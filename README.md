# AarogyaSetu AI (ग्रामीण स्वास्थ्य सेतु)

**AarogyaSetu AI** is an offline-first, voice-friendly preventive healthcare platform designed specifically for rural and underserved communities. The application connects ASHA workers, primary health centre doctors, and villagers through structured health registration, general preventive screening, referral escalation, and localized health education.

---

## 🌟 Core Features Implemented ("Build Now")

### 1. Three-Role Authentication & Session Persistence
- **ASHA Worker Portal**: Registration of villagers, preventive screenings, referral management, and pending follow-ups.
- **Doctor Portal**: Incoming triage queues (Red / Yellow), full clinical inspection of vital signs & symptoms, doctor clinical consultation notes, and status updates.
- **Patient / Villager Portal**: Citizen health card with medical history, past screening results, doctor prescriptions, and direct access to educational content.
- **1-Click Development/Demo Fast Login**: Instant testing for all three roles without typing credentials:
  - *ASHA Worker*: Shanti Devi (`asha.shanti@aarogyasetu.gov.in`)
  - *Medical Officer / Doctor*: Dr. Rajesh Sharma, MD (`dr.rajesh@aarogyasetu.gov.in`)
  - *Villager / Patient*: Ramesh Kumar (`ramesh.kumar@aarogyasetu.gov.in`)
- **Session Persistence**: Login state is saved across application restarts.

### 2. General Health Screening & Decision Support Engine
- **Non-Disease-Centric Screening**: Captures comprehensive vitals (Systolic BP, Diastolic BP, Pulse Rate, Temperature, Blood Glucose, SpO2), warning symptoms checklist, and lifestyle observations.
- **Biological Plausibility Validation**: Detects and rejects physiologically impossible values (e.g. Diastolic BP higher than Systolic BP, extreme pulse or temperatures).
- **Rule-Based Triage Classification**:
  - 🔴 **RED — High Urgency**: Hypertensive crisis, critical hypoxia (SpO2 < 90%), severe hyperglycemia (> 300 mg/dL), severe breathlessness, chest pain, antenatal emergencies. Immediate 24-hour PHC/hospital escalation recommendation.
  - 🟡 **YELLOW — Moderate Urgency**: Stage 1/2 HTN, fever > 3 days, cough > 2 weeks, dysuria, elevated sugar. Referral within 7 days.
  - 🟢 **GREEN — Low Risk / Normal**: All vitals and observations within normal limits. Routine lifestyle counseling.
- **Statutory Decision Support Disclaimer**: Prominently presented to reinforce that triage output is advisory decision support and not a final medical diagnosis.
- **One-Tap Escalation**: Automatically prompts referral creation when Red or Yellow flags are detected.

### 3. Doctor Portal & Synchronized Referral History
- **Referral Triage Queue**: Filterable by urgency (Red / Yellow), review status (Pending / Consulted), or village.
- **Clinical Review Workspace**: Doctors can review field vitals, reported symptoms, and ASHA field notes.
- **Doctor Clinical Notes & Recommendations**: Doctors record diagnosis and prescription notes.
- **Audit Trail & Timestamps**: Complete chronological log of status changes (`pending` -> `under_review` -> `consulted` -> `escalated_to_facility` -> `closed`) with doctor names and timestamps.
- **Two-Way Synchronization**: Doctor updates immediately reflect on the originating ASHA worker's portal and the villager's health card.

### 4. Public Health Awareness Hub (Open Access)
- **Accessible Without Login**: Anyone can access from the login screen, as well as from authenticated user portals.
- **Curated Topics**: Dengue prevention, Summer safety & hydration, Safe drinking water & hygiene, Maternal nutrition & antenatal care, Chronic disease control.
- **Metadata**: Title, Topic, Language, Source (e.g., MoHFW, NCVBDC, WHO), Review Date, Version.
- **Verified Guidance Distinction**: Distinguishes verified health guidance from sample demonstration content.

### 5. Automatic Offline Video Playback
- **Local File Persistence**: Downloads actual MP4 video files into device documents storage (`path_provider`).
- **Download State Machine**:
  - `Available Offline (Downloaded)`
  - `Downloading (0% - 100%)`
  - `Waiting for Internet`
  - `Update Available`
  - `Online Only`
- **Interruption Recovery**: Incomplete downloads write to `.part` files; verified atomically upon completion to avoid corrupt playable files. Existing versions remain playable until replacement is verified.
- **Guaranteed Offline Demonstration**: Bundled fallback asset (`assets/videos/sample_health_video.mp4`) ensures immediate offline video playback even if internet was never connected.

### 6. Offline-First Repository & Sync Engine
- **Local-First Saving**: New patients, screenings, and referrals are saved immediately on the device with `SyncStatus.locallySaved`.
- **Sync Badges**: `[Saved Locally]`, `[Pending Sync]`, `[Cloud Synced]`.
- **Automatic Connectivity Sync**: Listens to network state transitions and automatically uploads pending records when Wi-Fi or mobile data reconnects. Includes a manual **Sync Now** trigger.

---

## 🏗 Future-Ready Architecture (Models & Extension Points)

Data models and service contracts are ready now to support future roadmap modules without database refactoring:

1. **Care-Gap Radar & Village Map (`lib/core/models/future_models/village_model.dart`)**:
   - `villageId`, `subDistrict`, `district`, `clusterZone`, `latitude`, `longitude`, `totalScreenedCount`, `highRiskClusterCount`, `careGapIndex`.
   - Allows future geographic aggregation and heatmaps without exposing patient identities.
2. **Hospital Registration & Administration (`lib/core/models/future_models/facility_model.dart`)**:
   - `facilityId`, `type` (PHC, CHC, District Hospital), `verifiedDoctorIds`, `assignedAshaWorkerIds`, `totalBedCapacity`, `hasEmergencyICU`.
3. **Follow-Up & Missed-Care Recovery (`lib/core/models/future_models/follow_up_model.dart`)**:
   - `followUpId`, `referralId`, `patientId`, `scheduledDate`, `isCompleted`, `isMissedCare`, `daysOverdue`, `automatedReminderTimestamps`.
4. **Awareness Content Governance (`lib/core/models/future_models/content_governance_model.dart`)**:
   - `contentId`, `approvalStatus` (draft, underMedicalReview, approved, published), `reviewerMedicalOfficerId`, `targetVillageIds`.

---

## 🔒 Security & Firestore Rules

Production-grade rules in `firestore.rules`:
- Role-based authorization enforced via custom claims or user profile lookup.
- Patients, screenings, and referrals are restricted to authorized healthcare workers and owning users.
- Public Health Awareness Content (`/healthContent/{id}`) is publicly readable without authentication.
- Deletions of medical audit records and screenings are strictly prohibited.

---

## 🚀 How to Run the Application

### Prerequisites
- Flutter SDK 3.24+ (Dart 3.5+)
- Google Chrome, Windows, or connected Android emulator/device

### 1. Run in Development
```bash
# Run on Chrome
flutter run -d chrome

# Run on Windows Desktop
flutter run -d windows
```

### 2. Run the Verification Tests
```bash
flutter test
```

### 3. Build Web Production Bundle
```bash
flutter build web --release
```

### 4. Firebase Setup (Optional for Cloud Live Sync)
By default, the app runs in **Offline-First Resilience Mode** with persistent local storage and demo accounts.
To connect to your own Firebase project:
1. Install FlutterFire CLI: `dart pub global activate flutterfire_cli`
2. Run configuration: `flutterfire configure`
3. Deploy Firestore rules: `firebase deploy --only firestore:rules`
