# FikrFree Firebase Database Schema & Setup Guide 🗄️

This document is the official schema reference for the **Database/Backend Team** to set up, secure, and seed your production Firebase Firestore database.

---

## 🔑 1. Firebase Firestore Setup Instructions

To hook the FastAPI backend to your live Firebase instance:
1. Go to the **Firebase Console** -> **Project Settings** -> **Service Accounts**.
2. Click **Generate New Private Key**.
3. Download the JSON file, rename it to `serviceAccountKey.json`, and place it in the root folder of the backend project repository.
4. Run the seed script:
   ```bash
   python init_db.py
   ```
   *(This will automatically recreate the collections below and populate them with standard user/provider profiles, including their hashed passwords).*

---

## 📂 2. Database Schema (Firestore Collections)

### 1. `users` Collection
Stores customer profiles and credentials.
* **Document ID:** `user_id` (e.g. `usr_789234`)
* **Document Fields:**
  ```typescript
  {
    id: string;               // e.g. "usr_789234"
    name: string;             // e.g. "Faiq Hassan"
    email: string;            // e.g. "faiq@kaamconnect.pk"
    phone: string;            // e.g. "03001234567"
    hashed_password: string;  // Bcrypt hashed password string
    role: "customer";
    location: {
      lat: number;            // e.g. 31.4697
      lng: number;            // e.g. 74.4012
    };
    saved_addresses?: {
      home?: { lat: number; lng: number };
      work?: { lat: number; lng: number };
    }
  }
  ```

---

### 2. `providers` Collection
Stores service provider profiles, metrics, locations, and rankings.
* **Document ID:** `provider_id` (e.g. `prv_ac_1`)
* **Document Fields:**
  ```typescript
  {
    id: string;                 // e.g. "prv_ac_1"
    name: string;               // e.g. "Ali AC Master"
    email: string;              // e.g. "ali@kaamconnect.pk"
    hashed_password: string;    // Bcrypt hashed password string
    role: "provider";
    service_category: string;   // e.g. "ac_repair"
    specialty: string;          // e.g. "split ac" (used for skill ranking)
    is_active: boolean;         // True means online and ready
    strikes: number;            // Default: 0 (providers with 2+ strikes are suspended)
    location: {
      lat: number;              // e.g. 31.4750
      lng: number;              // e.g. 74.4050
    };
    rating: number;             // e.g. 4.9 (out of 5)
    cancellation_rate: number;  // e.g. 5 (means 5% cancellations)
    on_time_score: number;      // e.g. 98 (means 98% punctuality)
    base_hourly_rate: number;   // e.g. 1200 (in PKR)
    last_review_days_ago: number; // Stale reviews factor
  }
  ```

---

### 3. `bookings` Collection
Stores finalized, locked matches and billing parameters.
* **Document ID:** `booking_id` (e.g. `KC-BK-32AAF`)
* **Document Fields:**
  ```typescript
  {
    booking_id: string;         // e.g. "KC-BK-32AAF"
    request_id: string;         // e.g. "req_f5ff10"
    user_id: string;            // e.g. "usr_789234"
    selected_provider: string;  // e.g. "prv_ac_1"
    provider_name: string;      // e.g. "Ali AC Master"
    agreed_price: number;       // e.g. 900
    status: "Pending" | "En-route" | "Arrived" | "Completed";
    timestamp: string;          // ISO Date string
  }
  ```

---

### 4. `service_requests` Collection
Stores the raw user request and extracted intent.
* **Document ID:** `request_id` (e.g. `req_f5ff10`)
* **Document Fields:**
  ```typescript
  {
    request_id: string;
    user_id: string;
    user_request: string;      // e.g. "Mujhe kal subah AC technician chahiye G-13 mein"
    parsed_data: object;       // JSON extracted by Gemini Intent Agent
    status: "pending" | "matched";
    timestamp: string;
  }
  ```

---

### 5. `agent_logs` Collection
Traces and audits the autonomous agent steps (debugging and UI visualization helper).
* **Document ID:** `log_id` (e.g. `log_abc123`)
* **Document Fields:**
  ```typescript
  {
    log_id: string;
    request_id: string;
    agent: string;             // e.g. "RankingAgent"
    action: string;            // e.g. "Ranked using 10-factor matrix"
    reasoning: string;
    timestamp: string;
  }
  ```

---

## 🔒 3. Firestore Security Rules

Since the FastAPI backend accesses Firestore via the **Firebase Admin SDK**, it bypasses Security Rules completely. However, if your Flutter apps read from Firestore directly (e.g. for real-time order updates), add these rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Customers can read/write their own user profile
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Providers can read profiles, but only the backend can modify rankings/strikes
    match /providers/{providerId} {
      allow read: if request.auth != null;
      allow write: if false; // Block client writes (only Admin SDK writes)
    }

    // Customers and matching Providers can view their active bookings
    match /bookings/{bookingId} {
      allow read: if request.auth != null && 
        (resource.data.user_id == request.auth.uid || resource.data.selected_provider == request.auth.uid);
      allow write: if false; // All booking modifications must flow through the backend API
    }
  }
}
```
