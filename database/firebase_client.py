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
        self.temp_users = {}
        self.temp_providers = {}
        self.temp_chats = {}
        self.temp_device_tokens = {}
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
        if not self.db:
            return self.temp_users.get(user_id)
        doc = self.db.collection('users').document(user_id).get()
        return doc.to_dict() if doc.exists else None

    def get_user_by_email(self, email: str) -> Any:
        if not self.db:
            for u in self.temp_users.values():
                if u.get("email") == email:
                    return u
            if email == "faiq@kaamconnect.pk":
                from auth import get_password_hash
                user = {
                    "id": "usr_789234",
                    "name": "Faiq Hassan",
                    "email": "faiq@kaamconnect.pk",
                    "phone": "03001234567",
                    "hashed_password": get_password_hash("password123"),
                    "role": "customer"
                }
                self.temp_users[user["id"]] = user
                return user
            return None
        docs = self.db.collection('users').where('email', '==', email).limit(1).stream()
        for doc in docs:
            return doc.to_dict()
        return None

    def create_user(self, user_data: dict) -> bool:
        if self.db:
            self.db.collection('users').document(user_data["id"]).set(user_data)
        else:
            self.temp_users[user_data["id"]] = user_data
        return True

    def get_provider_by_email(self, email: str) -> Any:
        if not self.db:
            for p in self.temp_providers.values():
                if p.get("email") == email:
                    return p
            if email == "ali@kaamconnect.pk":
                from auth import get_password_hash
                provider = {
                    "id": "prov_1",
                    "name": "Ali Tech",
                    "email": "ali@kaamconnect.pk",
                    "hashed_password": get_password_hash("password123"),
                    "role": "provider"
                }
                self.temp_providers[provider["id"]] = provider
                return provider
            return None
        docs = self.db.collection('providers').where('email', '==', email).limit(1).stream()
        for doc in docs:
            return doc.to_dict()
        return None

    def create_provider(self, provider_data: dict) -> bool:
        if self.db:
            self.db.collection('providers').document(provider_data["id"]).set(provider_data)
        else:
            self.temp_providers[provider_data["id"]] = provider_data
        return True

    def get_providers_by_category(self, category: str) -> List[Any]:
        if not self.db: 
            return [
                {
                    "id": "prov_1", "name": "Ali Tech", "service_category": category, "specialty": "general",
                    "is_active": True, "location": {"lat": 31.4750, "lng": 74.4050}, "rating": 4.8,
                    "cancellation_rate": 5, "on_time_score": 98, "base_hourly_rate": 1000, "last_review_days_ago": 2, "strikes": 0
                },
                {
                    "id": "prov_2", "name": "Babu Repairs", "service_category": category, "specialty": "general",
                    "is_active": True, "location": {"lat": 31.4700, "lng": 74.4020}, "rating": 4.5,
                    "cancellation_rate": 10, "on_time_score": 90, "base_hourly_rate": 800, "last_review_days_ago": 10, "strikes": 0
                }
            ]
        docs = self.db.collection('providers').where('service_category', '==', category).where('is_active', '==', True).where('strikes', '<', 2).stream()
        return [doc.to_dict() for doc in docs]
    
    def get_provider(self, provider_id: str) -> Any:
        if not self.db:
            return self.temp_providers.get(provider_id)
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

    def update_device_token(self, user_id: str, token: str) -> bool:
        self.temp_device_tokens[user_id] = token
        # Save to temp dicts for in-memory fallback
        if user_id in self.temp_users:
            self.temp_users[user_id]["device_token"] = token
        if user_id in self.temp_providers:
            self.temp_providers[user_id]["device_token"] = token

        if self.db:
            # Check user first, then provider
            user_doc = self.db.collection('users').document(user_id)
            if user_doc.get().exists:
                user_doc.update({"device_token": token})
                return True
            provider_doc = self.db.collection('providers').document(user_id)
            if provider_doc.get().exists:
                provider_doc.update({"device_token": token})
                return True
        return True

    def save_chat_message(self, booking_id: str, sender_id: str, text: str) -> dict:
        msg_id = f"msg_{uuid.uuid4().hex[:6]}"
        message_data = {
            "message_id": msg_id,
            "booking_id": booking_id,
            "sender_id": sender_id,
            "text": text,
            "timestamp": datetime.utcnow().isoformat()
        }
        if booking_id not in self.temp_chats:
            self.temp_chats[booking_id] = []
        self.temp_chats[booking_id].append(message_data)

        if self.db:
            self.db.collection('bookings').document(booking_id).collection('messages').document(msg_id).set(message_data)
        return message_data

    def get_chat_history(self, booking_id: str) -> List[Any]:
        if not self.db:
            return self.temp_chats.get(booking_id, [])
        
        docs = self.db.collection('bookings').document(booking_id).collection('messages').order_by('timestamp', direction=firestore.Query.ASCENDING).stream()
        messages = [doc.to_dict() for doc in docs]
        if not messages:
            # Fallback to local memory if Firestore collection is empty
            return self.temp_chats.get(booking_id, [])
        return messages

# Global instance
db = FirebaseDB()
