# Implementation Plan: Eman (Provider App UI/UX)

**Role:** Provider Frontend & Failure Trigger
**Tech Stack:** Flutter (Android)

## Overview
Your goal is to build the technician's side of the app. Your most critical task is to build a "Cancel Job" button so we can demonstrate our AI's auto-reschedule and dispute handling to the judges.

## Step-by-Step Execution

### 1. App Navigation & Signup
- **First Page:** When the user selects "Provider" on the start screen, route them to your flow.
- **Provider Signup:** Create a large form capturing:
  - Valid Email & Phone Number.
  - CNIC Number and an upload button for a CNIC scan.
  - Services provided, License, Education, Experience, and Shop Location.
- **Temporary Save:** Just like Anum, save this data into a temporary JSON format before it gets pushed to Mishal's Firebase.

### 2. Provider Dashboard
- **Profile Screen:** Display the provider's details and their average 5-star rating (which comes from Anum's client side).
- **Active Jobs:** Build a screen that shows jobs assigned to this provider.

### 3. The Stress-Test Trigger (Crucial for Demo)
*The judges want to see what happens when things go wrong.*
- **"Simulate Emergency Cancel" Button:** On an active job card, place a highly visible red button.
- **Trigger Logic:** When the provider clicks this, it updates the job status to `cancelled`. This will trigger Faiq and Anamta's AI on the backend to automatically find a new provider. You don't need to write the AI, just ensure the button updates the status!
