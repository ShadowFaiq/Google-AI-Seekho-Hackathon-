# Implementation Plan: Anamta (AI & APIs)

**Role:** The AI Brains
**Tech Stack:** Python, Google Gemini (Antigravity)

## Overview
Your job is to build the "AI Service Orchestrator". You make the APIs and write the code that thinks, calculates, and makes decisions.

## Step-by-Step Execution

### 1. The Intent LLM (Language AI)
- Use Google Gemini to read the user's request (e.g., from a form or comment).
- It must be able to read **Urdu, Roman Urdu, and English**.
- Extract the specific service needed, the location, and urgency from their messy text.

### 2. The 6-Factor Matching Code (Mandatory)
- The judges require us to rank providers using more than just distance.
- Write Python code that pulls providers from Mishal's database and ranks them using 6 factors: Distance, Rating, Cancellation Rate, On-time Score, Price, and Service Keywords.
- Calculate the location distance between the Client and Provider as part of this ranking.

### 3. Dynamic Pricing & Disputes
- Write a simple pricing API that calculates: Base Rate + Distance Surcharge + Urgency.
- Write a simple dispute logic API that calculates a refund if the actual charge was higher than the original AI quote.

### 4. Build the APIs
- Turn your Python code into actual APIs (Request API, Read API, etc.) so that Anum's and Eman's apps can send data to your AI. Faiq will help you connect these.
