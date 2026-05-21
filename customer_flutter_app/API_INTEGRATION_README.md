# FikrFree Customer App: API Integration Reference Guide

This document explains the backend API integrations inside the customer-side Flutter application, outlining which endpoints are active, which are pending/missing from the running FastAPI backend, and how the demo fallbacks operate during tests.

---

## 1. Connected APIs and Screen Mapping

- **`/api/request`**: Fully **connected** to `UserRequestScreen`. On submission, it sends the request parameters to the backend.
- **`/api/trace/{req_id}`**: Fully **connected** to `TraceVisualizerScreen`. It polls or fetches the live orchestration trace from the backend.
- **Auth APIs (`/api/auth/login`, `/api/auth/register`)**: **Pending** and not currently exposed in Swagger. The app uses a safe onboarding demo flow when these endpoints fail.
- **Bid APIs (`/api/bids/offer`, `/api/bids/accept`)**: **Pending** and not currently exposed in Swagger.
- **Bidding Screen**: Currently uses a high-fidelity **demo fallback** with interactive bid items until the backend exposes the bid routes.

| API Route | HTTP Method | Screen / Component | Purpose | Status in Running Backend |
| :--- | :--- | :--- | :--- | :--- |
| `/api/auth/register` | `POST` | `UserAuthScreen` (Create Account) | Creates a new customer account | ⚠️ **Pending / Missing** (Fallback to demo flow) |
| `/api/auth/login` | `POST` | `UserAuthScreen` (Login) | Logs in an existing customer | ⚠️ **Pending / Missing** (Fallback to demo flow) |
| `/api/request` | `POST` | `UserRequestScreen` (Prepare My Request) | Submits service details to start AI orchestration | ✅ **Active & Connected** |
| `/api/bids/offer` | `POST` | `BiddingScreen` (Place Bid) | Places customer bid price | ⚠️ **Pending / Missing** (Uses demo bids fallback) |
| `/api/bids/accept` | `POST` | `BiddingScreen` (Accept Bid) | Accepts provider bid and locks the rate | ⚠️ **Pending / Missing** (Uses demo booking fallback) |
| `/api/trace/{req_id}`| `GET` | `TraceVisualizerScreen` (Trace View) | Fetches the live agent orchestration logs | ✅ **Active & Connected** |

---

## 2. Fallback / Demo Mode Mechanism

When the customer app hits a missing/pending endpoint, or when the FastAPI backend is completely offline:
1. The app catches the `HttpException` or `SocketException` safely.
2. A user-friendly `SnackBar` notification is displayed (e.g. `"Auth backend endpoint pending. Continuing in demo mode."`).
3. The app injects mock data parameters (such as a random Booking ID, standard suggested pricing variables, or pre-populated agent trace timelines) and routes the user to the next screen.
4. **This ensures the entire customer workflow is 100% testable during the hackathon under any network or deployment condition.**

---

## 3. Testing Environments

### Configurable Base URL
The backend server URL is configured inside:
`customer_flutter_app/lib/services/api_service.dart`

To switch environments, update `ApiService.baseUrl`. The default is `http://127.0.0.1:8000`.

### A. Testing on Chrome (Web)
1. Run the FastAPI backend:
   ```bash
   python -m uvicorn main:app --reload
   ```
2. Run the Flutter web client from `customer_flutter_app/`:
   ```bash
   flutter run -d chrome
   ```
3. Set `ApiService.baseUrl` to `'http://127.0.0.1:8000'`.

### B. Testing on Android Emulator
1. Set `ApiService.baseUrl` to `'http://10.0.2.2:8000'`. (Android Emulators route requests to `127.0.0.1` of the host machine through `10.0.2.2`).
2. Run the Flutter app targeting the emulator device.

### C. Testing on Real Android Device
1. Find your machine's local network IP (e.g., run `ipconfig` on Windows or `ifconfig` on macOS/Linux). Look for IPv4 Address like `192.168.1.100`.
2. Connect your Android device to the **same Wi-Fi network**.
3. Set `ApiService.baseUrl` to `'http://192.168.x.x:8000'` (replace with your actual local IP).
4. Run the Flutter app targeting the connected phone.

---

## 4. Tasks for Backend Teammate(s)

To make the customer flows fully live, the backend team must implement the following routes in `main.py`:

1. **`POST /api/auth/register`**
   - **Request**: `{ "name": "...", "email": "...", "phone": "...", "password": "..." }`
   - **Response**: `{ "status": "success", "token": "...", "user": { "id": "...", "name": "..." } }`

2. **`POST /api/auth/login`**
   - **Request**: `{ "email": "...", "password": "..." }`
   - **Response**: `{ "status": "success", "token": "...", "user": { "id": "...", "name": "..." } }`

3. **`POST /api/bids/offer`**
   - **Request**: `{ "req_id": "...", "user_id": "...", "offered_price": 1000.0, "session_token": "..." }`
   - **Response**: `{ "status": "success", "req_id": "...", "bids": [ { "provider_id": "...", "name": "...", "bid_price": 1000.0 } ] }`

4. **`POST /api/bids/accept`**
   - **Request**: `{ "req_id": "...", "user_id": "...", "provider_id": "...", "accepted_price": 1000.0, "session_token": "..." }`
   - **Response**: `{ "status": "success", "message": "...", "ctx": { "booking_id": "...", "slot": "..." } }`
