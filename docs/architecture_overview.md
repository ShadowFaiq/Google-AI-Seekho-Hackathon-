# FikrFree: Final Hackathon System Architecture

This document outlines the **final**, judge-approved architecture for the **FikrFree** Hackathon submission, hitting all mandatory requirements of Challenge 2.

---

## 1. The Technology Stack
- **AI Orchestration Layer:** Google Antigravity (Manages multi-agent workflows, tool execution, and the DAG)
- **Reasoning Engine:** Google Gemini 1.5 Flash (Performs multilingual understanding, dispute arbitration, and geo-normalization)
- **Backend Framework:** FastAPI (Python)
- **Database:** Google Cloud Firestore (Firebase)
- **Frontend / Mobile:** Flutter APK (Supports offline caching of trace logs and previous sessions; core booking requires connectivity)
- **Real-time Trace:** WebSockets with HTTP Long-Polling fallback

---

## 2. The 10-Agent Hybrid Pipeline (9 Sequential + 1 Event-Driven)

To ensure a seamless flow rather than disconnected scripts, the entire pipeline is managed by a central **Antigravity Orchestrator** (`main.py`). This orchestrator dispatches 9 lightweight agents sequentially, followed by 1 event-driven agent (DisputeAgent) if triggered, explicitly handling failure recoveries.

```python
class Orchestrator:
    pipeline = [
        IntentAgent, GeoNormalizationAgent, DiscoveryAgent, SchedulingAgent, 
        RankingAgent, PricingAgent, BookingAgent, NotificationAgent, 
        ServiceLifecycleAgent
    ]
    
    async def run(self, ctx):
        # ... sequential execution ...
        
        # Event-driven Dispute Routing
        if ctx.get("user_rating", 5) <= 2 or ctx.get("complaint"):
            ctx = await DisputeAgent(ctx).run()
```

### 1. Intent Agent (`intent_agent.py`)
- **What it does:** Uses Gemini 1.5 Flash to parse messy Roman Urdu/English text. Extracts budget, urgency, and service details.
- **Multilingual Confidence Details:** Confidence is not a black box. It is derived from a strict breakdown: `{intent_certainty, location_certainty, time_certainty, service_certainty}`.
- **Output Schema:** Extracts `service_type`, `budget: int | None`, `urgency`, etc.

### 2. GeoNormalization Agent (`geo_normalization_agent.py`)
- **What it does:** Solves the mixed-language location problem. Translates `"جی تیرہ"`, `"G13"`, `"model town"` into strict LatLng coordinates using Gemini reasoning.
- **Ambiguity Handling:** If the resolved location has a `location_confidence < 0.75` (e.g. `"DHA"` exists in 4+ cities, or `"Satellite Town"` in 3+ cities), the agent **halts the pipeline** and asks the user a targeted clarification question before proceeding:
  ```
  "Do you mean DHA Lahore, DHA Islamabad, or DHA Karachi?"
  ```
  This directly satisfies the Challenge 2 multilingual ambiguity requirement and prevents the rest of the pipeline from running on incorrect coordinates.

### 3. Discovery Agent (`discovery_agent.py`)
- **What it does:** Queries Firebase for active technicians matching the service category, strictly excluding blacklisted providers (`strikes < 2`).
- **4-Step Recovery Chain:** If 0 providers are found, the Orchestrator executes an explicit recovery sequence instead of failing silently:
  ```
  Step 1: Expand radius 5km → 10km
      ↓ still none?
  Step 2: Offer a later time slot today
      ↓ still none?
  Step 3: Offer the nearest available city
      ↓ still none?
  Step 4: Recommend next available day
  ```
  Every step emits a distinct trace event (`status: "error", recovery: "expand_radius"`) visible on the Agent Trace screen.

### 4. Scheduling Agent (`scheduling_agent.py`)
- **What it does:** Takes Google Maps ETA and adds a dynamic "Travel Time Buffer" (+15m) preventing double-booking.

### 5. Ranking Agent (`ranking_agent.py`) **[The 10-Factor Matrix]**
- **What it does:** Ranks providers based on 10 critical factors. Distance alone is strictly penalized. 
- **The Workload Balancing & Budget Factors:**
  1. **Drive Time (ETA):** `0.15`
  2. **Rating:** `0.15`
  3. **Cancellation Rate:** `0.15`
  4. **On-Time Score:** `0.10`
  5. **Review Recency:** `0.10`
  6. **Skill Specialization:** `0.10`
  7. **Base Hourly Rate:** `0.05`
  8. **Preference History:** `0.05`
  9. **Workload Balancing:** `1 - ((active_jobs + future_bookings) / max_capacity)` (Weight: `0.10`) — Huge points for preventing burnout.
  10. **Budget Fit:** Safe formula protecting against division by zero (Weight: `0.05`)
      ```python
      if budget and budget > 0:
          budget_fit = max(0.0, 1.0 - abs(rate-budget)/budget)
      else:
          budget_fit = 1.0 # Neutral if no budget specified
      ```

  *Note: **Emergency Override** – If the Intent Agent detects an emergency ("short circuit", "gas leak"), the ETA weight dynamically shifts to `0.50`, and all other 9 weights are mathematically scaled down to sum to `0.50`.*

### 6. Pricing Agent (`pricing_agent.py`)
- **What it does:** Calculates `Base rate + distance surcharge + urgency multiplier (same day 1.3x) + job complexity - loyalty discount`.

### 7. Booking Agent (`booking_agent.py`)
- **What it does:** Finalizes booking via Firestore `@firestore.async_transactional`.
- **Race Condition Recovery:** If `AlreadyBookedError` is caught, the orchestrator triggers a trace `status: "error", recovery: "offer alternatives"` and falls back to the next ranked provider.

### 8. Notification Agent (`notification_agent.py`)
- **What it does:** Executes an **adaptive** follow-up timeline based on how far away the booking is.
- **Adaptive Logic:**
  - `hours_until_job >= 24` → include `T-24h` reminder
  - `hours_until_job >= 1` → include `T-1h` reminder  
  - `hours_until_job < 1` → skip both, send **Immediate Dispatch** notification instead
  ```
  T-24h (if applicable) → T-1h (if applicable) → Immediate (if same-hour)
  → Provider En-Route → Provider Arrived → Service Completed → Feedback Request
  ```

### 9. Service Lifecycle Agent (`service_lifecycle_agent.py`)
- **What it does:** Simulates the full post-booking experience: en-route, arrival, service completion, and user feedback.
- **Provider Cancellation Recovery:** This agent handles the mandatory stress-test scenario where a provider cancels **after confirmation**. It follows a strict 4-step automated recovery:
  ```
  Step 1: Log ProviderCancelEvent (provider_id, reason, timestamp)
      ↓
  Step 2: Re-rank — pop cancelled provider, promote next best from ranked_providers
      ↓
  Step 3: Notify user ("Rizwan cancelled. Auto-assigned Ali — slot preserved.")
      ↓
  Step 4: Auto-book replacement provider, emit trace event
  ```
  This is demoable by sending `service_type: "cancel_test"` in the request, which forces the cancellation path every time — perfect for judge demonstrations.

### 10. Dispute Resolution Agent (`dispute_agent.py`)
- **What it does:** Evaluates complaints autonomously. Automatically refunds and issues DB strikes to providers if they violate pricing policies.

---

## 3. The Baseline Engine (`baseline_engine.py`)
To prove the AI's value, we run a parallel "Dumb System" that only evaluates `baseline_score = 0.8*(distance) + 0.2*(price)`. 
- **Baseline Compare Screen:** The frontend explicitly compares:
  - *Baseline Choice:* Provider B (ETA: 10 min, Cancel Rate: 28%)
  - *AI Choice:* Provider A (ETA: 15 min, Cancel Rate: 1%)
  - *Result:* Agent avoided a highly likely cancellation.

---

## 4. Mobile APK Frontend Architecture
The mandatory **Flutter APK** drives the user experience.
- **Single App Architecture:** We use one unified APK with Role-Based Access Control (Customer View, Provider View, Admin/Judge Demo View) to reduce complexity.
- **Offline Capabilities:** Supports offline caching of trace logs and previous sessions. Core booking requires an active internet connection.
- **Screens:** 
  1. Home (Multilingual Input)
  2. Provider List
  3. Provider Detail
  4. Booking Confirmation
  5. Follow-up
  6. **Agent Trace** (Renders WebSocket logs visualizing Antigravity workflow)
  7. Dispute
  8. Baseline Compare

---

## 5. Provider App & Authentication
- **Auth:** Secured via Firebase Auth / JWT Role-Based access control.
- **Workload APIs:** `/provider/dashboard`, `/provider/availability`, `/provider/demand-forecast`.

---

## 6. Observability Metrics & Trace Visualizer
- **Trace Visualization:** Live JSON trace streamed via `/ws/trace` (with HTTP polling fallback).
- **System Metrics:** Tracks Average Response Time, Clarification Rate, Booking Success %, Failure Recovery %, and Cancellation %.

### The Agent Trace Event Schema
Every agent in the pipeline emits a structured JSON event to `/ws/trace`. This powers the **Agent Trace screen** (worth ~20% of the judging score). The frontend renders each event as a reasoning card.

```json
{
  "agent": "RankingAgent",
  "timestamp": "2025-05-18T10:23:11Z",
  "status": "completed",
  "inputs": {
    "user_input": "Mujhe kal subah AC technician chahiye G-13 mein"
  },
  "outputs": {
    "top_provider": "Rizwan Ahmed",
    "score": 0.874
  },
  "decision": "Provider Rizwan chosen: low cancellation rate (1%), ETA 12 min, skill match split_ac",
  "duration_ms": 242
}
```

**`status` field values:**

| Value | Meaning |
|:---|:---|
| `completed` | Agent ran successfully |
| `halted` | Agent paused pipeline for clarification |
| `error` | Agent hit a failure, recovery triggered |

**Failure recovery example** (double-booking scenario):
```json
{
  "agent": "BookingAgent",
  "timestamp": "2025-05-18T10:23:14Z",
  "status": "error",
  "recovery": "offer alternatives",
  "decision": "Slot 10:00 AM already locked by another user. Re-allocating to next ranked provider.",
  "duration_ms": 87
}
```

---

## 7. Stress Test Coverage & Recovery Paths
We have explicitly designed the Antigravity Orchestrator to gracefully recover from the mandatory failure scenarios:

| Scenario | Antigravity Handling |
| :--- | :--- |
| **No provider available** | `DiscoveryAgent` expands radius (5km → 10km → tomorrow). |
| **Double booking** | `BookingAgent` hits Firestore transaction lock, throws `AlreadyBookedError`, and triggers automatic re-rank. |
| **Mixed language/location** | `IntentAgent` & `GeoNormalizationAgent` loop back for clarification ("Do you mean DHA Lahore or Islamabad?"). |
| **Provider cancels** | Webhook triggers `ProviderCancelEvent`, forcing Orchestrator to re-rank and notify the user. |
| **Price dispute** | Event-driven `DisputeAgent` uses Gemini to arbitrate, refund, and issue DB strikes. |
| **Concurrent users** | Atomic slot locking via Firestore prevents silent overwrites. |

---

## 8. Synthetic Mock Dataset Specification
**Disclaimer:** No real user, provider, or PII data is stored or processed. 
- **Dataset Size:** 100 Mock Providers
- **Coverage:** 5 Major Cities (Islamabad, Lahore, Karachi, Peshawar, Quetta)
- **Data Points:** Synthetic ratings, cancellation histories, dynamic availability slots, and service skills.
