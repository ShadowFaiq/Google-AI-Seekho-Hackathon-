import requests
import json

BASE_URL = "http://localhost:8000"

def test_auth():
    print("=== Testing Customer Register ===")
    reg_payload = {
        "name": "Faiq Hassan",
        "email": f"faiq_{int(json.dumps(reg_payload)) if False else 'test1'}@kaamconnect.pk",  # dynamic-ish email
        "phone": "03001234567",
        "password": "password123"
    }
    # Let's just use static but different email
    import random
    email = f"user_{random.randint(1000, 9999)}@test.com"
    reg_payload["email"] = email
    
    try:
        res = requests.post(f"{BASE_URL}/api/auth/register", json=reg_payload)
        print("Register Status:", res.status_code)
        print(json.dumps(res.json(), indent=2))
        
        token = res.json().get("token")
        
        print("\n=== Testing Customer Login ===")
        login_payload = {
            "email": email,
            "password": "password123"
        }
        res2 = requests.post(f"{BASE_URL}/api/auth/login", json=login_payload)
        print("Login Status:", res2.status_code)
        print(json.dumps(res2.json(), indent=2))
        
        print("\n=== Testing JWT Secured Provider Dashboard ===")
        # Testing a provider login with mock data first
        prov_login_payload = {
            "email": "ali@kaamconnect.pk",
            "password": "password123"
        }
        res3 = requests.post(f"{BASE_URL}/api/provider/login", json=prov_login_payload)
        print("Provider Login Status:", res3.status_code)
        prov_token = res3.json().get("token")
        
        headers = {"Authorization": f"Bearer {prov_token}"}
        res4 = requests.get(f"{BASE_URL}/provider/prov_1/dashboard", headers=headers)
        print("Provider Dashboard Access Status:", res4.status_code)
        print(json.dumps(res4.json(), indent=2))
        
    except Exception as e:
        print("Test failed:", e)

if __name__ == "__main__":
    test_auth()
