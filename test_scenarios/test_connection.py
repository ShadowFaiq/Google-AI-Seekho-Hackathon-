import sys
import os
import requests
import json
import asyncio
import websockets

# Base URL config
BASE_URL = "http://127.0.0.1:8000"
WS_URL = "ws://127.0.0.1:8000/ws/trace"

async def test_api_connectivity():
    print("\n===========================================")
    print("RUNNING BACKEND INTEGRATION & CONNECTION TESTS")
    print("===========================================\n")
    
    # 1. Test Base Server Check
    print("-> Checking Server Status (GET /)...")
    try:
        response = requests.get(BASE_URL)
        print(f"   [OK] Server is responding. Status: {response.status_code}\n")
    except requests.exceptions.ConnectionError:
        print("   [CRITICAL] Server is not running on http://localhost:8000!")
        print("      Please start it with: uvicorn main:app --reload")
        return False

    # 2. Test REST Request Endpoint
    print("-> Testing REST API Service Request (POST /api/request)...")
    payload = {
        "user_id": "usr_789234",
        "text": "AC servicing needed urgently in G-13"
    }
    try:
        payload["text"] = "AC servicing needed urgently in DHA Lahore"
        response = requests.post(f"{BASE_URL}/api/request", json=payload)
        if response.status_code != 200:
            print(f"   [DEBUG] Server Error Details: {response.text}")
        assert response.status_code == 200, f"HTTP Error: {response.status_code}"
        data = response.json()
        assert data.get("status") == "success", "Response status is not success!"
        req_id = data.get("req_id")
        print(f"   [OK] REST API Success! Created Request ID: {req_id}\n")
    except Exception as e:
        print(f"   [FAIL] REST Request Failed: {e}\n")
        return False

    # 3. Test REST Dispute Endpoint
    print("-> Testing REST API Dispute Resolution (POST /api/dispute)...")
    dispute_payload = {
        "booking_id": "KC-BK-MOCK1",
        "actual_charge": 2500.0,
        "complaint_text": "I was overcharged by the plumber. Plumber asked for 2500 but quote was 1500."
    }
    try:
        response = requests.post(f"{BASE_URL}/api/dispute", json=dispute_payload)
        assert response.status_code == 200, f"HTTP Error: {response.status_code}"
        data = response.json()
        assert data.get("status") == "success", "Response status not success!"
        res = data.get("resolution", {})
        print(f"   [OK] Dispute API Success! Status: '{res.get('resolution_status')}'. Suggested Refund: {res.get('suggested_refund')} PKR\n")
    except Exception as e:
        print(f"   [FAIL] Dispute Request Failed: {e}\n")
        return False

    # 4. Test WebSocket Trace Endpoint
    print("-> Testing WebSocket Live Trace (WS /ws/trace)...")
    try:
        async with websockets.connect(WS_URL) as websocket:
            ws_payload = {
                "user_id": "usr_789234",
                "text": "AC is hot, please send technician today"
            }
            await websocket.send(json.dumps(ws_payload))
            print("   [OK] Sent test query over WebSocket.")
            
            # Receive some trace outputs to verify it's working
            received_trace = False
            for _ in range(5):
                try:
                    # Set a timeout so we don't block indefinitely
                    response = await asyncio.wait_for(websocket.recv(), timeout=5.0)
                    data = json.loads(response)
                    print(f"      [WS Stream] Agent: {data.get('agent', 'unknown')} | Status: {data.get('status')}")
                    if "agent" in data:
                        received_trace = True
                except asyncio.TimeoutError:
                    print("      [WARN] Timeout waiting for WebSocket message.")
                    break
                    
            if received_trace:
                print("   [OK] WebSocket Success! Connection and stream work perfectly.\n")
            else:
                print("   [FAIL] WebSocket did not stream trace data!\n")
                return False
    except Exception as e:
        print(f"   [FAIL] WebSocket Connection Failed: {e}\n")
        return False

    print("ALL ENDPOINTS AND COMMUNICATIONS FULLY INTEGRATED & EMBEDDED!")
    return True

if __name__ == "__main__":
    asyncio.run(test_api_connectivity())
