import requests
import json
import time

BASE_URL = "http://localhost:8000"

def run_tests():
    print("=== Step 1: Sending Initial Request ===")
    payload = {
        "user_id": "usr_789234",
        "text": "Mujhe kal subah AC technician chahiye G-13 mein"
    }
    
    try:
        res1 = requests.post(f"{BASE_URL}/api/request", json=payload)
        res1.raise_for_status()
    except Exception as e:
        print(f"Failed to connect to server: {e}")
        return
        
    data1 = res1.json()
    print("Response:")
    print(json.dumps(data1, indent=2))
    
    req_id = data1.get("req_id")
    session_token = data1.get("session_token")
    ctx = data1.get("ctx", {})
    
    if ctx.get("bidding_status") != "WAITING_FOR_USER_BID":
        print("ERROR: Pipeline did not halt for bidding!")
        return
        
    price_breakdown = ctx.get("price_breakdown", {})
    suggested_price = price_breakdown.get("suggested_price", 1000)
    floor_price = price_breakdown.get("floor_price", 800)
    
    print(f"\nCalculated Bounds - Suggested: {suggested_price}, Floor: {floor_price}")
    
    print("\n=== Step 2: Placing a Bid Offer ===")
    my_offer = floor_price + 50
    offer_payload = {
        "req_id": req_id,
        "user_id": "usr_789234",
        "offered_price": my_offer,
        "session_token": session_token
    }
    
    res2 = requests.post(f"{BASE_URL}/api/bids/offer", json=offer_payload)
    data2 = res2.json()
    print("Response:")
    print(json.dumps(data2, indent=2))
    
    bids = data2.get("bids", [])
    if not bids:
        print("ERROR: No counter bids received!")
        return
        
    chosen_bid = bids[1] # Choose the second one ("Babu Repairs")
    
    print(f"\n=== Step 3: Accepting Bid from {chosen_bid['name']} for {chosen_bid['bid_price']} ===")
    accept_payload = {
        "req_id": req_id,
        "user_id": "usr_789234",
        "provider_id": chosen_bid["provider_id"],
        "accepted_price": chosen_bid["bid_price"],
        "session_token": session_token
    }
    
    res3 = requests.post(f"{BASE_URL}/api/bids/accept", json=accept_payload)
    data3 = res3.json()
    print("Response:")
    print(json.dumps(data3, indent=2))
    
    final_ctx = data3.get("ctx", {})
    booking_id = final_ctx.get("booking_id")
    
    if booking_id:
        print(f"\n[SUCCESS] Booking locked. ID: {booking_id}")
    else:
        print("\n[ERROR] Booking failed.")

if __name__ == "__main__":
    run_tests()
