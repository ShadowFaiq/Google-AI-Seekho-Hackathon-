from fastapi import FastAPI, WebSocket, HTTPException
from pydantic import BaseModel
import asyncio
import traceback

from database.mock_firestore import db
from agents.intent_agent import parse_intent
from agents.discovery_agent import discover_providers
from agents.ranking_agent import rank_providers
from agents.pricing_agent import calculate_price
from agents.booking_agent import book_service
from agents.dispute_agent import handle_dispute

app = FastAPI(title="KaamConnect API")

class ServiceRequest(BaseModel):
    user_id: str
    text: str

class DisputeRequest(BaseModel):
    booking_id: str
    actual_charge: float
    complaint_text: str

@app.post("/api/request")
async def submit_request(req: ServiceRequest):
    """
    Endpoint to submit a request and run it through the orchestrator synchronously.
    (Used mostly if WebSocket is not preferred by the client)
    """
    try:
        req_id = db.save_request(req.user_id, req.text, {})
        user = db.get_user(req.user_id)
        if not user:
             raise HTTPException(status_code=404, detail="User not found")
        
        # We will use the 'home' address for this demo
        user_loc = user["saved_addresses"]["home"]
        
        # 1. Intent Parse
        intent = parse_intent(req.text)
        db.service_requests[req_id]["parsed_data"] = intent
        
        if intent.get("confidence", 0) < 0.6:
            return {"status": "clarification_needed", "message": "Can you please clarify your request?", "req_id": req_id}
            
        # 2. Discover
        providers = discover_providers(intent.get("service_category", "ac_repair"))
        if not providers:
            return {"status": "failed", "message": "No providers found for this category.", "req_id": req_id}
            
        # 3. Rank
        is_emergency = intent.get("is_emergency", False)
        ranked = rank_providers(providers, user_loc, is_emergency=is_emergency)
        if not ranked:
            return {"status": "failed", "message": "No providers match criteria.", "req_id": req_id}
            
        best_provider = ranked[0]["provider"]
        
        # 4. Pricing
        price_breakdown = calculate_price(
            provider_rate=best_provider["base_hourly_rate"],
            distance_km=ranked[0]["distance_km"],
            urgency=intent.get("urgency", "medium"),
            is_emergency=is_emergency
        )
        
        # 5. Book
        booking_id, slot, notification = book_service(
            req_id, req.user_id, best_provider, price_breakdown, intent.get("time_preference")
        )
        
        return {
            "status": "success",
            "booking_id": booking_id,
            "provider": best_provider["name"],
            "slot": slot,
            "price": price_breakdown,
            "is_emergency": is_emergency,
            "logs": db.agent_logs.get(req_id, [])
        }
    except Exception as e:
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))

@app.websocket("/ws/trace")
async def websocket_trace(websocket: WebSocket):
    """
    WebSocket endpoint for the Agent Trace Visualizer.
    Accepts the user request, runs the pipeline with asyncio.sleep to simulate processing time,
    and streams the reasoning steps back to the frontend.
    """
    await websocket.accept()
    try:
        data = await websocket.receive_json()
        user_id = data.get("user_id", "usr_789234")
        text = data.get("text", "")
        
        user = db.get_user(user_id)
        user_loc = user["saved_addresses"]["home"] if user else {"lat": 31.4697, "lng": 74.4012}
        
        req_id = db.save_request(user_id, text, {})
        
        # Step 1: Intent
        await websocket.send_json({"step": "intent", "status": "processing"})
        await asyncio.sleep(1) # Simulate think time
        intent = parse_intent(text)
        db.add_log(req_id, "IntentAgent", "Extracted Intent", "Parsed natural language into structured JSON.", intent)
        await websocket.send_json({"step": "intent", "status": "done", "result": intent})
        
        if intent.get("confidence", 0) < 0.6:
            await websocket.send_json({"step": "clarification", "status": "done", "message": "Low confidence. Please clarify."})
            return
            
        # Step 2: Discovery & Ranking
        await websocket.send_json({"step": "ranking", "status": "processing"})
        await asyncio.sleep(1)
        providers = discover_providers(intent.get("service_category", "ac_repair"))
        is_emergency = intent.get("is_emergency", False)
        ranked = rank_providers(providers, user_loc, is_emergency=is_emergency)
        
        db.add_log(req_id, "RankingAgent", "Ranked Providers", f"Evaluated {len(providers)} providers. Prioritized Trust Score.", {"top_provider": ranked[0]["provider"]["name"], "score": ranked[0]["score"]})
        
        await websocket.send_json({"step": "ranking", "status": "done", "top_result": ranked[0], "is_emergency": is_emergency})
        best_provider = ranked[0]["provider"]
        
        # Step 3: Pricing
        await websocket.send_json({"step": "pricing", "status": "processing"})
        await asyncio.sleep(1)
        price_breakdown = calculate_price(
            provider_rate=best_provider["base_hourly_rate"],
            distance_km=ranked[0]["distance_km"],
            urgency=intent.get("urgency", "medium"),
            is_emergency=is_emergency
        )
        db.add_log(req_id, "PricingAgent", "Calculated Quote", "Applied dynamic pricing formula with distance and urgency.", price_breakdown)
        await websocket.send_json({"step": "pricing", "status": "done", "breakdown": price_breakdown})
        
        # Step 4: Booking
        await websocket.send_json({"step": "booking", "status": "processing"})
        await asyncio.sleep(1)
        booking_id, slot, notification = book_service(
            req_id, user_id, best_provider, price_breakdown, intent.get("time_preference")
        )
        db.add_log(req_id, "BookingAgent", "Booking Confirmed", f"Simulated booking and notification to {best_provider['name']}.", {"booking_id": booking_id, "slot": slot})
        
        await websocket.send_json({
            "step": "final",
            "status": "success",
            "booking_id": booking_id,
            "provider": best_provider["name"],
            "slot": slot
        })
        
    except Exception as e:
        await websocket.send_json({"error": str(e)})
        traceback.print_exc()

@app.post("/api/dispute")
async def create_dispute(req: DisputeRequest):
    result = handle_dispute(req.booking_id, req.actual_charge, req.complaint_text)
    return result

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
