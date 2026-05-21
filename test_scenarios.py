import requests
import json
import asyncio
import websockets

BASE_URL = "http://localhost:8000"
WS_URL = "ws://localhost:8000/ws/trace"

def test_rest_api_normal():
    print("\n--- Test 1: Normal Booking via REST API ---")
    payload = {
        "user_id": "usr_789234",
        "text": "Mujhe kal subah AC technician chahiye G-13 mein"
    }
    response = requests.post(f"{BASE_URL}/api/request", json=payload)
    print(json.dumps(response.json(), indent=2))

def test_rest_api_emergency():
    print("\n--- Test 2: Emergency Booking (SOS Mode) ---")
    payload = {
        "user_id": "usr_789234",
        "text": "Bhai AC mein short circuit ho gaya hai, aag lagne ka dar hai, jaldi bhejain!"
    }
    response = requests.post(f"{BASE_URL}/api/request", json=payload)
    print(json.dumps(response.json(), indent=2))

def test_dispute_resolution(booking_id):
    print("\n--- Test 3: Auto Dispute Resolution ---")
    payload = {
        "booking_id": booking_id,
        "actual_charge": 2500.0,
        "complaint_text": "Technician charged me 2500 but the quote was only 1980!"
    }
    response = requests.post(f"{BASE_URL}/api/dispute", json=payload)
    print(json.dumps(response.json(), indent=2))

async def test_websocket_trace():
    print("\n--- Test 4: Live Agent Trace via WebSocket ---")
    async with websockets.connect(WS_URL) as websocket:
        payload = {
            "user_id": "usr_789234",
            "text": "AC bilkul cool nahi kar raha, kal koi bhej dain"
        }
        await websocket.send(json.dumps(payload))
        
        while True:
            try:
                response = await websocket.recv()
                data = json.loads(response)
                print(f"[{data.get('step', 'unknown').upper()}] Status: {data.get('status')}")
                if 'result' in data:
                    print(f"  Parsed: {data['result']}")
                if 'top_result' in data:
                    print(f"  Selected: {data['top_result']['provider']['name']} (Score: {data['top_result']['score']})")
                if 'breakdown' in data:
                    print(f"  Quote: {data['breakdown']['total_price']} PKR")
                if 'booking_id' in data and data['step'] == 'final':
                    print(f"  Confirmed! Booking ID: {data['booking_id']}")
                    break
            except Exception as e:
                print(f"WebSocket closed: {e}")
                break

if __name__ == "__main__":
    print("Testing KaamConnect Backend...")
    # These synchronous tests require the server to be running.
    try:
        test_rest_api_normal()
        test_rest_api_emergency()
        
        # Test dispute with a dummy booking ID (might fail if not created, but demonstrates the logic)
        # Ideally, grab the booking_id from the first test
        response = requests.post(f"{BASE_URL}/api/request", json={
            "user_id": "usr_789234",
            "text": "AC servicing needed"
        })
        if response.status_code == 200 and "booking_id" in response.json():
            test_dispute_resolution(response.json()["booking_id"])
            
    except requests.exceptions.ConnectionError:
        print("Server is not running. Start it with: uvicorn main:app --reload")

    # Uncomment to test WebSocket (requires `pip install websockets`)
    # asyncio.run(test_websocket_trace())
