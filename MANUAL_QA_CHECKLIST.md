# ESMS Manual QA Checklist

APK under test: `build/app/outputs/flutter-apk/app-debug.apk`

Record the observed result in **Actual result**, mark **PASS** or **FAIL**, and add context in **Notes**.

## 1. App Launch / Splash

- [ ] **Test action:** Launch the APK from a cold start.
  - **Expected result:** Splash appears briefly and routes to the correct state.
  - **Actual result:**
  - **PASS/FAIL:**
  - **Notes:**

## 2. Setup Flow

- [ ] **Test action:** On a fresh environment, open Setup and submit valid shop information.
  - **Expected result:** Fields validate, setup saves successfully, and the app navigates to the Dashboard only after saving.
  - **Actual result:**
  - **PASS/FAIL:**
  - **Notes:**

- [ ] **Test action:** Submit Setup with missing or invalid shop fields.
  - **Expected result:** Validation messages appear and no invalid data is saved.
  - **Actual result:**
  - **PASS/FAIL:**
  - **Notes:**

## 3. Login / Logout

- [ ] **Test action:** Log in with valid Firebase Auth credentials.
  - **Expected result:** Login succeeds and the Dashboard opens.
  - **Actual result:**
  - **PASS/FAIL:**
  - **Notes:**

- [ ] **Test action:** Try invalid email, invalid password, disabled user, and network interruption scenarios.
  - **Expected result:** Friendly error feedback appears; protected content is not opened.
  - **Actual result:**
  - **PASS/FAIL:**
  - **Notes:**

- [ ] **Test action:** Use Forgot password with a valid and invalid email.
  - **Expected result:** Valid email receives a reset email; invalid input shows validation or friendly error feedback.
  - **Actual result:**
  - **PASS/FAIL:**
  - **Notes:**

- [ ] **Test action:** Sign out from Settings.
  - **Expected result:** Firebase session ends and the app returns to Login.
  - **Actual result:**
  - **PASS/FAIL:**
  - **Notes:**

## 4. Dashboard Navigation

- [ ] **Test action:** Open each Dashboard module card.
  - **Expected result:** Each card opens the correct screen without crashes or broken back navigation.
  - **Actual result:**
  - **PASS/FAIL:**
  - **Notes:**

## 5. Master Data

### Brands

- [ ] **Test action:** Create, edit, search, and delete or deactivate a brand if supported.
  - **Expected result:** Changes persist and appear after reload; invalid input is rejected.
  - **Actual result:**
  - **PASS/FAIL:**
  - **Notes:**

### Categories

- [ ] **Test action:** Create, edit, search, and delete or deactivate a category if supported.
  - **Expected result:** Changes persist and appear after reload; invalid input is rejected.
  - **Actual result:**
  - **PASS/FAIL:**
  - **Notes:**

### Locations

- [ ] **Test action:** Create, edit, search, and delete or deactivate a location if supported.
  - **Expected result:** Changes persist and appear after reload; invalid input is rejected.
  - **Actual result:**
  - **PASS/FAIL:**
  - **Notes:**

## 6. Products

### Create

- [ ] **Test action:** Create a product using valid fields and master-data selections.
  - **Expected result:** Product saves and appears in the product list.
  - **Actual result:**
  - **PASS/FAIL:**
  - **Notes:**

### Edit

- [ ] **Test action:** Edit product details and save.
  - **Expected result:** Updated values persist and are shown in list/details views.
  - **Actual result:**
  - **PASS/FAIL:**
  - **Notes:**

### Search / Filter

- [ ] **Test action:** Search products by name/SKU and use available status or stock filters.
  - **Expected result:** Results match the query/filter and empty results show an empty state.
  - **Actual result:**
  - **PASS/FAIL:**
  - **Notes:**

## 7. Inventory

### Stock Display

- [ ] **Test action:** Open Inventory and inspect product stock quantities and stock status.
  - **Expected result:** Quantities, low-stock, and out-of-stock states are accurate.
  - **Actual result:**
  - **PASS/FAIL:**
  - **Notes:**

### Stock Adjustment

- [ ] **Test action:** Increase and decrease stock with valid quantities and reasons.
  - **Expected result:** Stock changes atomically and invalid or negative-result adjustments are rejected.
  - **Actual result:**
  - **PASS/FAIL:**
  - **Notes:**

### Stock History

- [ ] **Test action:** Open product stock history after adjustments.
  - **Expected result:** Each adjustment shows the correct previous stock, new stock, difference, reason, and staff information.
  - **Actual result:**
  - **PASS/FAIL:**
  - **Notes:**

## 8. Purchase Orders

### Create

- [ ] **Test action:** Create a purchase order and select a supplier from the supplier data layer.
  - **Expected result:** Supplier selection is provider-backed, products and quantities validate, and the order saves.
  - **Actual result:**
  - **PASS/FAIL:**
  - **Notes:**

### Edit

- [ ] **Test action:** Edit an eligible purchase order.
  - **Expected result:** Editable fields save; system-managed statuses remain protected.
  - **Actual result:**
  - **PASS/FAIL:**
  - **Notes:**

### Receive Stock

- [ ] **Test action:** Receive all or part of an open purchase order.
  - **Expected result:** Received quantities are clamped to remaining quantities and status becomes Partially Received or Completed correctly.
  - **Actual result:**
  - **PASS/FAIL:**
  - **Notes:**

- [ ] **Test action:** Attempt to receive a completed or cancelled order, or receive it twice.
  - **Expected result:** Operation is rejected and stock is not duplicated.
  - **Actual result:**
  - **PASS/FAIL:**
  - **Notes:**

### Verify Inventory Changes

- [ ] **Test action:** Compare product stock before and after receiving a purchase order.
  - **Expected result:** Inventory increases exactly by the received quantity and history is recorded.
  - **Actual result:**
  - **PASS/FAIL:**
  - **Notes:**

## 9. Billing POS

### Add Products

- [ ] **Test action:** Add in-stock products to the cart.
  - **Expected result:** Product, price, quantity, and line total appear correctly.
  - **Actual result:**
  - **PASS/FAIL:**
  - **Notes:**

### Change Quantities

- [ ] **Test action:** Increase and decrease cart quantities within available stock.
  - **Expected result:** Totals update correctly and quantity cannot exceed available stock.
  - **Actual result:**
  - **PASS/FAIL:**
  - **Notes:**

### Remove Items

- [ ] **Test action:** Remove a product from the cart.
  - **Expected result:** Item disappears and subtotal/discount/total recalculate correctly.
  - **Actual result:**
  - **PASS/FAIL:**
  - **Notes:**

### Finalize Bill

- [ ] **Test action:** Complete a bill with payment method and optional customer information.
  - **Expected result:** Bill is created once with the correct total and bill number.
  - **Actual result:**
  - **PASS/FAIL:**
  - **Notes:**

### Verify Stock Reduction

- [ ] **Test action:** Compare product stock before and after checkout.
  - **Expected result:** Stock decreases exactly by sold quantities; insufficient stock prevents checkout.
  - **Actual result:**
  - **PASS/FAIL:**
  - **Notes:**

## 10. Expenses

### Create

- [ ] **Test action:** Create an expense with valid title, category, amount, date, and payment method.
  - **Expected result:** Expense saves and appears in the expense list.
  - **Actual result:**
  - **PASS/FAIL:**
  - **Notes:**

### Edit

- [ ] **Test action:** Edit an existing expense.
  - **Expected result:** Updated values persist and its original creation identity remains intact.
  - **Actual result:**
  - **PASS/FAIL:**
  - **Notes:**

### Delete

- [ ] **Test action:** Delete an expense and confirm the destructive action.
  - **Expected result:** Confirmation is required; confirmed deletion removes the expense and updates totals.
  - **Actual result:**
  - **PASS/FAIL:**
  - **Notes:**

### Filters

- [ ] **Test action:** Search/filter expenses by text, category, and date range.
  - **Expected result:** Results and totals match the selected filters; empty results show an empty state.
  - **Actual result:**
  - **PASS/FAIL:**
  - **Notes:**

## 11. Reports

### Date Filters

- [ ] **Test action:** Test Today, Yesterday, This Week, This Month, and Custom date ranges.
  - **Expected result:** All report values update to include only records in the selected range.
  - **Actual result:**
  - **PASS/FAIL:**
  - **Notes:**

### Sales

- [ ] **Test action:** Compare report sales totals with finalized bills.
  - **Expected result:** Bill count, sales total, items sold, payment methods, and top products are accurate.
  - **Actual result:**
  - **PASS/FAIL:**
  - **Notes:**

### Expenses

- [ ] **Test action:** Compare report expense totals and categories with saved expenses.
  - **Expected result:** Expense total, count, categories, and daily values are accurate.
  - **Actual result:**
  - **PASS/FAIL:**
  - **Notes:**

### Profit

- [ ] **Test action:** Compare revenue, expenses, COGS, and net profit with known test data.
  - **Expected result:** Calculation is consistent and clearly treated as an estimate using current product purchase prices.
  - **Actual result:**
  - **PASS/FAIL:**
  - **Notes:**

### Inventory

- [ ] **Test action:** Compare inventory product count, stock quantity, and valuations with Products/Inventory.
  - **Expected result:** Inventory metrics match current product data.
  - **Actual result:**
  - **PASS/FAIL:**
  - **Notes:**

### Purchase Reports

- [ ] **Test action:** Compare purchase totals, status counts, and daily values with purchase orders.
  - **Expected result:** Purchase report values match saved purchase orders and statuses.
  - **Actual result:**
  - **PASS/FAIL:**
  - **Notes:**

### Charts

- [ ] **Test action:** Inspect sales/expenses, expense category, payment method, and top-product charts.
  - **Expected result:** Charts render without overflow, blank data is handled, and values correspond to report data.
  - **Actual result:**
  - **PASS/FAIL:**
  - **Notes:**

## 12. Staff & Roles

### Staff List

- [ ] **Test action:** Open the staff list and use search and role/status filters.
  - **Expected result:** Staff records display correctly with loading, empty, error, and refresh behavior.
  - **Actual result:**
  - **PASS/FAIL:**
  - **Notes:**

### Role / Status Behavior

- [ ] **Test action:** Review Owner, Staff, and Electrician permissions with active and inactive profiles.
  - **Expected result:** Permissions match the centralized role definitions; inactive users cannot use protected areas.
  - **Actual result:**
  - **PASS/FAIL:**
  - **Notes:**

### Owner Protection

- [ ] **Test action:** Attempt to deactivate, delete, or change the Owner role.
  - **Expected result:** Owner protection blocks the operation.
  - **Actual result:**
  - **PASS/FAIL:**
  - **Notes:**

## 13. Settings

### Shop Information

- [ ] **Test action:** Edit shop name, phone, email, address, GST setting, currency, and supported prefixes.
  - **Expected result:** Authorized changes validate, save, and remain after reload; unauthorized users cannot save.
  - **Actual result:**
  - **PASS/FAIL:**
  - **Notes:**

### Password Reset

- [ ] **Test action:** Send a password reset email from Settings.
  - **Expected result:** Firebase Auth sends the email and the app shows success or friendly error feedback.
  - **Actual result:**
  - **PASS/FAIL:**
  - **Notes:**

### Logout

- [ ] **Test action:** Use Settings > Sign out.
  - **Expected result:** User is signed out and returned to Login.
  - **Actual result:**
  - **PASS/FAIL:**
  - **Notes:**

## 14. Firebase / Security Behavior

### Unauthenticated Access

- [ ] **Test action:** Sign out, then attempt to open a protected route directly or reopen the APK.
  - **Expected result:** Access is redirected to Login; protected Firestore data is not exposed.
  - **Actual result:**
  - **PASS/FAIL:**
  - **Notes:**

### Inactive User Behavior

- [ ] **Test action:** Mark a test user inactive, sign in or refresh an existing session, and attempt protected navigation.
  - **Expected result:** User is blocked from protected application areas and receives appropriate feedback.
  - **Actual result:**
  - **PASS/FAIL:**
  - **Notes:**

### Firestore Permissions

- [ ] **Test action:** Exercise reads/writes as Owner, Staff, Electrician, inactive user, and unauthenticated user.
  - **Expected result:** Deployed `firestore.rules` allow only the documented operations for each role and reject unauthorized writes.
  - **Actual result:**
  - **PASS/FAIL:**
  - **Notes:**

## QA Summary

- **Tester:**
- **APK version/build:**
- **Device/emulator:**
- **Test date:**
- **Passed checks:**
- **Failed checks:**
- **Release decision:**
- **Blocking notes:**
