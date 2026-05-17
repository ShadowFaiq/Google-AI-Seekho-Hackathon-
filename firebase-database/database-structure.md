# Firebase Database Structure

This project uses Firebase Cloud Firestore to manage the database for a service-provider platform. The database stores client profiles, provider profiles, service requests, bookings, and AI agent logs.

## Collections Overview

The Firestore database contains the following collections:

- `client`
- `provider`
- `service_requests`
- `bookings`
- `agent_logs`

---

## 1. client

The `client` collection stores information about users who request services.

### Purpose

Clients use the app to request daily-life home services such as plumbing, electrical work, cleaning, appliance repair, and other household tasks.

### Possible Fields

| Field Name | Type | Description |
|---|---|---|
| client_id | string | Unique ID of the client |
| name | string | Full name of the client |
| email | string | Client email address |
| phone | string | Client phone number |
| location | string | Client city or area |
| address | string | Complete service address |
| created_at | timestamp/string | Date and time when the client profile was created |

### Example

```json
{
  "client_id": "client_001",
  "name": "Sample Client",
  "email": "client@example.com",
  "phone": "03000000000",
  "location": "Lahore",
  "address": "Sample Address, Lahore",
  "created_at": "2026-05-17"
}
