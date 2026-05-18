# Implementation Plan: Anum (User App UI/UX)

**Role:** Client Frontend & Trace Visualizer
**Tech Stack:** Flutter (Android)

## Overview
Your goal is to build the Android customer journey. Keep the UI simple, but you *must* include the Agent Trace Visualizer—this is what will win us the hackathon.

## Step-by-Step Execution

### 1. App Navigation & Signup
- **First Page:** Build a screen with two options: "Client" or "Provider". If they click Client, go to your flow.
- **Client Signup:** Create a form capturing Name, Gender, Age, Phone Number, and a button to capture current GPS location.
- **Dashboard:** Build a main screen with tabs: Home, Profile, Requests, and General.

### 2. The Request Form
- In the **Requests** tab, build a form asking:
  - Service Type needed
  - Location
  - Timings
  - Price Range
- **Temporary Save:** When "Submit" is clicked, temporarily save this data into a JSON structure before sending it to the backend.

### 3. The "Wow" Factor — Live Trace Visualizer (Mandatory)
*The judges require us to show the AI "thinking".*
- **Connect to Faiq's Backend:** Faiq will give you a WebSocket API link (`/ws/trace`). 
- **Display the Thinking:** Instead of a simple loading screen, you must display the live text coming from the API (e.g., "Confidence 91% -> Scanning DHA -> Selected Provider A").

### 4. Ratings & Receipt
- After the service is complete, provide a 5-star rating screen for the client to rate the provider.
- Display a final receipt showing the Dynamic Price breakdown (Base Rate + Distance Surcharge).
