# Aarogya Setu

**Aarogya Setu** is an offline-first preventive healthcare platform designed for community health workers, doctors, and citizens. The application seamlessly bridges frontline ASHA workers, Primary Health Centre (PHC) medical officers, and rural households through structured household management, non-communicable and infectious disease screening, clinical triage escalation, interactive clinical assistance, and verifiable digital health identity.

---

## 🌟 Core Features & Modules

### 1. Role-Based Portals & Safe Session Flow
- **Frontline ASHA Worker Portal**:
  - **Citizen Directory**: Searchable list of registered citizens with risk badges and quick access to screening profiles.
  - **Household & Family Management**: Group citizens by family/household ID, add new family members, and manage head-of-household structures.
  - **Duplicate Prevention**: Automated duplicate detection by phone number and full name prevents multiple ASHA workers from registering the same citizen twice.
  - **ASHA Saathi (Clinical AI Assistant)**: Built-in clinical conversational assistant offering immediate triage advice, vital threshold interpretations, and guidance on referral protocols.
  - **Preventive Health Screenings**: Multi-point physiological vitals collection with real-time biological plausibility checks.
  - **Referral Tracker**: Real-time status tracking for patients escalated to PHCs.
- **Citizen / Family Portal**:
  - **Digital Health Card with QR Code**: Dynamic QR code encoding verified citizen profile data for fast PHC triage scanning.
  - **Single-Device Multi-Profile Switcher**: Family members sharing a single smartphone can switch profiles seamlessly while keeping health records completely isolated.
  - **Doctor Prescriptions & Consultations**: View clinical advice, diagnostic notes, and medication regimens issued by PHC doctors.
  - **Screening & Vitals History**: Comprehensive record of past health screenings.
  - **Role Permissions Guard**: New citizen registrations are strictly restricted to ASHA workers to preserve census integrity.
- **Doctor / Medical Officer Portal**:
  - **Priority-Ranked Triage Queue**: Incoming patient referrals categorized by severity (🔴 Emergency / High Urgency, 🟡 Urgent / Moderate, 🟢 Routine / Normal).
  - **Clinical Review Workspace**: Complete inspection of field vitals, reported symptoms, lifestyle risk factors, and ASHA notes.
  - **Diagnostic Notes & Treatment Recommendations**: Record official clinical notes and prescription advice.
  - **Synchronized Patient Directory**: Access full medical history for every citizen in the health district.
- **Safe Sign-Out Confirmation**:
  - Direct accidental logouts are disabled across all roles.
  - Clicking sign-out presents an explicit confirmation dialog ensuring offline records remain secure before terminating the session.

---

### 2. General Health Screening & Decision Support
- **Comprehensive Vitals Capture**: Systolic/Diastolic BP, Pulse Rate, Temperature, Blood Glucose, SpO2, and symptomatic observations.
- **Biological Plausibility Validation**: Detects and rejects physiologically impossible vitals (e.g. Diastolic BP > Systolic BP, abnormal pulse/temperature entries).
- **Rule-Based Triage Matrix**:
  - 🔴 **RED — Emergency / High Urgency**: Hypertensive emergencies, critical hypoxia (SpO2 < 90%), severe hyperglycemia (> 300 mg/dL), acute chest pain, antenatal complications. Recommended 24-hour escalation.
  - 🟡 **YELLOW — Moderate Urgency**: Stage 1/2 hypertension, persistent fever, prolonged cough, elevated glucose. Recommended 7-day PHC follow-up.
  - 🟢 **GREEN — Low Risk / Normal**: All vitals within normal parameters. Routine lifestyle counseling.
- **Statutory Decision Support Disclaimer**: Explicit guidance clarifying that triage results serve as advisory decision support and not a final medical diagnosis.

---

### 3. Automatic Background Synchronization & Offline Resilience
- **Offline-First Storage**: All records (citizens, screenings, households, and referrals) are saved instantly to persistent local storage on the device.
- **Automated Connectivity Sync**: The sync engine automatically detects network restoration (Wi-Fi or cellular) and pushes pending changes to Cloud Firestore in the background without requiring manual intervention.
- **Fallback Resilience**: The app remains 100% operational in low-connectivity or completely offline rural environments.

---

### 4. Public Health Awareness Hub (Open Access)
- **Accessible Without Login**: Freely available from the onboarding screen and within authenticated portals.
- **Preventive Health Topics**: Dengue prevention, hydration & summer safety, clean water hygiene, antenatal care & maternal nutrition, and chronic disease management.
- **Offline Video Engine**: Downloads educational MP4 video modules locally to device storage with verified atomic file writes for playback without active internet.

---

## 🔒 Security & Firestore Architecture

- **Role-Based Security Rules (`firestore.rules`)**:
  - Citizens, screenings, and referrals are protected by user role authentication.
  - Public health educational content (`/healthContent/{id}`) is publicly readable.
  - Deletions of audit logs and screening records are strictly disallowed.
- **Safe Credential Handling**: Zero sensitive credentials or hardcoded API keys are committed to the codebase.

---

## 🚀 Getting Started & Execution

### Prerequisites
- Flutter SDK 3.24+ (Dart 3.5+)
- Android device/emulator, Google Chrome, or Windows desktop

### 1. Run in Development
```bash
# Run on connected Android phone or emulator
flutter run

# Run on Google Chrome (Web)
flutter run -d chrome

# Run on Windows Desktop
flutter run -d windows
```

### 2. Run Automated Verification Tests
```bash
flutter test
```

### 3. Build Web Production Bundle
```bash
flutter build web --release
```

---

## 🌐 Firebase Web Hosting Deployment

The repository includes pre-configured [`firebase.json`](firebase.json) and [`.firebaserc`](.firebaserc) files configured for Firebase Hosting with Single Page App (SPA) URL rewrites.

1. **Build the Web Release**:
   ```bash
   flutter build web --release
   ```

2. **Authenticate with Firebase**:
   ```bash
   npx -y firebase-tools@latest login
   ```

3. **Deploy to Hosting**:
   ```bash
   npx -y firebase-tools@latest deploy --only hosting
   ```

Live deployment endpoints:
- **`https://aarogya-setu-sdg.web.app`**
- **`https://aarogya-setu-sdg.firebaseapp.com`**
