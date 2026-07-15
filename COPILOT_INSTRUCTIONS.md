# ESMS (Electrical Shop Management System)

You are an expert Flutter, Firebase, Riverpod and Clean Architecture developer.

You are building a production-quality application.

Never generate demo code.
Never generate placeholder code.
Never generate TODOs.
Every file must compile.

---

TECH STACK

Flutter
Firebase Auth
Cloud Firestore
Firebase Storage
Riverpod
GoRouter

---

ARCHITECTURE

lib/

app/

core/
constants/
services/
utils/
errors/
extensions/

shared/
widgets/
models/
providers/

features/

    auth/

    dashboard/

    master/

    products/

    suppliers/

    purchase_orders/

    billing/

    inventory/

    returns/

    expenses/

    reports/

    staff/

    settings/

    activity_logs/

---

FIRESTORE COLLECTIONS

users

products

brands

categories

locations

suppliers

purchase_orders

bills

expenses

returns

activity_logs

settings

counters

---

MASTER DATA

Brands

Categories

Locations

Master Data is reusable.

Never duplicate Brand screens,
Category screens,
Location screens.

Always build reusable components.

---

PRODUCT MODEL

Fields

id

sku

name

brandId

categoryId

unit

purchasePrice

sellingPrice

stockQuantity

minimumStock

supplierId

locationId

barcode

imageUrl

status

createdAt

updatedAt

---

UNITS

Piece

Meter

Packet

---

STAFF TYPES

Owner

Staff

Electrician

---

ROUTING

GoRouter only.

Never use Navigator.push.

---

STATE MANAGEMENT

Riverpod only.

Never use Provider package.

---

REPOSITORY PATTERN

Screen

↓

Provider

↓

Repository

↓

Service

↓

Firestore

---

WIDGETS

Use reusable widgets.

PrimaryButton

PrimaryTextField

PrimarySearchBar

LoadingWidget

EmptyState

---

UI

Material 3

Responsive

Clean

Minimal

Professional

Suitable for shop owner.

---

CODE STYLE

Small files.

Single Responsibility Principle.

No duplicated code.

Meaningful variable names.

Null safety.

No warnings.

No analyzer issues.

---

BEFORE WRITING CODE

Reuse existing code.

Never recreate files unnecessarily.

Respect current folder structure.

Never change model names without updating every dependent file.

---

WHEN GENERATING A FEATURE

Generate ALL required files.

Update existing files when needed.

Never leave compilation errors.

Always finish the feature completely.

---

WHEN MODIFYING A MODEL

Automatically update

Repository

Provider

Service

Widgets

Screens

Firestore serialization

No partial updates.

---

CURRENT STATUS

Authentication Complete

Firebase Complete

GoRouter Complete

Master Data In Progress

Products In Progress

Suppliers Pending

Billing Pending

Purchase Orders Pending

Inventory Pending

Reports Pending

Staff Pending

Settings Pending

---

GOAL

Build a complete production-ready Electrical Shop Management System.
