import sys
import os

from database.firebase_client import FirebaseClient

def run_tests():
    print("=== Testing Firebase Client ===")
    try:
        client = FirebaseClient()
        
        print("\n1. Testing Providers Retrieval...")
        providers = client.get_providers_by_category("ac_repair")
        print(f"Successfully found {len(providers)} active AC Repair providers.")
        if len(providers) > 0:
            p = providers[0]
            print(f"   -> Sample: {p.get('name')} (Rating: {p.get('rating')}, Hourly: {p.get('base_hourly_rate')})")

        print("\n2. Testing User Retrieval...")
        user = client.get_user("usr_789234")
        if user:
            print(f"Successfully retrieved user: {user.get('name')} ({user.get('email')})")
        else:
            print("User not found.")

        print("\n3. Testing Service Request Creation...")
        dummy_req = {
            "user_id": "usr_789234",
            "user_request": "Test request",
            "parsed_data": {"test": True},
            "status": "pending"
        }
        req_id = client.save_request(dummy_req)
        print(f"Successfully created test service request with ID: {req_id}")

        print("\n=== All Database Tests Completed Successfully! ===")
    except Exception as e:
        print(f"Test Failed: {e}")

if __name__ == "__main__":
    run_tests()
