from datetime import datetime, timedelta

class NotificationAgent:
    name = "NotificationAgent"

    def __init__(self, ctx: dict):
        self.ctx = ctx

    async def run(self) -> dict:
        booking_id = self.ctx.get("booking_id")
        
        if not booking_id:
            # If we hit an error earlier, skip notifications
            return self.ctx
            
        ranked_providers = self.ctx.get("ranked_providers", [])
        if not ranked_providers:
            return self.ctx
            
        top_provider = ranked_providers[0]["provider"]
        phone = top_provider.get("phone", "03000000000")
        
        # Adaptive Timelines Logic
        # If preferred time isn't explicitly set, assume it's roughly 2 hours from now for mock
        intent = self.ctx.get("intent", {})
        pref_time_str = intent.get("preferred_time") or ""
        
        hours_until_job = 2 # default fallback
        if "tomorrow" in pref_time_str.lower():
            hours_until_job = 24
        elif "next week" in pref_time_str.lower():
            hours_until_job = 168
            
        timeline = []
        
        if hours_until_job >= 24:
            timeline.append({"time": "T-24h", "message": f"Reminder: Upcoming booking {booking_id} tomorrow.", "status": "scheduled"})
            
        if hours_until_job >= 1:
            timeline.append({"time": "T-1h", "message": f"Reminder: Provider {top_provider.get('name')} arriving in 1 hour.", "status": "scheduled"})
        else:
            timeline.append({"time": "Immediate", "message": f"Provider {top_provider.get('name')} dispatched immediately.", "status": "sent"})
            
        timeline.extend([
            {"time": "En-route", "message": f"Provider {top_provider.get('name')} is en-route.", "status": "pending"},
            {"time": "Arrived", "message": f"Provider {top_provider.get('name')} has arrived.", "status": "pending"},
            {"time": "Completed", "message": f"Service {booking_id} completed.", "status": "pending"},
            {"time": "Feedback", "message": f"Please rate your service with {top_provider.get('name')}.", "status": "pending"}
        ])
        
        self.ctx["notification_timeline"] = timeline
        self.ctx["notification_sent"] = f"Initial confirmation sent to {phone} for {booking_id}."
        
        return self.ctx
