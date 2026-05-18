# FikrFree 🧠
### AI-Powered Service Booking — Google Antigravity Hackathon, Challenge 2

> **"Fikr mat karo"** — FikrFree handles your entire home service booking lifecycle using a 10-agent AI pipeline.

---

## What is FikrFree?
FikrFree is an **agentic AI system** that takes a natural language service request in Urdu, Roman Urdu, or English and handles the entire booking lifecycle automatically.

**Example:**
> User types: *"Mujhe kal subah AC technician chahiye G-13 mein"*  
> FikrFree: understands it → finds providers → ranks them → books a slot → sends confirmation → schedules reminders

This is **not** a booking app. It is an **Antigravity-powered multi-agent system** where every decision is logged, traced, and explainable.

---

## Tech Stack
| Layer | Technology |
|:---|:---|
| AI Orchestration | Google Antigravity |
| Reasoning Engine | Google Gemini 1.5 Flash |
| Backend | FastAPI (Python) |
| Database | Google Cloud Firestore |
| Mobile | Flutter APK |
| Real-time Trace | WebSockets + HTTP Polling fallback |

---

## The 10-Agent Pipeline
```
Intent → GeoNorm → Discovery → Scheduling → Ranking → Pricing → Booking → Notification → Lifecycle
                                                                                              ↓ (if rating ≤ 2)
                                                                                          DisputeAgent
```

---

## 🚀 Getting Started (Backend)

### 1. Clone the repo
```bash
git clone https://github.com/your-repo/fikrfree.git
cd fikrfree
```

### 2. Create your environment file
```bash
cp .env.example .env
# Then open .env and fill in your actual API keys
```

### 3. Add your Firebase service account key
- Go to Firebase Console → Project Settings → Service Accounts → Generate New Private Key
- Save the downloaded JSON file as `serviceAccountKey.json` in the project root
- ⚠️ This file is in `.gitignore` — never commit it

### 4. Install dependencies
```bash
python -m venv .venv
.venv\Scripts\activate       # Windows
# source .venv/bin/activate  # Mac/Linux
pip install -r requirements.txt
```

### 5. Seed the database
```bash
python init_db.py
```

### 6. Run the backend
```bash
uvicorn main:app --reload
```
API docs available at: `http://localhost:8000/docs`

---

## 🧪 Test the Pipeline (WebSocket)
Use any WebSocket client (e.g. [Hoppscotch](https://hoppscotch.io/realtime/websocket)):
```
URL: ws://localhost:8000/ws/trace

Send:
{
  "user_id": "usr_789234",
  "text": "Mujhe kal subah AC technician chahiye G-13 mein"
}
```
Watch each agent fire in sequence with live trace events.

---

## 🔑 Demo Trigger Flags (for Judges)
| Scenario | How to Trigger |
|:---|:---|
| Provider cancellation | `"text": "cancel_test"` |
| Force dispute | `"service_type": "dispute_test"` |
| Location ambiguity | Use `"DHA"` as location (no city) |
| Emergency override | Use `"urgency": "emergency"` |

---

## 📁 Project Structure
```
fikrfree/
├── main.py                    # Antigravity Orchestrator + all API endpoints
├── baseline_engine.py         # Dumb comparison system
├── init_db.py                 # Database seeding script
├── requirements.txt
├── .env.example               # ← Copy this to .env and fill in your keys
├── agents/
│   ├── intent_agent.py
│   ├── geo_normalization_agent.py
│   ├── discovery_agent.py
│   ├── scheduling_agent.py
│   ├── ranking_agent.py
│   ├── pricing_agent.py
│   ├── booking_agent.py
│   ├── notification_agent.py
│   ├── service_lifecycle_agent.py
│   └── dispute_agent.py
├── database/
│   └── firebase_client.py
└── docs/
    ├── architecture_overview.md
    ├── project_status 1.md
    ├── project_status 2.md
    └── team_plans/
        ├── eman_anam_frontend_guide.md
        ├── mishaal_database_tasks.md
        └── ...
```

---

## 📋 Team Tasks
| Team Member | Task File |
|:---|:---|
| **Mishaal** | `docs/team_plans/mishaal_database_tasks.md` |
| **Eman & Anam** | `docs/team_plans/eman_anam_frontend_guide.md` |

---

## ⚠️ Security Notes
- **Never commit** `.env` or `serviceAccountKey.json` — both are in `.gitignore`
- Share API keys with teammates **privately** (WhatsApp DM, not GitHub)
- Use `.env.example` as a template

---

*Built with ❤️ for Google AI Seekho Hackathon 2026*