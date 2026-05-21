# Mishaal's Task — Database & Firebase
**FikrFree Hackathon | Due: May 20, 2026**

---

## Current State (What's Already Done ✅)

The backend team has already built `database/firebase_client.py` with the following methods working:

| Method | Status |
|:---|:---|
| `get_providers_by_category(category)` | ✅ Done — filters `is_active=True`, `strikes < 2` |
| `get_provider(provider_id)` | ✅ Done |
| `get_user(user_id)` | ✅ Done |
| `get_last_job(provider_id)` | ✅ Done — used by Scheduling Agent |
| `increment_provider_strikes(provider_id)` | ✅ Done — used by Dispute Agent |
| `save_request(...)` | ✅ Done |
| `add_log(...)` | ✅ Done — used by Trace Emitter |
| `create_booking(...)` | ✅ Done |
| `update_booking_status(...)` | ✅ Done |

`init_db.py` seeds the database with 3 AC providers + 7 plumbers. ✅

---

## 🚨 What Mishaal Needs To Do Now

### 1. Expand the Mock Dataset (CRITICAL)
**Why:** The architecture doc promises **100 providers across 5 cities**. Currently we only have **10 providers in 1 city (Lahore)**. Judges will ask how many providers were tested.

**Action:** Update `init_db.py` to add more providers with different cities and service types.

Required additions to `init_db.py`:
```python
# Add providers for each city
CITIES = {
    "Islamabad": {"lat": 33.6844, "lng": 73.0479},
    "Karachi":   {"lat": 24.8607, "lng": 67.0011},
    "Peshawar":  {"lat": 34.0151, "lng": 71.5249},
    "Quetta":    {"lat": 30.1798, "lng": 66.9750},
    "Lahore":    {"lat": 31.5204, "lng": 74.3587},
}
SERVICE_TYPES = ["ac_repair", "plumbing", "electrician", "cleaning", "painting"]
```

Each provider document must have **these new fields** the ranking agent now uses:

```python
{
    "id": "prv_...",
    "name": "...",
    "service_category": "ac_repair",     # existing
    "specialty": "split_ac",              # existing
    "is_active": True,                    # existing
    "location": {"lat": ..., "lng": ...}, # existing
    "rating": 4.5,                        # existing
    "cancellation_rate": 10,              # existing (as %)
    "on_time_score": 90,                  # existing (as %)
    "base_hourly_rate": 1200,             # existing
    "last_review_days_ago": 5,            # existing
    "strikes": 0,                         # ⚠️ ADD THIS — must exist or query fails
    "active_jobs": 1,                     # ⚠️ ADD THIS — used by Workload Factor
    "max_capacity": 5,                    # ⚠️ ADD THIS — used by Workload Factor
    "future_bookings": [],                # ⚠️ ADD THIS — used by Workload Factor
    "locked_slots": [],                   # ⚠️ ADD THIS — used by Booking Agent transaction
    "user_rated_before": False,           # ⚠️ ADD THIS — used by Preference History Factor
    "phone": "03001234567",               # ⚠️ ADD THIS — used by Notification Agent
    "home": {"lat": ..., "lng": ...},     # ⚠️ ADD THIS — used by Scheduling Agent
    "city": "Lahore",                     # ⚠️ ADD THIS — used by Discovery recovery
}
```

### 2. Fix the Firestore Composite Index Error (LIKELY)
**Why:** `firebase_client.py` line 33 uses `.where(...).where(...).where(...)` with a range filter (`strikes < 2`). Firestore requires a **composite index** for this.

**Action:** Go to Firebase Console → Firestore → Indexes → Add Composite Index:

| Collection | Fields | Order |
|:---|:---|:---|
| `providers` | `service_category` ASC | Ascending |
| `providers` | `is_active` ASC | Ascending |
| `providers` | `strikes` ASC | Ascending |

Without this, the Discovery Agent query will throw a Firestore error on first run.

### 3. Add `update_provider_workload()` Method
**Why:** When a booking is created, the provider's `active_jobs` count should increment so the Workload Balancing factor stays accurate across multiple bookings.

**Add this to `firebase_client.py`:**
```python
def update_provider_workload(self, provider_id: str, delta: int = 1):
    """Increment or decrement active_jobs for workload tracking."""
    if self.db:
        self.db.collection('providers').document(provider_id).update({
            "active_jobs": firestore.Increment(delta)
        })
```
Then call `db.update_provider_workload(provider_id, +1)` at the end of `create_booking()`.

### 4. Add `log_dispute()` Method
**Why:** The Dispute Agent currently writes strikes but doesn't log the dispute itself to Firestore for the frontend Dispute Screen.

**Add this to `firebase_client.py`:**
```python
def log_dispute(self, booking_id: str, provider_id: str, complaint: str, resolution: str, refund_amount: float):
    dispute_id = f"DISP-{uuid.uuid4().hex[:5].upper()}"
    if self.db:
        self.db.collection('disputes').document(dispute_id).set({
            "dispute_id": dispute_id,
            "booking_id": booking_id,
            "provider_id": provider_id,
            "complaint": complaint,
            "resolution": resolution,
            "refund_amount": refund_amount,
            "timestamp": datetime.utcnow().isoformat()
        })
    return dispute_id
```

### 5. Verify `init_db.py` Runs Without Errors
**Action:** After updating `init_db.py`, run it once to seed the database:
```bash
python init_db.py
```
Confirm in Firebase Console that collections `providers`, `users`, `bookings`, `service_requests`, `agent_logs` all have documents.

---

## Summary of Mishaal's Checklist

- [ ] Add `strikes`, `active_jobs`, `max_capacity`, `future_bookings`, `locked_slots`, `user_rated_before`, `phone`, `home`, `city` fields to ALL providers in `init_db.py`
- [ ] Expand providers to ~20+ across 5 cities and 5 service types
- [ ] Create Firestore Composite Index for `providers` collection
- [ ] Add `update_provider_workload()` method to `firebase_client.py`
- [ ] Add `log_dispute()` method to `firebase_client.py`
- [ ] Run `python init_db.py` and verify data in Firebase Console
- [ ] Share the live Firebase project URL with the team so the Flutter app can connect

---

## 📌 You Do NOT Need To Change
- The collection names — they are already correct
- The `firebase_client.py` core methods — they work as-is
- `serviceAccountKey.json` — keep this out of Git (already in `.gitignore`)
