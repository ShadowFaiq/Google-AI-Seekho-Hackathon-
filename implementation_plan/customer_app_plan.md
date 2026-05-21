# Connect Flutter Apps to Backend and Preview

This plan details the steps to fully connect the two Flutter applications (`customer_flutter_app` and `provider_flutter_app`) to the FastAPI backend, implementing the required AI tracking screens, and finally launching a preview.

## User Review Required
> [!IMPORTANT]
> The `customer_flutter_app` directory currently lacks the Flutter core files (`lib`, `pubspec.yaml`, etc.). I will need to recreate the Flutter project structure for it to proceed. Does this sound correct? Also, do you prefer to see the preview in a web browser (Chrome) or an Android Emulator? Browser is much faster for a quick preview.

## Open Questions
> [!WARNING]
> Do you have the `flutter` SDK installed and configured in your `PATH`? If not, we'll need to set that up or use web-based alternatives. 

## Proposed Changes

### 1. Initialize `customer_flutter_app`
Currently, this directory only contains `android`, `ios`, and `macos` folders.
- Run `flutter create .` inside `customer_flutter_app` to generate the missing `lib` directory and `pubspec.yaml`.
- Add necessary dependencies to `pubspec.yaml`:
  - `http`
  - `web_socket_channel`
  - `flutter_animate`
  - `lucide_flutter` (or equivalent icons)

### 2. Implement Frontend Guide Screens (Customer App)
As requested in the frontend guide, I will build the 8 required screens for the `customer_flutter_app` to interact with the backend AI agents:
#### [NEW] [main.dart](file:///c:/Users/HP/Desktop/repo1/Google-AI-Seekho-Hackathon-/customer_flutter_app/lib/main.dart)
#### [NEW] [api_service.dart](file:///c:/Users/HP/Desktop/repo1/Google-AI-Seekho-Hackathon-/customer_flutter_app/lib/services/api_service.dart) (WebSocket and HTTP logic)
#### [NEW] [home_screen.dart](file:///c:/Users/HP/Desktop/repo1/Google-AI-Seekho-Hackathon-/customer_flutter_app/lib/screens/home_screen.dart) (Screen 1 - Home)
#### [NEW] [agent_trace_screen.dart](file:///c:/Users/HP/Desktop/repo1/Google-AI-Seekho-Hackathon-/customer_flutter_app/lib/screens/agent_trace_screen.dart) (Screen 2 - WebSocket Live Trace)
#### [NEW] [provider_list_screen.dart](file:///c:/Users/HP/Desktop/repo1/Google-AI-Seekho-Hackathon-/customer_flutter_app/lib/screens/provider_list_screen.dart) (Screen 3 - Provider List)
#### [NEW] [provider_detail_screen.dart](file:///c:/Users/HP/Desktop/repo1/Google-AI-Seekho-Hackathon-/customer_flutter_app/lib/screens/provider_detail_screen.dart) (Screen 4 - Detail)
#### [NEW] [booking_confirmation_screen.dart](file:///c:/Users/HP/Desktop/repo1/Google-AI-Seekho-Hackathon-/customer_flutter_app/lib/screens/booking_confirmation_screen.dart) (Screen 5 - Confirmation)
#### [NEW] [follow_up_screen.dart](file:///c:/Users/HP/Desktop/repo1/Google-AI-Seekho-Hackathon-/customer_flutter_app/lib/screens/follow_up_screen.dart) (Screen 6 - Timeline)
#### [NEW] [dispute_screen.dart](file:///c:/Users/HP/Desktop/repo1/Google-AI-Seekho-Hackathon-/customer_flutter_app/lib/screens/dispute_screen.dart) (Screen 7 - Dispute)
#### [NEW] [baseline_compare_screen.dart](file:///c:/Users/HP/Desktop/repo1/Google-AI-Seekho-Hackathon-/customer_flutter_app/lib/screens/baseline_compare_screen.dart) (Screen 8 - Compare)

### 3. Verify `provider_flutter_app`
- Review the existing `ApiService` logic in the provider app.
- Ensure the provider app can authenticate and show the dashboard pulling from the backend.

### 4. Backend Setup
- Verify the Python environment and run `init_db.py` to seed the database if necessary.
- Launch the `uvicorn main:app` process in the background to serve the API.

## Verification Plan

### Automated/Manual Verification
- I will run the Python FastAPI backend in the background.
- I will launch the Flutter application preview using `flutter run -d chrome`.
- We will verify that submitting a natural language request in the customer app correctly triggers the WebSocket AI Trace and updates the UI in real-time.
