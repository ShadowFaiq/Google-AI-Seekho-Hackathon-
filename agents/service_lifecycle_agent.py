import random

class ServiceLifecycleAgent:
    name = "ServiceLifecycleAgent"

    def __init__(self, ctx: dict):
        self.ctx = ctx

    async def run(self) -> dict:
        ranked_providers = self.ctx.get("ranked_providers", [])
        if not ranked_providers:
            self.ctx["halt"] = True
            return self.ctx

        provider = ranked_providers[0]["provider"]
        provider_name = provider.get("name", "Provider")

        # --- Provider Cancellation Scenario (15% chance in mock, 100% if forced by intent) ---
        intent = self.ctx.get("intent", {})
        force_cancel = intent.get("service_type") == "cancel_test"
        provider_cancelled = force_cancel or (random.random() < 0.15)

        if provider_cancelled:
            # Step 1: Log ProviderCancelEvent
            self.ctx["provider_cancel_event"] = {
                "provider_id": provider.get("id"),
                "provider_name": provider_name,
                "reason": "Provider unavailable (mock cancellation)"
            }

            # Step 2: Re-rank — pop cancelled provider, fallback to next best
            ranked_providers.pop(0)
            self.ctx["ranked_providers"] = ranked_providers

            if ranked_providers:
                replacement = ranked_providers[0]["provider"]
                replacement_name = replacement.get("name", "Replacement Provider")

                # Step 3: Notify user
                self.ctx["notification_sent"] = (
                    f"{provider_name} cancelled your booking. "
                    f"We've automatically assigned {replacement_name} — your slot is preserved."
                )

                # Step 4: Auto-book replacement (mark booking updated)
                self.ctx["booking_reassigned"] = True
                self.ctx["booked_provider"] = replacement_name
                self.ctx["lifecycle_events"] = [
                    f"⚠️ {provider_name} cancelled after confirmation.",
                    f"✅ Auto-reassigned to {replacement_name}.",
                    f"📲 User notified: slot preserved with {replacement_name}."
                ]
            else:
                # No replacement available — halt and notify
                self.ctx["halt"] = True
                self.ctx["error_msg"] = f"{provider_name} cancelled and no replacement is available. Please rebook."

            self.ctx["user_rating"] = None  # No rating — service didn't happen
            return self.ctx

        # --- Normal lifecycle ---
        lifecycle_events = [
            f"Provider {provider_name} is en-route.",
            f"Provider {provider_name} has arrived.",
            "Service in progress. Verifying completion checklist...",
            "Service completed. Checklist verified (Photo evidence mock attached)."
        ]

        # Simulate feedback
        if intent.get("service_type") == "dispute_test":
            new_rating = 1.5
        else:
            new_rating = round(random.uniform(1.0, 5.0), 1)

        self.ctx["lifecycle_events"] = lifecycle_events
        self.ctx["user_rating"] = new_rating
        self.ctx["message"] = f"Customer left a {new_rating}-star review. Rating updated."

        return self.ctx
