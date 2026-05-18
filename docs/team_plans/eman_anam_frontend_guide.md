# Eman & Anam — Flutter Frontend Guide
**FikrFree Hackathon | Due: May 20, 2026**

> This guide tells you everything you need to build the Flutter APK. The backend is 100% ready. You just need to connect to it.

---

## 🌐 Backend URL
```
Base URL: http://localhost:8000    (local testing)
WebSocket: ws://localhost:8000/ws/trace
```
When the backend is deployed, replace `localhost:8000` with the server IP.

---

## The 8 Screens You Must Build

### Screen 1 — Home (Input)
**What it does:** User types their request in any language.

**UI Elements:**
- FikrFree logo / branding at top
- Large text field: placeholder `"Apni zaroorat likhein... e.g. Mujhe AC technician chahiye"`
- A language hint below: `Urdu • Roman Urdu • English supported`
- A big **"Find Provider"** button
- On submit → call the backend, navigate to Agent Trace screen

**API Call:**
```dart
// POST /api/request  OR  connect WebSocket /ws/trace
// WebSocket is preferred — gives live streaming

final ws = WebSocketChannel.connect(Uri.parse('ws://localhost:8000/ws/trace'));
ws.sink.add(jsonEncode({"user_id": "usr_789234", "text": userInput}));
```

---

### Screen 2 — Agent Trace (⭐ 20% of Score — Build This First)
**What it does:** Shows the AI "thinking" live as it processes the request. Each agent emits a card.

**UI Elements:**
- Title: `"FikrFree AI is working..."`
- A scrollable list of **Trace Cards** that appear one by one
- Each card shows: Agent Name, Status badge (completed/error/halted), Decision text, Duration

**Trace Card Structure (from backend WebSocket):**
```json
{
  "agent": "RankingAgent",
  "timestamp": "2025-05-18T10:23:11Z",
  "status": "completed",
  "decision": "Provider Rizwan chosen: ETA 12 min, cancel rate 1%",
  "duration_ms": 242
}
```

**Card Colors by Status:**
- `completed` → Green accent
- `halted` → Orange (clarification needed)
- `error` → Red with recovery text

**Dart WebSocket listener:**
```dart
ws.stream.listen((message) {
  final event = jsonDecode(message);
  setState(() {
    traceCards.add(event); // Adds card to the list
  });
});
```

> **Demo tip:** When `status == "halted"`, show a dialog asking the user to clarify (e.g., "Did you mean DHA Lahore or Islamabad?")

---

### Screen 3 — Provider List
**What it does:** Shows the ranked list of providers after the pipeline completes.

**Data comes from:** `ctx["ranked_providers"]` in the final WebSocket message.

**UI Elements (for each provider card):**
- Provider name + photo avatar (use initials if no photo)
- ⭐ Rating (e.g., 4.9)
- 📍 Distance (e.g., 1.2 km)
- ⏱ ETA (e.g., 12 min)
- 💰 Estimated price (e.g., PKR 1,450)
- AI Score badge (e.g., `Score: 0.87`)
- A **"View Details"** button

---

### Screen 4 — Provider Detail
**What it does:** Full profile of one provider before confirming the booking.

**UI Elements:**
- Name, photo, rating, city
- **Price Breakdown card:**
  ```
  Base Rate:           PKR 1,200
  Distance Surcharge:  PKR   80
  Urgency Multiplier:  x 1.3
  Complexity:          PKR  300
  Loyalty Discount:   -PKR  150
  ─────────────────────────────
  Total:               PKR 1,826
  ```
- Availability slots (show 3 buttons from `ctx["available_slots"]`)
- **"Confirm Booking"** button → navigate to Booking Confirmation

---

### Screen 5 — Booking Confirmation
**What it does:** Receipt / confirmation screen after booking is placed.

**Data:** `ctx["booking_id"]`, `ctx["slot"]`, `ctx["ranked_providers"][0]`

**UI Elements:**
- ✅ Large green checkmark animation
- Booking ID (e.g., `KC-BK-A3F2E`)
- Provider name + service type
- Scheduled slot (e.g., `Today at 2:00 PM`)
- Price total
- **"Track Service"** button → goes to Follow-Up screen

---

### Screen 6 — Follow-Up (Notification Timeline)
**What it does:** Shows the adaptive reminder timeline.

**Data:** `ctx["notification_timeline"]` — a list of events

**Example timeline items:**
```json
[
  {"time": "T-1h",      "message": "Rizwan arriving in 1 hour",    "status": "scheduled"},
  {"time": "En-route",  "message": "Rizwan is on his way",         "status": "pending"},
  {"time": "Arrived",   "message": "Rizwan has arrived",           "status": "pending"},
  {"time": "Completed", "message": "Service completed",            "status": "pending"},
  {"time": "Feedback",  "message": "Rate your experience",         "status": "pending"}
]
```

**UI:** Vertical stepper / timeline component, each step ticks green when `status == "sent"`.

---

### Screen 7 — Dispute
**What it does:** Lets the user report a problem after service.

**UI Elements:**
- Title: `"Report an Issue"`
- Dropdown: Dispute type (Overcharged, No-show, Poor quality)
- Text field: Describe your issue
- Amount field: `"What were you charged?"`
- **"Submit Dispute"** button

**API Call:**
```dart
// POST /api/provider/cancel  (for provider cancellation)
// The DisputeAgent is triggered automatically if user_rating <= 2
// For the demo, show a resolved dispute message from the lifecycle trace events
```

---

### Screen 8 — Baseline Compare
**What it does:** Shows side-by-side comparison of AI system vs dumb system. Judges love this.

**Data:** `ctx["ranked_providers"][0]` (AI) vs `ctx["baseline_ranked"][0]` (Dumb)

**UI:** Two cards side by side:

| | 🤖 FikrFree AI | 📏 Simple System |
|:--|:--|:--|
| Provider | Rizwan | Imran |
| ETA | 15 min | 10 min |
| Cancel Rate | 1% | 28% |
| Rating | 4.9 ⭐ | 4.2 ⭐ |
| **Result** | ✅ Reliable choice | ⚠️ High cancellation risk |

Caption: `"FikrFree AI avoided a provider with 28% cancellation rate."`

---

## 🔑 Key Things to Remember

### Navigation Flow
```
Home → Agent Trace (live) → Provider List → Provider Detail → Booking Confirmation → Follow-Up
                                                                                    ↓
                                                                               Dispute (if needed)
```

### State Management
Use a simple `Map<String, dynamic> ctx = {}` to pass the backend response between screens. Every screen reads from this `ctx`.

### Fallback (If WebSocket Fails)
```dart
// If WebSocket connection fails, use HTTP polling:
// GET /api/trace/{req_id}
// Poll every 2 seconds until pipeline completes
```

### Demo Triggers (Tell the judges)
- Send `"service_type": "cancel_test"` in user text to demo provider cancellation
- Send `"DHA"` as location to demo the ambiguity clarification screen
- Both of these are built into the backend — you don't need to code anything special

---

## Design Guidelines
- **Color palette:** Deep purple / indigo gradient with white cards
- **Font:** Google Fonts `Inter` or `Poppins`
- **Agent Trace cards:** Dark background with colored status badges (green/orange/red)
- **Animations:** `flutter_animate` package for card slide-in on the trace screen
- **Icons:** `lucide_flutter` or Material Icons

---

## What You Do NOT Need to Build
- Any AI logic — backend handles everything
- Any database — Firebase is managed by Mishaal
- Any authentication system — mock auth is handled by backend
- The actual reminder sending — Notification Agent simulates it; just display the timeline
