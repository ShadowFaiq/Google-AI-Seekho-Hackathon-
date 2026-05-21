# FikrFree Flutter API Integration Guide 📱

This document is the ultimate integration blueprint for the **Customer App (User-Side)** and **Provider App (Worker-Side)** Flutter developers. It specifies exactly which endpoints to use, their request/response schemas, and where to place them in the Flutter codebase.

---

## 👤 1. Customer App (User-Side) Flutter Team

The Customer App handles:
1. User registration and authentication.
2. Initiating service matching requests.
3. Placing and negotiating pricing bids (inDrive-style).

---

### API 1: Customer Register
* **Endpoint:** `POST /api/auth/register`
* **Content-Type:** `application/json`
* **Request Body:**
  ```json
  {
    "name": "Faiq Hassan",
    "email": "faiq@kaamconnect.pk",
    "phone": "03001234567",
    "password": "password123"
  }
  ```
* **Response Body (200 OK):**
  ```json
  {
    "status": "success",
    "token": "eyJhbGciOiJIUz...",
    "user": {
      "id": "usr_ca6524",
      "name": "Faiq Hassan",
      "email": "faiq@kaamconnect.pk"
    }
  }
  ```
* **📱 Where to place in Flutter:** Connect this to the **"Sign Up"** button on the Customer Registration screen.
* **⚡ Post-Action:** Store the returned `token` in `flutter_secure_storage` or `shared_preferences` as your global session token.

---

### API 2: Customer Login
* **Endpoint:** `POST /api/auth/login`
* **Content-Type:** `application/json`
* **Request Body:**
  ```json
  {
    "email": "faiq@kaamconnect.pk",
    "password": "password123"
  }
  ```
* **Response Body (200 OK):**
  *(Same format as Register response)*
* **📱 Where to place in Flutter:** Connect this to the **"Login"** button on the Customer Sign-In screen.
* **⚡ Post-Action:** Store the returned `token` in secure storage and navigate to the Home dashboard.

---

### API 3: Submit Service Request
* **Endpoint:** `POST /api/request`
* **Content-Type:** `application/json`
* **Request Body:**
  ```json
  {
    "user_id": "usr_ca6524",
    "text": "Mujhe kal subah AC technician chahiye G-13 mein"
  }
  ```
* **Response Body (200 OK):**
  ```json
  {
    "status": "success",
    "req_id": "req_f5ff10",
    "session_token": "eyJhbGciOiJIUz...",
    "ctx": {
      "bidding_status": "WAITING_FOR_USER_BID",
      "price_breakdown": {
        "suggested_price": 1000,
        "floor_price": 800,
        "ceiling_price": 1500
      }
    }
  }
  ```
* **📱 Where to place in Flutter:** Connect this to the **"Send Request" / "Match Me"** button on the Home / Service Description Screen.
* **⚡ Post-Action:** 
  1. Store the `req_id` and the unique `session_token` locally in state.
  2. Parse `floor_price` and `ceiling_price` and display them on the Bidding Screen (Slider or Input field) so the user cannot input a bid outside these limits.

---

### API 4: Place Bidding Offer
* **Endpoint:** `POST /api/bids/offer`
* **Content-Type:** `application/json`
* **Request Body:**
  ```json
  {
    "req_id": "req_f5ff10",
    "user_id": "usr_ca6524",
    "offered_price": 850.0,
    "session_token": "eyJhbGciOiJIUz..."
  }
  ```
* **Response Body (200 OK):**
  ```json
  {
    "status": "success",
    "req_id": "req_f5ff10",
    "message": "Offer broadcasted. Received counter-bids.",
    "bids": [
      {
        "provider_id": "prov_1",
        "name": "Ali Tech",
        "bid_price": 1000.0
      },
      {
        "provider_id": "prov_2",
        "name": "Babu Repairs",
        "bid_price": 900.0
      }
    ]
  }
  ```
* **📱 Where to place in Flutter:** Connect this to the **"Place Bid"** slider/input screen.
* **⚡ Post-Action:** Display the returned counter-bids from providers in a clean, real-time negotiation list.

---

### API 5: Accept Provider Bid
* **Endpoint:** `POST /api/bids/accept`
* **Content-Type:** `application/json`
* **Request Body:**
  ```json
  {
    "req_id": "req_f5ff10",
    "user_id": "usr_ca6524",
    "provider_id": "prov_2",
    "accepted_price": 900.0,
    "session_token": "eyJhbGciOiJIUz..."
  }
  ```
* **Response Body (200 OK):**
  ```json
  {
    "status": "success",
    "message": "Bid accepted and booking locked.",
    "ctx": {
      "booking_id": "KC-BK-32AAF",
      "slot": "12:00 PM"
    }
  }
  ```
* **📱 Where to place in Flutter:** Connect this to the **"Accept Offer"** button next to each provider in the bidding list.
* **⚡ Post-Action:** Navigate the user to the Booking Status / Live Tracking Screen, showing the confirmed `booking_id`.

---

## 🛠️ 2. Provider App (Worker-Side) Flutter Team

The Provider App handles:
1. Provider registration and authentication.
2. Managing work status (Online/Offline toggle).
3. Viewing dashboard statistics and AI demand forecasts.

> [!IMPORTANT]
> All operational requests (API 3, 4, and 5) **MUST** include the following header:
> `Authorization: Bearer <SAVED_JWT_TOKEN>` (Alternatively, for testing, you can use `Authorization: Bearer mock_token`).

---

### API 1: Provider Register
* **Endpoint:** `POST /api/provider/register`
* **Content-Type:** `application/json`
* **Request Body:**
  ```json
  {
    "name": "Ali Tech",
    "email": "ali@kaamconnect.pk",
    "password": "password123",
    "service_category": "ac_repair",
    "base_hourly_rate": 1000
  }
  ```
* **Response Body (200 OK):**
  *(Same token & provider details format as customer registration)*
* **📱 Where to place in Flutter:** Connect this to the **"Register"** button on the Provider onboarding screen.

---

### API 2: Provider Login
* **Endpoint:** `POST /api/provider/login`
* **Content-Type:** `application/json`
* **Request Body:**
  ```json
  {
    "email": "ali@kaamconnect.pk",
    "password": "password123"
  }
  ```
* **Response Body (200 OK):**
  *(Same format as Provider registration)*
* **📱 Where to place in Flutter:** Connect this to the **"Login"** button on the Provider Sign-in screen.

---

### API 3: Get Provider Dashboard
* **Endpoint:** `GET /provider/{provider_id}/dashboard`
* **Headers:** `Authorization: Bearer <TOKEN>`
* **Response Body (200 OK):**
  ```json
  {
    "provider_id": "prov_1",
    "name": "Ali Tech",
    "today_jobs": 3,
    "earnings_today_pkr": 4500,
    "next_available_slot": "04:00 PM"
  }
  ```
* **📱 Where to place in Flutter:** Call this inside the `initState` of the Provider's Main Dashboard Screen.

---

### API 4: Toggle Availability Status
* **Endpoint:** `POST /provider/{provider_id}/availability`
* **Query Parameters:** `available=true` or `available=false`
* **Headers:** `Authorization: Bearer <TOKEN>`
* **Response Body (200 OK):**
  ```json
  {
    "status": "success",
    "message": "Availability status updated to True"
  }
  ```
* **📱 Where to place in Flutter:** Connect this to the **"Go Online / Go Offline"** switch or slider in the Provider application header.

---

### API 5: Get AI Demand Forecast
* **Endpoint:** `GET /provider/{provider_id}/demand-forecast`
* **Headers:** `Authorization: Bearer <TOKEN>`
* **Response Body (200 OK):**
  ```json
  {
    "provider_id": "prov_1",
    "predictions": [
      {"hour": "02:00 PM", "demand_level": "medium"},
      {"hour": "03:00 PM", "demand_level": "high"},
      {"hour": "04:00 PM", "demand_level": "very_high"}
    ]
  }
  ```
* **📱 Where to place in Flutter:** Connect this to the **"Analytics / Demand Map"** screen in the Provider App.

---

## 💬 3. Real-Time Chat (WebSocket Room)

Once a matching provider is selected, both apps (Customer and Provider) can join a real-time messaging room using WebSockets.

* **WebSocket URL:** `ws://<SERVER_IP>:8000/ws/chat/{booking_id}/{user_id}`
* **Payload sent by Client (JSON):**
  ```json
  {
    "text": "Hello, when will you reach G-13?"
  }
  ```
* **Payload broadcasted by Server (JSON):**
  ```json
  {
    "message_id": "msg_f35a9c",
    "booking_id": "KC-BK-32AAF",
    "sender_id": "usr_789234",
    "text": "Hello, when will you reach G-13?",
    "timestamp": "2026-05-19T21:20:00Z"
  }
  ```
* **Fetch Chat History (REST API):**
  * **Endpoint:** `GET /api/chat/{booking_id}/history`
  * **Response Body (200 OK):**
    ```json
    {
      "status": "success",
      "messages": [
        {
          "message_id": "msg_f35a9c",
          "booking_id": "KC-BK-32AAF",
          "sender_id": "usr_789234",
          "text": "Hello, when will you reach G-13?",
          "timestamp": "2026-05-19T21:20:00Z"
        }
      ]
    }
    ```
* **📱 Where to place in Flutter:** 
  - Connect the WebSocket when entering the **In-App Chat Screen** using the `web_socket_channel` package.
  - Call the chat history API to load previous messages before connecting the WebSocket.

---

## 🔔 4. Real-Time Push Notifications (Firebase Cloud Messaging)

Both Customer and Provider apps must register their device tokens with the backend so they can receive real-time push alerts.

* **Register Device Token:**
  * **Endpoint:** `POST /api/notification/register-device-token`
  * **Request Body:**
    ```json
    {
      "user_id": "usr_789234",
      "device_token": "FCM_DEVICE_REGISTRATION_TOKEN_HERE"
    }
    ```
  * **Response Body (200 OK):**
    ```json
    {
      "status": "success",
      "message": "Registered device token for usr_789234"
    }
    ```

* **When do Push Notifications trigger?**
  1. **New Job Alert:** When a customer accepts a bid, the selected provider receives a push alert instantly ("*New Job Assigned! 🛠️*").
  2. **Booking Confirmed:** When booking is locked, the customer receives an alert ("*Booking Confirmed! 🎉*").
  3. **Milestone Alerts:** The orchestrator dispatches updates during lifecycle steps.

* **📱 Where to place in Flutter:** 
  - Fetch the FCM device token via the `firebase_messaging` package on app startup, and upload it using `register-device-token`.

