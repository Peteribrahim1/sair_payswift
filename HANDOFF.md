# Project Handoff: PaySwift Fintech App

## Current State — All Core Features Complete ✅

| Feature | Status |
|---|---|
| Backend (Auth, Profile, Transactions, Notifications) | ✅ Complete |
| Flutter Auth (Login + Register → Dashboard) | ✅ Complete |
| Wallet Balance (live, updates after transaction) | ✅ Complete |
| Buy Airtime / Data / Convert / Pay Bills | ✅ Complete (Polished) |
| **VTPass Real API (Airtime, Data, Electricity, Cable TV)** | ✅ **Complete** |
| Onboarding Flow (3 slides, persistent) | ✅ Complete |
| Spending Analytics (Pie + Bar charts) | ✅ Complete |
| Transaction Details (Digital Receipt) | ✅ Complete |
| Bank Accounts Management (view, add, remove) | ✅ Complete |
| Transaction History | ✅ Complete |
| Notifications (create on transact, fetch, mark read) | ✅ Complete |
| Notification badge on Home bell icon | ✅ Complete |
| Profile Screen (view, initials avatar, balance chip) | ✅ Complete |
| Profile Edit (full name + phone → backend) | ✅ Complete |
| Logout | ✅ Complete |
| Dark Mode toggle | ✅ Complete |
| News Screen (polished, deep links, relative timestamps) | ✅ Complete |

## Where We Stopped
1. **Spending Analytics**: Added a new "Analytics" service on the Home screen. It provides interactive Pie and Bar charts to visualize spending by category and weekly trends.
2. **Transaction Details (Digital Receipt)**: Transactions in history open a detailed digital receipt.
3. **Bank Accounts Management**: Added a screen to manage linked bank accounts.
4. **Service Screens Polished**: `PayBillsScreen` and `BuyDataScreen` are fully functional.

## 🗂️ Backlog — Planned Features (Not Yet Started)

These features are intentionally deferred and will be implemented in a future session.
They are fully scoped out below so work can resume cleanly.

---

### 1. 🔔 Push Notifications (Firebase Cloud Messaging)
**Priority**: Medium  
**Goal**: Deliver real-time push alerts to the user's device when a transaction occurs, even when the app is in the background.

**Implementation Notes**:
- Integrate `firebase_messaging` Flutter package
- Set up a Firebase project and link it to the app (GoogleService-Info.plist / google-services.json)
- Backend: send FCM push from the Node.js server after every transaction (use `firebase-admin` SDK)
- Handle foreground, background, and terminated app states
- Store FCM device token per user in the database (add `fcmToken` field to User model in `schema.prisma`)

**Files likely to touch**:
- `backend/prisma/schema.prisma` — add `fcmToken` field
- `backend/src/controllers/` — trigger FCM after transaction
- `lib/main.dart` — initialize Firebase, request permission
- `lib/providers/` — store & sync token

---

### 2. 🔐 Biometric Lock (Fingerprint / Face ID)
**Priority**: Medium  
**Goal**: Protect the app with fingerprint or Face ID on launch or when returning from background.

**Implementation Notes**:
- Use `local_auth` Flutter package
- Show biometric prompt on app resume (use `AppLifecycleState` listener)
- Fall back to PIN/password if biometrics unavailable
- Store biometric preference in `SharedPreferences` (toggle in Profile settings)
- Add a toggle in the Profile/Settings screen: "Enable Biometric Lock"

**Files likely to touch**:
- `lib/main.dart` — lifecycle listener
- `lib/screens/profile/profile_screen.dart` — biometric toggle
- New file: `lib/services/biometric_service.dart`

---

### 3. 🏦 Withdraw Funds
**Priority**: High  
**Goal**: Allow users to withdraw money from their wallet to a linked bank account.

**Implementation Notes**:
- UI: A "Withdraw" button on the Home/Dashboard screen (similar to "Transfer")
- Flow: Select linked bank account → Enter amount → Confirm → Show receipt
- Backend: New `POST /transactions/withdraw` endpoint
  - Validate sufficient wallet balance
  - Deduct from wallet, log transaction with type `WITHDRAWAL`
  - Trigger a notification
- Frontend: Re-use the existing `BankAccountsProvider` to list linked accounts
- Validate: minimum withdrawal amount, PIN confirmation before executing

**Files likely to touch**:
- `backend/src/controllers/transactions.controller.ts` — new withdraw endpoint
- `backend/src/routes/transactions.routes.ts` — register route
- `lib/screens/services/` — new `withdraw_screen.dart`
- `lib/providers/wallet_provider.dart` — refresh balance after withdrawal
- `lib/screens/home/home_screen.dart` — add Withdraw entry point

---

## Useful Commands to Resume
**Start the Backend server first:**
```bash
cd /Users/macbook/StudioProjects/sair/backend
npx ts-node src/index.ts
```

**Start the Flutter Emulator App:**
```bash
flutter emulators --launch Pixel_4_API_29
flutter run
```
