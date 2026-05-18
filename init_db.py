import firebase_admin
from firebase_admin import credentials, firestore
import os

# Connect to Firebase
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
KEY_PATH = os.path.join(BASE_DIR, 'serviceAccountKey.json')

cred = credentials.Certificate(KEY_PATH)
firebase_admin.initialize_app(cred)
db = firestore.client()

def seed_database():
    print("Seeding database with Mishal's schema...")

    # Clear old data (optional, but good for fresh hackathon starts)
    for col in ['providers', 'users', 'bookings', 'service_requests', 'agent_logs']:
        docs = db.collection(col).stream()
        for doc in docs:
            doc.reference.delete()

    # 1. Users
    users = [
        {"id": "usr_789234", "name": "Faiq Hassan", "email": "faiq@kaamconnect.pk", "phone": "03001234567", "location": {"lat": 31.4697, "lng": 74.4012}, "saved_addresses": {"home": {"lat": 31.4697, "lng": 74.4012}}},
        {"id": "usr_111111", "name": "Anum Malik", "email": "anum@kaamconnect.pk", "phone": "03009876543", "location": {"lat": 31.4800, "lng": 74.4100}, "saved_addresses": {"home": {"lat": 31.4800, "lng": 74.4100}}},
    ]
    for i in range(8):
        users.append({"id": f"usr_dummy_{i}", "name": f"Dummy User {i}", "email": f"dummy{i}@test.com", "phone": "03000000000", "location": {"lat": 31.4700, "lng": 74.4000}, "saved_addresses": {"home": {"lat": 31.4700, "lng": 74.4000}}})

    for u in users:
        db.collection('users').document(u["id"]).set(u)
    print("Seeded 10 Users.")

    # 2. Providers (8-factor ready)
    providers = [
        {
            "id": "prv_ac_1",
            "name": "Ali AC Master",
            "service_category": "ac_repair",
            "specialty": "split ac", # Skill specialization
            "is_active": True,
            "location": {"lat": 31.4750, "lng": 74.4050}, # 1km away
            "rating": 4.9,
            "cancellation_rate": 5, # 5%
            "on_time_score": 98, # 98%
            "base_hourly_rate": 1200,
            "last_review_days_ago": 2, # Very recent
            "metrics": {} # Legacy compatibility if needed
        },
        {
            "id": "prv_ac_2",
            "name": "Imran HVAC",
            "service_category": "ac_repair",
            "specialty": "window ac",
            "is_active": True,
            "location": {"lat": 31.4700, "lng": 74.4020}, # 0.2km away
            "rating": 4.2,
            "cancellation_rate": 40, # High risk
            "on_time_score": 70,
            "base_hourly_rate": 800,
            "last_review_days_ago": 45, # Stale
            "metrics": {}
        },
        {
            "id": "prv_ac_3",
            "name": "Zahid Cooling Experts",
            "service_category": "ac_repair",
            "specialty": "central ac",
            "is_active": True,
            "location": {"lat": 31.5000, "lng": 74.4500}, # Far
            "rating": 5.0,
            "cancellation_rate": 0,
            "on_time_score": 100,
            "base_hourly_rate": 2000,
            "last_review_days_ago": 5,
            "metrics": {}
        }
    ]
    
    # Fill out the rest to make 10
    for i in range(7):
        providers.append({
            "id": f"prv_plumb_{i}",
            "name": f"Plumber {i}",
            "service_category": "plumbing",
            "specialty": "general",
            "is_active": True,
            "location": {"lat": 31.4800, "lng": 74.4100},
            "rating": 4.5,
            "cancellation_rate": 10,
            "on_time_score": 90,
            "base_hourly_rate": 1000,
            "last_review_days_ago": 10,
            "metrics": {}
        })

    for p in providers:
        db.collection('providers').document(p["id"]).set(p)
    print("Seeded 10 Providers.")

    # 3. Bookings (Sample)
    db.collection('bookings').document("SAMPLE_BK").set({
        "user_id": "usr_789234",
        "provider_id": "prv_ac_1",
        "status": "Completed",
        "service_type": "ac_repair",
        "timestamp": "2026-05-18T10:00:00Z"
    })
    print("Seeded sample bookings.")
    
    print("Init DB complete!")

if __name__ == "__main__":
    seed_database()
