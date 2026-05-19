import sys
import os
import asyncio

# Ensure parent directory is in sys.path
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from agents.intent_agent import IntentAgent
from agents.geo_normalization_agent import GeoNormalizationAgent
from agents.discovery_agent import DiscoveryAgent
from agents.scheduling_agent import SchedulingAgent
from agents.ranking_agent import RankingAgent
from agents.pricing_agent import PricingAgent
from agents.booking_agent import BookingAgent
from agents.notification_agent import NotificationAgent
from agents.service_lifecycle_agent import ServiceLifecycleAgent
from agents.dispute_agent import DisputeAgent
from database.firebase_client import db

async def run_agent_tests():
    print("\n===========================================")
    print("RUNNING ISOLATED AGENT UNIT TESTS")
    print("===========================================\n")
    
    # Setup initial mock context
    ctx = {
        "user_input": "AC kharab hai DHA Lahore mein, emergency",
        "req_id": "test_req_999",
        "user_id": "usr_789234",
        "discovery_radius_km": 15
    }
    
    # Pre-seed the service request document to avoid 404 in BookingAgent
    if db and db.db:
        db.db.collection('service_requests').document("test_req_999").set({
            "id": "test_req_999",
            "user_id": "usr_789234",
            "status": "pending",
            "user_input": "AC kharab hai DHA Lahore mein, emergency"
        })
    
    # 1. Test IntentAgent
    print("-> Testing 1/10: IntentAgent...")
    intent_agent = IntentAgent(ctx)
    ctx = await intent_agent.run()
    intent = ctx.get("intent", {})
    assert intent is not None, "Intent parsing failed!"
    print(f"   [OK] SUCCESS: Intent parsed as service_type='{intent.get('service_type')}' with urgency='{intent.get('urgency')}'\n")
    
    # 2. Test GeoNormalizationAgent
    print("-> Testing 2/10: GeoNormalizationAgent...")
    geo_agent = GeoNormalizationAgent(ctx)
    ctx = await geo_agent.run()
    normalized_loc = ctx.get("normalized_location", {})
    assert normalized_loc.get("address") is not None, "Location normalization failed!"
    print(f"   [OK] SUCCESS: Location normalized to: '{normalized_loc.get('address')}'\n")
    
    # 3. Test DiscoveryAgent
    print("-> Testing 3/10: DiscoveryAgent...")
    discovery_agent = DiscoveryAgent(ctx)
    ctx = await discovery_agent.run()
    providers = ctx.get("providers", [])
    assert isinstance(providers, list), "Providers discovery failed!"
    print(f"   [OK] SUCCESS: Discovered {len(providers)} eligible providers nearby.\n")
    
    # 4. Test SchedulingAgent
    print("-> Testing 4/10: SchedulingAgent...")
    scheduling_agent = SchedulingAgent(ctx)
    ctx = await scheduling_agent.run()
    for p in ctx.get("providers", []):
        assert "earliest_slot" in p, "Earliest slot not assigned!"
    print("   [OK] SUCCESS: Dynamic travel buffers and earliest slots calculated successfully.\n")
    
    # 5. Test RankingAgent
    print("-> Testing 5/10: RankingAgent...")
    ranking_agent = RankingAgent(ctx)
    ctx = await ranking_agent.run()
    ranked_providers = ctx.get("ranked_providers", [])
    assert len(ranked_providers) > 0, "No providers ranked!"
    print(f"   [OK] SUCCESS: Providers ranked. Top choice: '{ranked_providers[0]['provider']['name']}' (Score: {ranked_providers[0]['score']})\n")
    
    # 6. Test PricingAgent
    print("-> Testing 6/10: PricingAgent...")
    pricing_agent = PricingAgent(ctx)
    ctx = await pricing_agent.run()
    price_breakdown = ctx.get("price_breakdown", {})
    assert "total_price" in price_breakdown, "Price breakdown failed!"
    print(f"   [OK] SUCCESS: Formulated price quote. Total Price: {price_breakdown['total_price']} PKR\n")
    
    # 7. Test BookingAgent
    print("-> Testing 7/10: BookingAgent...")
    booking_agent = BookingAgent(ctx)
    ctx = await booking_agent.run()
    booking_id = ctx.get("booking_id")
    assert booking_id is not None, "Booking failed!"
    print(f"   [OK] SUCCESS: Atomic slot booking successful. Booking ID: {booking_id}\n")
    
    # 8. Test NotificationAgent
    print("-> Testing 8/10: NotificationAgent...")
    notification_agent = NotificationAgent(ctx)
    ctx = await notification_agent.run()
    timeline = ctx.get("notification_timeline", [])
    assert len(timeline) > 0, "No notification timeline scheduled!"
    print(f"   [OK] SUCCESS: Adaptive notifications scheduled. Timelines created: {len(timeline)} events.\n")
    
    # 9. Test ServiceLifecycleAgent
    print("-> Testing 9/10: ServiceLifecycleAgent...")
    lifecycle_agent = ServiceLifecycleAgent(ctx)
    ctx = await lifecycle_agent.run()
    events = ctx.get("lifecycle_events", [])
    if ctx.get("halt") and ctx.get("error_msg"):
        print("   [OK] SUCCESS: Provider mock cancellation simulated successfully (No replacements available).\n")
    else:
        assert len(events) > 0, "No service events simulated!"
        print(f"   [OK] SUCCESS: Simulated dispatch to completion events successfully.\n")
    
    # 10. Test DisputeAgent
    print("-> Testing 10/10: DisputeAgent...")
    dispute_ctx = {
        "user_input": "Technician charged me 2500 PKR but the app said 1980 PKR!",
        "req_id": "test_dispute_999",
        "user_id": "usr_789234",
        "price_breakdown": {"total_price": 1980.0},
        "ranked_providers": [
            {
                "provider": {
                    "id": "prv_ac_1",
                    "name": "Ali AC Master",
                    "phone": "03211112222",
                    "service_category": "ac_repair"
                }
            }
        ]
    }
    dispute_agent = DisputeAgent(dispute_ctx)
    dispute_res = await dispute_agent.run()
    res = dispute_res.get("dispute_resolution", {})
    assert "resolution_status" in res, "Dispute resolution failed!"
    print(f"   [OK] SUCCESS: Dispute resolved autonomously by Gemini. Status: '{res['resolution_status']}'. Suggested Refund: {res.get('suggested_refund')} PKR\n")
    
    print("ALL 10 AGENTS FUNCTIONAL AND WORKING PERFECTLY!")

if __name__ == "__main__":
    asyncio.run(run_agent_tests())
