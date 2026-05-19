from database.firebase_client import db

class AlreadyBookedError(Exception):
    pass

class BookingAgent:
    name = "BookingAgent"

    def __init__(self, ctx: dict):
        self.ctx = ctx

    async def _book_slot_transactional(self, provider_id: str, slot: str, booking_data: dict):
        # MOCK OF @firestore.async_transactional for the hackathon
        # In a real setup, this would be wrapped in the transaction decorator
        provider_ref = db.db.collection('providers').document(provider_id) if db.db else None
        
        if provider_ref:
            snap = provider_ref.get()
            data = snap.to_dict() or {}
            locked_slots = data.get("locked_slots", [])
            
            if slot in locked_slots:
                raise AlreadyBookedError(f"Slot {slot} was snatched!")
                
            locked_slots.append(slot)
            provider_ref.update({"locked_slots": locked_slots})
            
        booking_id = db.create_booking(
            req_id=booking_data["req_id"],
            user_id=booking_data["user_id"],
            provider_id=provider_id,
            price_breakdown=booking_data["price_breakdown"],
            slot=slot
        )
        return booking_id

    async def run(self) -> dict:
        req_id = self.ctx.get("req_id", "mock_req_123")
        user_id = self.ctx.get("user_id", "mock_user_123")
        
        ranked_providers = self.ctx.get("ranked_providers", [])
        if not ranked_providers:
            self.ctx["halt"] = True
            return self.ctx
            
        # In a bidding system, use the accepted provider from context, fallback to top provider
        accepted_provider_id = self.ctx.get("accepted_provider_id")
        
        top_provider = None
        if accepted_provider_id:
            for entry in ranked_providers:
                if entry["provider"].get("id") == accepted_provider_id:
                    top_provider = entry["provider"]
                    break
                    
        if not top_provider:
            top_provider = ranked_providers[0]["provider"]
            
        price_breakdown = self.ctx.get("price_breakdown", {})
        accepted_price = self.ctx.get("accepted_price")
        if accepted_price:
            price_breakdown["accepted_bid_price"] = accepted_price
            price_breakdown["total_price"] = accepted_price
        
        # Scheduling Agent assigned an earliest_slot
        selected_slot = top_provider.get("earliest_slot")
        if selected_slot:
            selected_slot = selected_slot.strftime("%I:%M %p")
        else:
            selected_slot = "12:00 PM"
            
        booking_data = {
            "req_id": req_id,
            "user_id": user_id,
            "price_breakdown": price_breakdown
        }
        
        try:
            booking_id = await self._book_slot_transactional(top_provider.get("id", "prov_1"), selected_slot, booking_data)
        except AlreadyBookedError:
            self.ctx["error_msg"] = "Double booking detected. Triggering re-rank."
            self.ctx["recovery_triggered"] = True
            self.ctx["recovery_action"] = "offer alternatives"
            self.ctx["halt"] = True # Handled by orchestrator fallback logic
            return self.ctx
            
        notification = {
            "type": "whatsapp_sms_simulation",
            "to": top_provider.get('phone', '03000000000'),
            "message": f"New booking: {top_provider.get('service_category')} at {selected_slot}. Booking ID: {booking_id}"
        }
        
        self.ctx["booking_id"] = booking_id
        self.ctx["slot"] = selected_slot
        self.ctx["notification"] = notification
        
        return self.ctx
