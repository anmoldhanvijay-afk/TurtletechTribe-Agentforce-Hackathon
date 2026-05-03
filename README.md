# TurtletechTribe-Agentforce-Hackathon
Agentforce Hackathon 2026 Team TurtleTech Tribe. A multilingual self-serve banking agent built on Salesforce Financial Services Cloud for Self-Serve Robotic Customer Service Agent.Powered by Agentforce, WhatsApp, and Data Cloud — enabling Hindi-English banking, instant dispute filing, and self-serve loan restructuring without branch visits.

## Problem Statement

Rajesh Sharma is a small business owner in Indore. Despite a long-term relationship 
with his bank (Home Loan, Credit Card, and Mutual Funds), he faces:

- High-friction IVR menus and 7-step MPIN resets just to check a balance
- English-only interfaces despite thinking and communicating in Hindi
- Mandatory physical branch visits for loan restructuring
- 10+ day wait times for credit card dispute resolution with zero visibility
- Scanning paper receipts into PDFs for dispute filing

**Rajesh is a high-churn risk. Our solution turns him into a brand advocate.**

---

##  Solution Overview

A WhatsApp-first, multilingual (Hindi/Hinglish/English) Agentforce banking agent 
built on Salesforce Financial Services Cloud. Rajesh can self-serve his entire 
banking journey — balance checks, dispute filing, and loan restructuring — without 
calling a helpline or visiting a branch.

---

##  Architecture
##  Architecture
Rajesh (WhatsApp)
│
▼
Twilio Sandbox (WhatsApp Channel)
│
▼
Salesforce Messaging Channel
│
▼
Agentforce (Atlas Reasoning Engine)
│
├── Scenario 1: Balance / Mini-Statement
│       └── Apex Action → FSC Financial Accounts → Hindi reply
│
├── Scenario 2: Credit Card Dispute
│       └── Einstein Document AI (OCR) → Case creation → Provisional credit
│
└── Scenario 3: Loan Restructuring
└── EMI Simulator Flow → OTP confirmation → RM callback
---

##  Key Features Built

### Scenario 1 — High-Speed Multilingual Banking
- Rajesh sends "बैलेंस" or "Mera balance kya hai?" via WhatsApp
- Agent authenticates via OTP and replies instantly in Hindi
- Mini-statement (last 5 transactions) on demand — no app login needed
- Full Hindi/Hinglish/English understanding without forcing English input

### Scenario 2 — Frictionless Credit Card Dispute
- One-message filing: "I didn't make this ₹12,500 charge at Goa"
- Agent identifies the transaction and opens a structured case record
- Einstein Document AI extracts dates and amounts from a photo of the bill
- Provisional credit issued immediately — Rajesh pays no interest during investigation
- Real-time status tracking: "dispute status" returns exact case stage

### Scenario 3 — Self-Serve Loan Restructuring
- In-chat EMI simulator: three options (extend by 1yr, 2yr, or 3-month moratorium)
- Side-by-side impact on EMI and total interest shown before confirmation
- Zero paperwork — existing income and ID proofs on file are reused
- OTP-based confirmation — no branch visit needed
- Proactive RM callback scheduled with full context briefing

---

##  Tech Stack

| Layer | Technology |
|---|---|
| Agent | Agentforce (Agent Builder) |
| Reasoning | Atlas Reasoning Engine |
| CRM | Salesforce Financial Services Cloud |
| Document Processing | Einstein Document AI / OCR |
| Messaging Channel | WhatsApp via Twilio Sandbox |
| Custom Actions | Apex Classes |
| Automation | Salesforce Flows |
| Frontend (if any) | Lightning Web Components (LWC) |

---

## Salesforce Features Used

- Agentforce (Agent Builder, Agent Topics, Agent Actions)
- Atlas Reasoning Engine
-  Financial Services Cloud (FSC)
-  Einstein Document AI / OCR
-  Apex Classes (custom actions)
-  Flows (automation and action logic)
-  WhatsApp Messaging Channel
-  Connected Apps (Twilio integration)
-  OTP Authentication

---

##  Setup & Testing Instructions for Judges

### Step 1 — Access the Org
Use the admin credentials provided in the submission form to log into the 
Salesforce trial org. No additional configuration is needed.

### Step 2 — Join the Twilio WhatsApp Sandbox
To test the WhatsApp channel, send the following message from your WhatsApp:
Send: join <paragraph-late>
To:   +14155238886

You will receive a confirmation message once you have joined the sandbox.

### Step 3 — Test the Agent
Once in the sandbox, send any of the following prompts to test each scenario:

**Scenario 1 — Balance Check:**
Mera balance kya hai?
बैलेंस
Show me my last 5 transactions
**Scenario 2 — Dispute Filing:**
I didn't make this ₹12,500 charge at Goa
What is my dispute status?
**Scenario 3 — Loan Restructuring:**
Mujhe apni EMI kam karni hai
### Step 4 — Navigate the Org Directly
Key pages to review in the org:

- **Agent Builder**: Setup → Agentforce Agents → New Bank Sathi Service Agent
- **FSC Financial Accounts**: App Launcher → Financial Services Cloud
- **Cases**: App Launcher → Cases (to see dispute records created)
- **Flows**: Setup → Flows (to review automation logic)
- **Apex Classes**: Setup → Apex Classes (to review custom actions)

---

##  External Dependencies

### Twilio WhatsApp Sandbox
- **Provider**: Twilio
- **Purpose**: WhatsApp messaging channel for customer interaction
- **Sandbox Number**: +14155238886
- **Credentials stored as**: Custom Metadat in Salesforce org
- **Note**: Judges must join the sandbox (Step 2 above) before testing

---

##  Future Improvements

Given more time, we would:

1. **Move from Twilio Sandbox to a production WhatsApp Business API** — for real 
   customer deployment without sandbox join requirements
2. **Add proactive notifications** — EMI due date reminders, dispute resolution 
   updates pushed to Rajesh without him needing to ask
3. **Expand language support** — Marathi, Gujarati, Tamil for deeper regional reach
4. **Voice channel integration** — same agent accessible via voice call for 
   customers less comfortable with text
5. **Deeper Data Cloud segmentation** — identify other high-churn customers like 
   Rajesh and proactively reach out before they consider leaving
6. **Biometric authentication** — replace OTP with WhatsApp-native fingerprint/
   face ID for even lower friction

---

##  Team TurtleTech Tribe

| Name | Role |
|---|---|
| Kanishk Gupta |Team Lead |
| Anmol Dhanvijay | Salesforce Developer |
| Harkirat Singh |Salesforce Developer |
| Kalyan Vajjiparthi | Salesforce Developer |


---

##  Contact

For any questions during judging, reach us at: kanishk.gupta@turtletechtribe.com(Mob- 8527650722)

---

*Submitted for Agentforce World Tour Mumbai Hackathon 2026*
*Hackathon Portal: https://awt-mumbai-hackathon-2026-c94c8fd906ff.herokuapp.com/*
