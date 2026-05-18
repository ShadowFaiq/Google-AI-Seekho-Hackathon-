import os
import uuid
import firebase_admin
from firebase_admin import credentials
from firebase_admin import firestore
from datetime import datetime
from typing import Dict, List, Any

# Get the absolute path to the key file in the same directory as this project
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
KEY_PATH = os.path.join(BASE_DIR, 'serviceAccountKey.json')

class FirebaseDB:
    def __init__(self):
        try:
            # Check if already initialized to prevent errors during hot-reloads
            if not firebase_admin._apps:
                cred = credentials.Certificate(KEY_PATH)
                firebase_admin.initialize_app(cred)
            self.db = firestore.client()
            print("Successfully connected to Firebase Firestore!")
        except Exception as e:
            print(f"Error initializing Firebase: {e}")
            self.db = None

    def get_user(self, user_id: str) -> Any:
        if not self.db: return None
        doc = self.db.collection('users').document(user_id).get()
        return doc.to_dict() if doc.exists else None

    def get_providers_by_category(self, category: str) -> List[Any]:
        if not self.db: return []
        docs = self.db.collection('providers').where('service_category', '==', category).where('is_active', '==', True).where('strikes', '<', 2).stream()
        return [doc.to_dict() for doc in docs]
    
    def get_provider(self, provider_id: str) -> Any:
        if not self.db: return None
        doc = self.db.collection('providers').document(provider_id).get()
        return doc.to_dict() if doc.exists else None

    def get_last_job(self, provider_id: str) -> Any:
        if not self.db: return None
        docs = self.db.collection('bookings').where('selected_provider', '==', provider_id).order_by('timestamp', direction=firestore.Query.DESCENDING).limit(1).stream()
        for doc in docs:
            return doc.to_dict()
        return None

    def increment_provider_strikes(self, provider_id: str):
        if self.db:
            self.db.collection('providers').document(provider_id).update({
                "strikes": firestore.Increment(1)
            })

    def save_request(self, user_id: str, request_text: str, structured_data: dict) -> str:
        req_id = f"req_{uuid.uuid4().hex[:6]}"
        data = {
            "request_id": req_id,
            "user_id": user_id,
            "user_request": request_text,
            "parsed_data": structured_data,
            "status": "pending",
            "timestamp": datetime.utcnow().isoformat()
        }
        if self.db:
            self.db.collection('service_requests').document(req_id).set(data)
        return req_id

    def add_log(self, req_id: str, agent: str, action: str, reasoning: str, data: Any = None):
        log_entry = {
            "log_id": f"log_{uuid.uuid4().hex[:6]}",
            "request_id": req_id,
            "agent": agent,
            "action": action,
            "reasoning": reasoning,
            "data": data,
            "timestamp": datetime.utcnow().isoformat()
        }
        if self.db:
            self.db.collection('agent_logs').document(log_entry["log_id"]).set(log_entry)
        return log_entry

    def create_booking(self, req_id: str, user_id: str, provider_id: str, price_breakdown: dict, slot: str) -> str:
        booking_id = f"KC-BK-{uuid.uuid4().hex[:5].upper()}"
        provider = self.get_provider(provider_id)
        
        booking_data = {
            "booking_id": booking_id,
            "request_id": req_id,
            "user_id": user_id,
            "selected_provider": provider_id,
            "provider_name": provider["name"] if provider else "Unknown",
            "service": provider["service_category"] if provider else "Unknown",
            "status": "Confirmed",
            "price_breakdown": price_breakdown,
            "scheduled_slot": slot,
            "reminder_status": "Scheduled",
            "timestamp": datetime.utcnow().isoformat()
        }
        
        if self.db:
            self.db.collection('bookings').document(booking_id).set(booking_data)
            self.db.collection('service_requests').document(req_id).update({
                "status": "booked",
                "booking_id": booking_id
            })
            
        return booking_id

    def update_booking_status(self, booking_id: str, new_status: str):
        if self.db:
            self.db.collection('bookings').document(booking_id).update({"status": new_status})

# Global instance
db = FirebaseDB()
