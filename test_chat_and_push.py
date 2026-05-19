import requests
import json

BASE_URL = "http://localhost:8000"

def test_chat_and_push():
    print("=== Testing Device Token Registration ===")
    
    # 1. Register User FCM Device Token
    user_token_payload = {
        "user_id": "usr_789234",
        "device_token": "FCM_USER_DEVICE_TOKEN_xyz123"
    }
    res_user_token = requests.post(f"{BASE_URL}/api/notification/register-device-token", json=user_token_payload)
    print("User Token Reg Status:", res_user_token.status_code)
    print(res_user_token.json())
    
    # 2. Register Provider FCM Device Token
    provider_token_payload = {
        "user_id": "prov_2",
        "device_token": "FCM_PROVIDER_DEVICE_TOKEN_abc789"
    }
    res_provider_token = requests.post(f"{BASE_URL}/api/notification/register-device-token", json=provider_token_payload)
    print("Provider Token Reg Status:", res_provider_token.status_code)
    print(res_provider_token.json())

    # 3. Simulate Accept Bid (which triggers FCM push notification messages on backend)
    print("\n=== Simulating Accepting Bid and Triggering Push Notifications ===")
    # First get a valid request session token by submitting a normal request
    req_payload = {
        "user_id": "usr_789234",
        "text": "AC installation"
    }
    res_req = requests.post(f"{BASE_URL}/api/request", json=req_payload)
    req_data = res_req.json()
    req_id = req_data.get("req_id")
    session_token = req_data.get("session_token")
    
    # Now accept the bid
    accept_payload = {
        "req_id": req_id,
        "user_id": "usr_789234",
        "provider_id": "prov_2",
        "accepted_price": 5000.0,
        "session_token": session_token
    }
    res_accept = requests.post(f"{BASE_URL}/api/bids/accept", json=accept_payload)
    print("Accept Bid Status:", res_accept.status_code)
    accept_data = res_accept.json()
    print(json.dumps(accept_data, indent=2))
    
    booking_id = accept_data.get("ctx", {}).get("booking_id")
    
    # 4. Test Chat History Retrieval
    print(f"\n=== Testing Chat History for Booking: {booking_id} ===")
    res_history_empty = requests.get(f"{BASE_URL}/api/chat/{booking_id}/history")
    print("Initial history status:", res_history_empty.status_code)
    print("Initial messages:", res_history_empty.json())

    # Note: In-app real-time messaging is powered by FastAPI WebSockets under:
    # ws://localhost:8000/ws/chat/{booking_id}/{user_id}
    print(f"\n[INFO] Real-time WebSocket Chat URL ready: ws://localhost:8000/ws/chat/{booking_id}/usr_789234")

if __name__ == "__main__":
    test_chat_and_push()
