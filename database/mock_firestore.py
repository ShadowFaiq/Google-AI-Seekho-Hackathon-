import uuid
from typing import Dict, List, Any
from datetime import datetime, timedelta

# Mock data store for Firestore
class MockFirestore:
    def __init__(self):
        self.users: Dict[str, Any] = {
            "usr_789234": {
                "user_id": "usr_789234",
                "name": "Anum",
                "email": "anum@kaamconnect.pk",
                "phone": "+923001112223",
                "role": "customer",
                "saved_addresses": {
                    "home": {"lat": 31.4697, "lng": 74.4012, "text": "Phase 5 DHA, Lahore"},
                    "g13": {"lat": 33.6425, "lng": 72.9691, "text": "G-13, Islamabad"}
                }
            }
        }

        self.providers: Dict[str, Any] = {
            "prv_111": {
                "provider_id": "prv_111",
                "name": "Kamran Electrician & AC",
                "phone": "+923214445556",
                "service_category": "ac_repair",
                "specialty": "Inverter Board Repair",
                "base_hourly_rate": 1500,
                "is_active": True,
                "location": {"lat": 33.6400, "lng": 72.9600}, # Close to G-13
                "metrics": {
                    "rating": 4.8,
                    "total_reviews": 84,
                    "review_recency_days": 3,
                    "on_time_score": 0.96,
                    "cancellation_rate": 0.01,
                    "completion_rate": 0.98,
                    "trust_score": 94 # Base trust score
                },
                "slots": {
                    "tomorrow": ["10:00 AM", "12:00 PM", "04:00 PM"]
                }
            },
            "prv_222": {
                "provider_id": "prv_222",
                "name": "Zahid Iqbal AC Services",
                "phone": "+923214445557",
                "service_category": "ac_repair",
                "specialty": "Basic Servicing",
                "base_hourly_rate": 1200,
                "is_active": True,
                "location": {"lat": 33.6420, "lng": 72.9680}, # Very close to G-13
                "metrics": {
                    "rating": 4.1,
                    "total_reviews": 32,
                    "review_recency_days": 14,
                    "on_time_score": 0.80,
                    "cancellation_rate": 0.14, # High cancellation
                    "completion_rate": 0.85,
                    "trust_score": 67
                },
                "slots": {
                    "tomorrow": ["10:00 AM", "02:00 PM"]
                }
            },
            "prv_333": {
                "provider_id": "prv_333",
                "name": "Tariq Master Plumber",
                "phone": "+923214445558",
                "service_category": "plumbing",
                "specialty": "Pipe Leakage",
                "base_hourly_rate": 1000,
                "is_active": True,
                "location": {"lat": 31.4700, "lng": 74.4000}, # Close to DHA Lahore
                "metrics": {
                    "rating": 4.9,
                    "total_reviews": 150,
                    "review_recency_days": 1,
                    "on_time_score": 0.99,
                    "cancellation_rate": 0.00,
                    "completion_rate": 1.0,
                    "trust_score": 98
                },
                "slots": {
                    "today": ["06:00 PM", "08:00 PM"],
                    "tomorrow": ["09:00 AM", "11:00 AM"]
                }
            }
        }

        self.service_requests: Dict[str, Any] = {}
        self.bookings: Dict[str, Any] = {}
        self.agent_logs: Dict[str, List[Any]] = {}

    def get_user(self, user_id: str) -> Any:
        return self.users.get(user_id)

    def get_providers_by_category(self, category: str) -> List[Any]:
        return [p for p in self.providers.values() if p["service_category"] == category and p["is_active"]]
    
    def get_provider(self, provider_id: str) -> Any:
        return self.providers.get(provider_id)

    def save_request(self, user_id: str, request_text: str, structured_data: dict) -> str:
        req_id = f"req_{uuid.uuid4().hex[:6]}"
        self.service_requests[req_id] = {
            "request_id": req_id,
            "user_id": user_id,
            "user_request": request_text,
            "parsed_data": structured_data,
            "status": "pending",
            "timestamp": datetime.utcnow().isoformat()
        }
        self.agent_logs[req_id] = []
        return req_id

    def add_log(self, req_id: str, agent: str, action: str, reasoning: str, data: Any = None):
        if req_id not in self.agent_logs:
            self.agent_logs[req_id] = []
        
        log_entry = {
            "log_id": f"log_{uuid.uuid4().hex[:6]}",
            "agent": agent,
            "action": action,
            "reasoning": reasoning,
            "data": data,
            "timestamp": datetime.utcnow().isoformat()
        }
        self.agent_logs[req_id].append(log_entry)
        return log_entry

    def create_booking(self, req_id: str, user_id: str, provider_id: str, price_breakdown: dict, slot: str) -> str:
        booking_id = f"KC-BK-{uuid.uuid4().hex[:5].upper()}"
        provider = self.providers[provider_id]
        
        self.bookings[booking_id] = {
            "booking_id": booking_id,
            "request_id": req_id,
            "user_id": user_id,
            "selected_provider": provider_id,
            "provider_name": provider["name"],
            "service": provider["service_category"],
            "status": "Confirmed",
            "price_breakdown": price_breakdown,
            "scheduled_slot": slot,
            "reminder_status": "Scheduled",
            "timestamp": datetime.utcnow().isoformat()
        }
        
        if req_id in self.service_requests:
            self.service_requests[req_id]["status"] = "booked"
            self.service_requests[req_id]["booking_id"] = booking_id
            
        return booking_id
    
    def update_booking_status(self, booking_id: str, new_status: str):
        if booking_id in self.bookings:
            self.bookings[booking_id]["status"] = new_status

# Global instance
db = MockFirestore()
