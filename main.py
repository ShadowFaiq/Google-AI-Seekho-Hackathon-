from fastapi import FastAPI, WebSocket, HTTPException, Header, Depends
from pydantic import BaseModel
import asyncio
import traceback
import time
from datetime import datetime
import uuid

from database.firebase_client import db
from baseline_engine import BaselineEngine
from agents.intent_agent import IntentAgent
from agents.geo_normalization_agent import GeoNormalizationAgent
from agents.discovery_agent import DiscoveryAgent
from agents.ranking_agent import RankingAgent
from agents.scheduling_agent import SchedulingAgent
from agents.pricing_agent import PricingAgent
from agents.booking_agent import BookingAgent
from agents.notification_agent import NotificationAgent
from agents.service_lifecycle_agent import ServiceLifecycleAgent
from agents.dispute_agent import DisputeAgent

from auth import verify_token, get_password_hash, verify_password, create_access_token, create_session_token, verify_session_token

app = FastAPI(title="FikrFree Antigravity API")

class ServiceRequest(BaseModel):
    user_id: str
    text: str

class DisputeRequest(BaseModel):
    booking_id: str
    actual_charge: float
    complaint_text: str

class BidOfferRequest(BaseModel):
    req_id: str
    user_id: str
    offered_price: float
    session_token: str

class BidAcceptRequest(BaseModel):
    req_id: str
    user_id: str
    provider_id: str
    accepted_price: float
    session_token: str

class RegisterRequest(BaseModel):
    name: str
    email: str
    phone: str
    password: str

class LoginRequest(BaseModel):
    email: str
    password: str

class ProviderRegisterRequest(BaseModel):
    name: str
    email: str
    password: str
    service_category: str
    base_hourly_rate: float

# Real Auth with Mock fallback for Hackathon backward compatibility
def verify_provider_token(token_data: dict = Depends(verify_token)):
    if token_data.get("role") != "provider":
        raise HTTPException(status_code=403, detail="Access denied. Providers only.")
    return token_data

class TraceEmitter:
    def __init__(self, websocket: WebSocket = None, req_id: str = None):
        self.websocket = websocket
        self.req_id = req_id

    async def emit(self, agent_name: str, ctx: dict, start_time: float):
        duration_ms = int((time.time() - start_time) * 1000)
        
        # Build strict schema for the Trace Visualizer
        schema = {
            "agent": agent_name,
            "timestamp": datetime.utcnow().isoformat() + "Z",
            "status": "error" if ctx.get("recovery_triggered") else ("halted" if ctx.get("halt") else "completed"),
            "recovery": ctx.get("recovery_action") if ctx.get("recovery_triggered") else None,
            "inputs": {"user_input": ctx.get("user_input")},
            "outputs": {k: v for k, v in ctx.items() if k not in ["user_input", "providers", "ranked_providers", "baseline_ranked", "notification_timeline"]}, # Truncated large objects
            "decision": f"{agent_name} executed.",
            "duration_ms": duration_ms
        }
        
        # Populate specific human-readable decisions
        if agent_name == "IntentAgent":
            conf = ctx.get('intent', {}).get('confidence_breakdown', {})
            schema["decision"] = f"Parsed intent. Avg Confidence: {sum(conf.values())/4 if conf else 0}"
        elif agent_name == "GeoNormalizationAgent":
            schema["decision"] = f"Normalized location to: {ctx.get('normalized_location', {}).get('address')}"
        elif agent_name == "DiscoveryAgent":
            schema["decision"] = f"Found {len(ctx.get('providers', []))} eligible providers (filtered strikes)."
        elif agent_name == "SchedulingAgent":
            schema["decision"] = "Calculated dynamic travel buffers using Maps ETA."
        elif agent_name == "RankingAgent":
            rp = ctx.get("ranked_providers", [])
            top = rp[0].get("provider", {}).get("name", "None") if rp else "None"
            schema["decision"] = f"Ranked using 10-factor matrix. Emergency Override: {ctx.get('is_emergency')}. Top: {top}"
            schema["outputs"]["top_provider"] = top
        elif agent_name == "PricingAgent":
            schema["decision"] = "Calculated quote including budget and complexity factors."
        elif agent_name == "BookingAgent":
            if ctx.get("recovery_triggered"):
                schema["decision"] = "Double-booking race condition hit. Triggered recovery."
            else:
                schema["decision"] = "Locked slot with Firestore atomic transaction."
        elif agent_name == "NotificationAgent":
            schema["decision"] = "Scheduled T-24h to post-service notification timeline."
        elif agent_name == "ServiceLifecycleAgent":
            schema["decision"] = f"Simulated lifecycle. User rating: {ctx.get('user_rating')}"
        elif agent_name == "DisputeAgent":
            schema["decision"] = "Resolved dispute. Issued strike to Firebase."
            
        # Log to DB for HTTP polling fallback
        if self.req_id:
            db.add_log(self.req_id, agent_name, schema["status"], schema["decision"], schema)
            
        if self.websocket:
            await self.websocket.send_json(schema)
            # Simulated visual delay for judges to read the trace
            await asyncio.sleep(1)

class Orchestrator:
    pipeline = [
        IntentAgent, GeoNormalizationAgent, DiscoveryAgent, SchedulingAgent, 
        RankingAgent, PricingAgent, BookingAgent, NotificationAgent, 
        ServiceLifecycleAgent
    ]
    
    def __init__(self, trace_emitter: TraceEmitter):
        self.ws_trace = trace_emitter

    async def run(self, user_input: str, req_id: str, user_id: str):
        ctx = {
            "user_input": user_input,
            "req_id": req_id,
            "user_id": user_id
        }
        
        # Standard DAG Pipeline
        for AgentClass in self.pipeline:
            start_time = time.time()
            agent = AgentClass(ctx)
            ctx = await agent.run()
            await self.ws_trace.emit(agent.name, ctx, start_time)
            
            # Handle Failure Recovery Paths
            if ctx.get("recovery_triggered"):
                # Discovery Failed -> Expand Radius 5km to 10km
                if agent.name == "DiscoveryAgent" and ctx.get("recovery_action") == "expand_radius":
                    ctx["discovery_radius_km"] = 10
                    ctx["recovery_triggered"] = False
                    ctx["halt"] = False
                    ctx = await DiscoveryAgent(ctx).run()
                    await self.ws_trace.emit("DiscoveryAgent_Radius_Expanded", ctx, time.time())
                    if not ctx.get("providers"):
                        # Still nothing? Fallback to tomorrow
                        ctx["error_msg"] = "No providers available in 10km radius today. Would you like to schedule for tomorrow?"
                        ctx["halt"] = True
                        
                # Booking Failed -> Try next provider
                elif agent.name == "BookingAgent" and ctx.get("recovery_action") == "offer alternatives":
                    if ctx.get("ranked_providers"):
                        ctx["ranked_providers"].pop(0) # Remove unavailable
                        ctx["recovery_triggered"] = False
                        ctx["halt"] = False
                        if ctx["ranked_providers"]:
                            start_time = time.time()
                            ctx = await BookingAgent(ctx).run()
                            await self.ws_trace.emit("BookingAgent_Retry", ctx, start_time)
            
            if ctx.get("halt"):
                return ctx # Clarification loop or error gate
                
        # Calculate Baseline Engine Comparison
        if ctx.get("providers"):
            baseline_engine = BaselineEngine(ctx["providers"], ctx.get("normalized_location"))
            ctx["baseline_ranked"] = baseline_engine.calculate_baseline()
                
        # Conditional Routing for Dispute Agent
        if ctx.get("user_rating", 5) <= 2:
            start_time = time.time()
            ctx["dispute_trigger"] = "low_rating"
            agent = DisputeAgent(ctx)
            ctx = await agent.run()
            await self.ws_trace.emit("DisputeAgent", ctx, start_time)
            
        return ctx

# --- Authentication Endpoints ---

@app.post("/api/auth/register")
async def register_user(req: RegisterRequest):
    existing_user = db.get_user_by_email(req.email)
    if existing_user:
        raise HTTPException(status_code=400, detail="Email already registered")
    
    user_id = f"usr_{uuid.uuid4().hex[:6]}"
    hashed_password = get_password_hash(req.password)
    
    user_data = {
        "id": user_id,
        "name": req.name,
        "email": req.email,
        "phone": req.phone,
        "hashed_password": hashed_password,
        "role": "customer"
    }
    
    db.create_user(user_data)
    token = create_access_token({"sub": user_id, "email": req.email, "role": "customer"})
    return {"status": "success", "token": token, "user": {"id": user_id, "name": req.name, "email": req.email}}

@app.post("/api/auth/login")
async def login_user(req: LoginRequest):
    user = db.get_user_by_email(req.email)
    if not user or not verify_password(req.password, user.get("hashed_password", "")):
        raise HTTPException(status_code=400, detail="Invalid email or password")
    
    token = create_access_token({"sub": user["id"], "email": user["email"], "role": user.get("role", "customer")})
    return {"status": "success", "token": token, "user": {"id": user["id"], "name": user["name"], "email": user["email"]}}

@app.post("/api/provider/register")
async def register_provider(req: ProviderRegisterRequest):
    existing_provider = db.get_provider_by_email(req.email)
    if existing_provider:
        raise HTTPException(status_code=400, detail="Email already registered")
    
    provider_id = f"prv_{uuid.uuid4().hex[:6]}"
    hashed_password = get_password_hash(req.password)
    
    provider_data = {
        "id": provider_id,
        "name": req.name,
        "email": req.email,
        "hashed_password": hashed_password,
        "service_category": req.service_category,
        "base_hourly_rate": req.base_hourly_rate,
        "role": "provider",
        "is_active": True,
        "rating": 5.0,
        "strikes": 0,
        "cancellation_rate": 0
    }
    
    db.create_provider(provider_data)
    token = create_access_token({"sub": provider_id, "email": req.email, "role": "provider"})
    return {"status": "success", "token": token, "provider": {"id": provider_id, "name": req.name, "email": req.email}}

@app.post("/api/provider/login")
async def login_provider(req: LoginRequest):
    provider = db.get_provider_by_email(req.email)
    if not provider or not verify_password(req.password, provider.get("hashed_password", "")):
        raise HTTPException(status_code=400, detail="Invalid email or password")
    
    token = create_access_token({"sub": provider["id"], "email": provider["email"], "role": "provider"})
    return {"status": "success", "token": token, "provider": {"id": provider["id"], "name": provider["name"], "email": provider["email"]}}

@app.post("/api/request")
async def submit_request(req: ServiceRequest):
    try:
        req_id = db.save_request(req.user_id, req.text, {})
        orchestrator = Orchestrator(TraceEmitter(None, req_id=req_id))
        ctx = await orchestrator.run(req.text, req_id, req.user_id)
        session_token = create_session_token(req_id, req.user_id)
        return {"status": "success", "req_id": req_id, "session_token": session_token, "ctx": ctx}
    except Exception as e:
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/bids/offer")
async def place_bid_offer(req: BidOfferRequest):
    try:
        verify_session_token(req.session_token, req.req_id, req.user_id)
        # User proposes an initial price to providers
        # Simulate providers responding with counter offers
        # In a real app, this would broadcast via websockets to active providers
        mock_provider_bids = [
            {"provider_id": "prov_1", "bid_price": req.offered_price + 150, "name": "Ali Tech"},
            {"provider_id": "prov_2", "bid_price": req.offered_price + 50, "name": "Babu Repairs"}
        ]
        return {"status": "success", "req_id": req.req_id, "message": "Offer broadcasted. Received counter-bids.", "bids": mock_provider_bids}
    except Exception as e:
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/bids/accept")
async def accept_bid(req: BidAcceptRequest):
    try:
        verify_session_token(req.session_token, req.req_id, req.user_id)
        # Recreate context and run only the remaining pipeline (Booking, Notification, Lifecycle)
        ctx = {
            "req_id": req.req_id,
            "user_id": req.user_id,
            "accepted_provider_id": req.provider_id,
            "accepted_price": req.accepted_price,
            "ranked_providers": [{"provider": {"id": req.provider_id, "name": "Selected Provider", "phone": "03001234567"}}]
        }
        
        ctx = await BookingAgent(ctx).run()
        if not ctx.get("halt"):
            ctx = await NotificationAgent(ctx).run()
            ctx = await ServiceLifecycleAgent(ctx).run()
            
        return {"status": "success", "message": "Bid accepted and booking locked.", "ctx": ctx}
    except Exception as e:
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/provider/cancel")
async def provider_cancellation_webhook(req: DisputeRequest):
    """Webhook triggered when a provider cancels a job after confirmation."""
    try:
        # Simulate autonomous reranking and reallocation
        req_id = req.booking_id # Simplified mock
        logs = db.agent_logs.get(req_id, [])
        return {
            "status": "success",
            "message": "ProviderCancelEvent triggered. Re-allocating booking to next best candidate.",
            "recovery_trace": {
                "agent": "BookingAgent",
                "status": "error",
                "recovery": "re-allocated",
                "decision": "Original provider cancelled. Autonomously re-allocated to secondary candidate."
            }
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/trace/{req_id}")
async def poll_trace(req_id: str):
    """Fallback HTTP endpoint if WebSockets fail on Hackathon WiFi"""
    logs = db.agent_logs.get(req_id, [])
    return {"req_id": req_id, "trace": logs}

@app.websocket("/ws/trace")
async def websocket_trace(websocket: WebSocket):
    await websocket.accept()
    try:
        data = await websocket.receive_json()
        user_id = data.get("user_id", "usr_789234")
        text = data.get("text", "")
        
        req_id = db.save_request(user_id, text, {})
        
        orchestrator = Orchestrator(TraceEmitter(websocket, req_id=req_id))
        ctx = await orchestrator.run(text, req_id, user_id)
        
        if ctx.get("halt"):
            await websocket.send_json({"message": ctx.get("error_msg") or "Pipeline halted for clarification."})
        else:
            await websocket.send_json({"message": "Pipeline completed successfully."})
            
    except Exception as e:
        await websocket.send_json({"error": str(e)})
        traceback.print_exc()

# ---------------------------------------------------------
# 4. The Provider Interface (Workload Balancing + Auth)
# ---------------------------------------------------------

@app.get("/provider/{id}/dashboard", dependencies=[Depends(verify_provider_token)])
async def get_provider_dashboard(id: str):
    provider = db.get_provider(id)
    if not provider:
        raise HTTPException(status_code=404, detail="Provider not found")
    
    return {
        "provider_id": id,
        "name": provider.get("name"),
        "today_jobs": 3,
        "earnings_today_pkr": 4500,
        "next_available_slot": "04:00 PM"
    }

@app.post("/provider/{id}/availability", dependencies=[Depends(verify_provider_token)])
async def set_provider_availability(id: str, available: bool = True):
    if db.db:
        db.db.collection('providers').document(id).update({"is_active": available})
    return {"status": "success", "message": f"Provider {id} availability set to {available}"}

@app.get("/provider/{id}/demand-forecast", dependencies=[Depends(verify_provider_token)])
async def get_demand_forecast(id: str):
    # Mocking Gemini prediction for busy hours
    return {
        "predicted_busy_hours": ["09:00 AM", "06:00 PM"],
        "recommended_slots": ["09:00 AM", "10:00 AM", "06:00 PM", "07:00 PM"],
        "reasoning": "Gemini predicts high demand for AC repair due to upcoming heatwave."
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
