from datetime import datetime, timedelta
from database.firebase_client import db
import math

class SchedulingAgent:
    name = "SchedulingAgent"

    def __init__(self, ctx: dict):
        self.ctx = ctx

    def maps_eta_mins(self, loc1, loc2) -> float:
        # Mocking Maps ETA (using Euclidean math for speed)
        dx = (loc1.get('lng', 0) - loc2.get('lng', 0)) * 111
        dy = (loc1.get('lat', 0) - loc2.get('lat', 0)) * 111
        dist_km = math.sqrt(dx*dx + dy*dy)
        return (dist_km / 40.0) * 60

    def compute_earliest_slot(self, provider, requested_time, user_loc):
        last_job = db.get_last_job(provider.get("id"))
        
        if last_job:
            travel_buffer = self.maps_eta_mins(last_job.get("location", provider.get("location")), user_loc)
            
            last_job_end_str = last_job.get("scheduled_slot", "12:00 PM")
            try:
                last_job_end = datetime.strptime(last_job_end_str, "%I:%M %p")
                # Assume today
                last_job_end = datetime.now().replace(hour=last_job_end.hour, minute=last_job_end.minute, second=0, microsecond=0)
            except:
                last_job_end = datetime.now()
                
            earliest = last_job_end + timedelta(minutes=travel_buffer + 15)
        else:
            travel_buffer = self.maps_eta_mins(provider.get("location", {"lat": 0, "lng": 0}), user_loc)
            earliest = datetime.now() + timedelta(minutes=travel_buffer)
            
        requested_dt = datetime.now()
        if requested_time:
            # simple mock
            pass 
            
        return max(earliest, requested_dt)

    async def run(self) -> dict:
        providers = self.ctx.get("providers", [])
        intent = self.ctx.get("intent", {})
        user_loc = intent.get("user_location", {"lat": 31.4697, "lng": 74.4012})
        requested_time = intent.get("preferred_time")
        
        # Pre-filter and assign earliest slot to each provider
        available_providers = []
        for provider in providers:
            earliest = self.compute_earliest_slot(provider, requested_time, user_loc)
            provider["earliest_slot"] = earliest
            # We assume all are available in this mock, but they get different slots
            available_providers.append(provider)
            
        self.ctx["providers"] = available_providers
        return self.ctx
