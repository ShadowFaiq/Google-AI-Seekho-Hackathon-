# Merging Apps and Implementing Missing Backend Features

To fulfill your request of connecting both sides into a single unified app and utilizing ALL backend endpoints, I have formulated the following implementation plan.

## User Review Required
> [!IMPORTANT]
> Merging these two codebases means `customer_flutter_app` will become the definitive **Unified FikrFree App**. I will copy the provider screens over and re-route the "Provider" button to open the `ProviderLoginScreen` internally instead of a new browser tab. Are you okay with retiring `provider_flutter_app`?

## Proposed Changes

### 1. Merge Codebases
- Copy the provider screens, widgets, models, and mock data from `provider_flutter_app/lib/` to `customer_flutter_app/lib/provider_side/`.
- Update `customer_flutter_app/lib/main.dart` to include the provider routes.
- Update `customer_flutter_app/lib/screens/role_selection_screen.dart` to navigate directly to `/provider_login` via standard Flutter routing (`Navigator.pushNamed`).
- Merge `api_service.dart` from the provider app into the customer app's `api_service.dart` so all API calls live in one place.

### 2. Implement Missing Backend Functionality
I audited the FastAPI backend and found 3 features that are currently unused in the frontend. I will build the Flutter UI and API hooks for them:

#### A. Real-time WebSocket Chat
- **Backend Endpoints:** `GET /api/chat/{booking_id}/history` & `WS /ws/chat/{booking_id}/{user_id}`
- **Frontend Update:** Create a new `chat_screen.dart` accessible from the Customer's Receipt Screen and the Provider's Job Progress Screen. This screen will fetch history and open a WebSocket connection for live messaging.

#### B. Provider Cancellation (Webhook Simulation)
- **Backend Endpoint:** `POST /api/provider/cancel`
- **Frontend Update:** Add a "Cancel Job" button in the Provider's `job_progress_screen.dart` that triggers this endpoint. The backend handles autonomous re-allocation.

#### C. Push Notifications Token Registration
- **Backend Endpoint:** `POST /api/notification/register-device-token`
- **Frontend Update:** Update the Customer and Provider Login/Registration flows to call this endpoint automatically upon successful authentication (using a mock FCM token for the web demo).

## Verification Plan
1. Launch the unified Flutter app on Chrome.
2. Click "Provider" on the Role Selection screen to ensure it routes internally.
3. Login as a provider and trigger the "Cancel Job" webhook.
4. Navigate to the new Chat Screen and verify WebSocket connection and history loading.
5. Verify terminal logs to ensure device tokens are registered upon login.
