# ESMS Production Readiness Audit

## 1. Architecture Overview

ESMS is a Flutter application using Firebase Authentication and Cloud Firestore. Feature code generally follows a screen -> Riverpod provider -> repository -> service -> Firestore structure. Shared models and widgets live under `lib/shared`, while cross-cutting constants and services live under `lib/core`.

Firestore writes that affect multiple documents use transactions in billing, inventory adjustment, expense changes, and purchase-order receiving.

## 2. Implemented Modules

- Authentication and splash/setup flow
- Dashboard
- Master Data
- Products
- Inventory and stock history
- Suppliers data layer
- Purchase Orders
- Billing POS and history
- Expenses
- Reports
- Staff and Roles
- Settings

## 3. Firestore Collections

The application references `users`, `shops`, `products`, `brands`, `categories`, `locations`, `suppliers`, `purchase_orders`, `bills`, `expenses`, `returns`, `activity_logs`, `counters`, and `settings`.

## 4. Authentication Model

Firebase Auth authenticates the user. The application loads the matching profile from `users/{uid}` into the existing `UserModel`. Passwords are never stored in Firestore. Password reset uses Firebase Auth's reset-email API.

Secure staff Auth account creation is not implemented in the Flutter client. It requires a trusted Cloud Function or backend using Firebase Admin SDK, followed by creation of the Firestore profile.

## 5. Role and Permission Model

`UserRole` currently supports `owner`, `staff`, and `electrician`. The centralized Staff authorization layer maps roles to permissions and blocks inactive users. Owner protection prevents owner profiles from being deleted, deactivated, or demoted through the staff workflow.

## 6. Security-Rule Status

`firestore.rules` was added and registered in `firebase.json`. Rules deny unauthenticated access, require an active user profile, restrict management operations by the existing roles, protect owner profiles, make activity logs append-only, and restrict master-data writes to owners.

The current schema has no `shopId` on users or business documents. The rules therefore cannot enforce per-shop tenant isolation. The application is protected as a single-shop deployment using `shops/default`; adding multi-shop support requires a `shopId` relationship on users and every shop-owned document, or a trusted custom-claims design.

Rules must be deployed to the Firebase project before release. The client-side authorization checks remain useful for UX but are not a replacement for deployed rules.

## 7. Known Limitations and Audit Findings

- The repository has no existing activity-log abstraction for general settings/staff events. Existing logs are inventory-shaped, so no duplicate logging system was introduced.
- Supplier list, add/edit form, details, filtering, lifecycle activation, routes, and purchase-order provider integration are implemented.
- Login now uses validated Firebase Auth credentials with friendly error handling, password reset, and protected navigation. Setup validates and persists the existing `shops/default` schema but still requires a trusted backend-provisioned owner.
- The application does not currently expose a theme preference manager; no second theme system was introduced.
- Firebase App Check is not configured. Enable it as deployment hardening.
- Reports profit uses current product purchase prices because bills do not store historical cost snapshots. It is an estimate, not exact historical profit.
- Rules cannot enforce multi-shop isolation because current documents do not include shop ownership metadata. Electrician billing is limited to bill creation, bill-counter increments, and stock-only product updates.

## 8. Report and Profit Limitation

The Reports repository calculates revenue from bills, expenses from expenses, inventory valuation from current products, and cost of goods sold from current product purchase prices. Historical product cost at sale time is not present in the bill schema, so reported profit can change when product purchase prices change.

## 9. Firebase Backend Requirements

Before release:

- Deploy `firestore.rules` to any future Firebase environment; it has been deployed successfully to `esms-6b9d0` during this verification.
- Configure a trusted Cloud Function/backend for staff Firebase Auth account provisioning.
- Establish the initial owner securely; the client must not bootstrap arbitrary Auth accounts.
- Configure Firebase App Check.
- Confirm production indexes for ordered/filtered Firestore queries.
- Configure monitoring, backups, and an appropriate Firebase project environment.

## 10. Testing Status

Focused tests cover billing calculations, inventory and purchase-order business rules, reports, staff roles/permissions/owner protection/filtering, settings validation/serialization, and related model behavior. The complete test suite was run during this audit.

## 11. Build Status

- `flutter analyze`: passed with no issues.
- `flutter test`: passed, 85 tests, 0 failures.
- `flutter build apk --debug`: passed. APK generated at `build/app/outputs/flutter-apk/app-debug.apk`.

## 12. Remaining Deployment Tasks

- Provision and verify the initial owner through a trusted backend before first-run setup.
- Test Firestore rules in an emulator for each role and critical write path.
- Provision staff Auth accounts through a trusted backend.
- Decide whether the deployment remains single-shop or add explicit tenant ownership fields before multi-shop use.
- Enable App Check and production observability.

The application is not declared fully production-ready until the backend requirements above are completed and the Android build completes successfully in the deployment environment.
