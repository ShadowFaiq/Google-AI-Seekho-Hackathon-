from dotenv import load_dotenv
load_dotenv()

from fastapi import FastAPI, WebSocket, WebSocketDisconnect, HTTPException, Header, Depends
from pydantic import BaseModel
import asyncio
import traceback
import time
from datetime import datetime

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

app = FastAPI(title="FikrFree Antigravity API") # Force StatReload to pick up latest updates

class ServiceRequest(BaseModel):
    user_id: str
    text: str

class DisputeRequest(BaseModel):
    booking_id: str
    actual_charge: float
    complaint_text: str

# Mock Auth
def verify_provider_token(authorization: str = Header(None)):
    if not authorization or "Bearer mock_token" not in authorization:
        raise HTTPException(status_code=401, detail="Unauthorized Provider")
    return True

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
            ranked = ctx.get("ranked_providers")
            top = ranked[0].get("provider", {}).get("name", "None") if ranked else "None"
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
            try:
                await self.websocket.send_json(schema)
                # Simulated visual delay for judges to read the trace
                await asyncio.sleep(1)
            except Exception:
                self.websocket = None

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

@app.post("/api/request")
async def submit_request(req: ServiceRequest):
    try:
        req_id = db.save_request(req.user_id, req.text, {})
        orchestrator = Orchestrator(TraceEmitter(None, req_id=req_id))
        ctx = await orchestrator.run(req.text, req_id, req.user_id)
        return {"status": "success", "req_id": req_id, "ctx": ctx}
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

@app.post("/api/dispute")
async def submit_dispute(req: DisputeRequest):
    try:
        booking = None
        if db.db:
            doc = db.db.collection('bookings').document(req.booking_id).get()
            if doc.exists:
                booking = doc.to_dict()
                
        if not booking:
            booking = {
                "user_id": "usr_789234",
                "selected_provider": "prv_ac_1",
                "price_breakdown": {"total_price": 1980}
            }
            
        provider_id = booking.get("selected_provider", "prv_ac_1")
        provider = None
        if db.db:
            p_doc = db.db.collection('providers').document(provider_id).get()
            if p_doc.exists:
                provider = p_doc.to_dict()
        if not provider:
            provider = {
                "id": provider_id,
                "name": "Ali AC Master",
                "service_category": "ac_repair",
                "phone": "03000000000"
            }
            
        ctx = {
            "user_input": req.complaint_text,
            "req_id": booking.get("request_id", "mock_req"),
            "user_id": booking.get("user_id", "usr_789234"),
            "price_breakdown": booking.get("price_breakdown", {"total_price": 1980}),
            "ranked_providers": [
                {
                    "provider": provider
                }
            ]
        }
        
        agent = DisputeAgent(ctx)
        ctx = await agent.run()
        
        return {
            "status": "success",
            "booking_id": req.booking_id,
            "resolution": ctx.get("dispute_resolution")
        }
    except Exception as e:
        traceback.print_exc()
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
        
        try:
            if ctx.get("halt"):
                await websocket.send_json({"message": ctx.get("error_msg") or "Pipeline halted for clarification."})
            else:
                await websocket.send_json({"message": "Pipeline completed successfully."})
        except Exception:
            pass
            
    except WebSocketDisconnect:
        print("WebSocket client disconnected.")
    except Exception as e:
        try:
            await websocket.send_json({"error": str(e)})
        except Exception:
            pass
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
