# Vet App Redesign Implementation Plan (Based on Sep 28 Mockup)

## Target
Redesign the Flutter Veterinarian Application (`Vet`) to match the new 3-screen high-fidelity UI design provided in `D:\Downloads\vet 28 sep.zip`, using only the provided assets (`vet_dashboard_banner.png`, `icon_todays_patients.png`, `icon_patients_waiting.png`, `national_emblem.png`), keeping the backend intact, ensuring responsiveness across all devices (mobile, tablet, desktop), and pushing the updated code to GitHub.

## Mockup Specifications
1. **Screen 1: Home / Dashboard**
   - Government of Maharashtra emblem + dual-language branding.
   - Header with notification bell (red dot) and doctor profile avatar.
   - Morning pastoral hero banner (`vet_dashboard_banner.png`) with "Good Morning, Dr. Bhatra".
   - 2-Column KPI Stat Cards:
     - Today's Patients (`12`, `↑ 2 from yesterday`, `icon_todays_patients.png`).
     - Patients Waiting (`3`, `High urgency`, `icon_patients_waiting.png`).
   - Recent Messages section with quick avatar previews (Nurse Sarah, Mark Admin).
   - Quick Actions:
     - Deep Teal Button: `View Queue (3) >`
     - White Cards: `Patient History >` & `Today's Schedule >`
   - Currently Waiting patient queue list with live wait timers and `Start` action.
   - 4-tab bottom navigation with active teal pill styling (`Home`, `Queue`, `Patients`, `Profile`).

2. **Screen 2: Waiting Queue**
   - Top bar: Maharashtra seal + `Waiting Queue` + `5 Waiting` amber pill badge.
   - Wait Time Trend (Last 2h) card with `-12% vs avg` indicator and 8-bar histogram.
   - Search input ("Search patients...") + Filter pills (`All`, `Kiosk`, `Patient App`).
   - Patient queue cards with source device indicators, countdown timer badge (red/amber circle), complaint tags, vitals (Temp, BP), and full-width `Accept Call` button.

3. **Screen 3: Telehealth Pro (Live Consultation)**
   - Top bar: Back button + Maharashtra seal + `Telehealth Pro`.
   - Large rounded video call viewport with patient video stream, doctor PIP, and floating call controls (mute, camera, end call).
   - Patient status row: Name ("Eleanor Vance"), `● Live Consultation` indicator, call timer ("12:45").
   - Patient Vitals card: Age, Gender, Blood Group, Weight/Height.
   - Medical History card: Condition pills (`Hypertension`, `Osteoarthritis`) + Allergy pill (`Penicillin`).
   - Consultation Notes card: Textarea, `Save Notes` action, `E-Prescribe` & `Schedule Follow-up` dual action buttons.
   - Recent Reports card: `Blood Panel`, `Chest X-Ray`, and `Upload Document` button.

## Task List
- [ ] Task 1: Update design tokens and brand colors in `Vet/lib/core/constants.dart` (Deep Teal `0xFF0B6057`, soft teal, gold, amber, badge colors).
- [ ] Task 2: Redesign `Vet/lib/screens/dashboard_view.dart` (Screen 1 - Hero banner, stats cards with assets, recent messages, quick actions, waiting queue preview).
- [ ] Task 3: Redesign `Vet/lib/screens/consultations_view.dart` (Screen 2 - Waiting Queue, 2h wait time trend histogram, filter pills, patient queue cards with vitals and Accept Call).
- [ ] Task 4: Redesign `Vet/lib/screens/consultation_screen.dart` (Screen 3 - Telehealth Pro, video viewport with PIP & floating controls, vitals, medical history, notes, reports).
- [ ] Task 5: Redesign `Vet/lib/screens/vet_shell.dart` (Active teal pill bottom navigation for Home, Queue, Patients, Profile + responsive navigation rail).
- [ ] Task 6: Align `Vet/lib/screens/cases_view.dart` styling for the Patients tab.
- [ ] Task 7: Run Dart static analysis to verify 0 errors across `Vet/lib/`.
- [ ] Task 8: Initialize git repo in `Vet/`, commit changes, and push to GitHub.
