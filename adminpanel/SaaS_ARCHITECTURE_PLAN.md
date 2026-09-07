# MASTER PROMPT — MANDAP SaaS Admin Panel UI & Architecture Planning

## A. Repository Audit
**Current State of the Repository:**
The workspace has just been restructured into two main directories:
1. `application/` - Contains the existing MANDAP product (Flutter App).
2. `adminpanel/` - Currently empty; will host the Next.js and NestJS infrastructure.

**Existing `application/` (Flutter Customer App):**
- **Architecture:** Domain-Driven Design (DDD) with clear separation of `domain`, `application` (controllers, commands), `presentation` (UI, 2D/3D views), and `renderer`.
- **Core Logic:** Contains robust pure-Dart logic for Truss calculations, Pole placement, Bill of Materials (BOM) generation, and drag constraints (`MandapCalculationEngine`, `TrussOptimizer`).
- **State Management:** Uses `ChangeNotifier` (`MandapEditorController`) and local state.
- **Missing Elements:** No backend, no API client, no authentication, no persistent database, no multi-tenancy.

## B. Current Architecture Assessment
**Strengths:**
- The 3D editor and truss calculation engine are decoupled from the UI and operate purely in Dart, making it highly portable.
- The command pattern (`AddNodeCommand`, etc.) enables easy undo/redo and potential synchronization with a backend.

**Weaknesses & Risks:**
- **Zero Persistence:** Currently relies entirely on ephemeral local memory. 
- **Missing Tenancy:** The app assumes a single-user environment.
- **Risk:** Integrating a backend without disrupting the complex synchronous 3D interactions. State synchronization between the real-time editor and the API must be handled carefully.

## C. Proposed SaaS Architecture
The system will evolve into a modular monorepo, where Flutter serves as a first-class API client:

```text
                         MANDAP
                           │
            ┌──────────────┴──────────────┐
            │                             │
      ADMIN PANEL                   CUSTOMER APP
        Next.js                        Flutter
            │                             │
            └──────────────┬──────────────┘
                           │
                      NestJS API
                           │
       ┌───────────┬───────┼────────┬───────────┐
       │           │       │        │           │
     Auth       Tenant    SaaS    Product    Admin
       │           │       │        │           │
       │           │       │        │           │
       │           │    Billing   Projects     RBAC
       │           │    Plans     Versions      Audit
       │           │    Orders    Usage
       │           │    Payments
       │
       └──────────────────────┐
                              │
                         PostgreSQL
                              │
                    ┌─────────┴─────────┐
                    │                   │
                  Redis              Storage
                    │
                 BullMQ
                    │
                Razorpay
```

## D. Multi-Tenant Strategy
**Tenant Isolation & Ownership:**
- The primary unit of tenancy is the **Organization**. 
- Users are assigned to Organizations via an `OrganizationMember` junction table, allowing one user to potentially belong to multiple orgs.
- All SaaS resources (Projects, Subscriptions, Orders, Usage) are strictly hard-linked to an `organizationId`.
- **NestJS Enforcement:** 
  ```text
  JWT ➔ AuthGuard ➔ TenantContext ➔ Authorization ➔ Tenant-aware service/repository ➔ Prisma
  ```
  Tenant isolation must be enforced explicitly at the **service/repository layer**. Integration tests will be mandated to verify cross-tenant boundaries (e.g., ensuring Org A cannot read Org B's projects).
- **Admin Access Mechanism:**
  Request contexts will distinguish between Customer Tenant Scope and Admin Authorization Scope. Admins operate outside tenant boundaries only when granted explicit RBAC permissions, not via a blanket interceptor bypass.

## E. Admin Panel Information Architecture
```text
MANDAP ADMIN

Dashboard (Metrics, MRR, Usage)

CUSTOMERS
  ├─ Users (Search, suspend, view details)
  ├─ Organizations (Manage tenants, view projects)
  └─ Subscriptions (View active, cancel, change plan)

COMMERCE
  ├─ Plans (Configure pricing, limits, features)
  ├─ Orders (Invoices, history)
  └─ Payments (Razorpay transactions, refunds)

PRODUCT
  ├─ Projects (Read-only view of customer projects, archive/restore)
  └─ Feature Flags (Global/Plan level toggles)

SYSTEM
  ├─ Admin Users (Internal staff)
  ├─ Roles & Permissions (RBAC configuration)
  └─ Audit Logs (Immutable admin action trail)

SETTINGS
  └─ General (Global config, webhooks)
```

## F. Admin Module Specifications
1. **Dashboard:** Built against API contracts (even if seeded initially). High-level metrics: Total MRR, Active Orgs, 3D Editor Usage stats.
2. **Users & Organizations:** Searchable datagrids. Actions to suspend accounts or reset passwords. Soft delete lifecycle (`ACTIVE`, `SUSPENDED`, `ARCHIVED`, `DELETED`).
3. **Plans:** Relational configuration (not JSONB blobs). Configure "Professional" plan features and generic limits (max_projects, max_storage_gb).
4. **Commerce (Orders/Payments):** Robust tracking of internal Order and Transaction entities decoupled from external provider objects.
5. **Projects:** Admins can view project metadata (name, version, storage) but cannot edit the 3D layout directly.
6. **System & Audit:** Every critical action is written to an `AuditLog` table.

## G. Database Architecture (PostgreSQL)
**Core Entities:**
- **User:** `id`, `email`, `passwordHash`, `status`, `createdAt`, `updatedAt` (No `is_admin` boolean).
- **Organization & Members:** `Organization` (tenant root) and `OrganizationMember` (mapping Users to Orgs). The authoritative owner is determined via an `OrganizationMember` with `role = OWNER`.
- **Admin Membership:** `AdminMembership` mapping internal staff to an `AdminRole`.
- **Plans & Limits:** 
  - `Plan`: Relational base (prices, provider plan IDs).
  - `PlanFeature`: Toggles for feature access (`planId`, `featureKey`, `enabled`).
  - `PlanLimit`: Quota values (`planId`, `key`, `value` e.g., max_projects=10).
- **Projects (Versioned):**
  - `Project`: Metadata and `currentVersionId`.
  - `ProjectVersion`: `layoutData` (JSONB), `version`, `createdBy`.
- **Billing & Subscriptions:**
  - `Subscription`: Status, plan, billing period.
  - `SubscriptionEvent`: Historical record of upgrades, downgrades, renewals, and cancellations.
  - `Order` / `OrderItem`: Canonical internal representation of purchases.
  - `Payment` / `Transaction`: Internal records mapped via `providerOrderId` and `providerPaymentId`.
  - `WebhookEvent`: `(provider, eventId)` composite unique key for strict idempotency.
- **Usage:** Generic `UsageMetric` (e.g., `projects`, `storage_bytes`) evaluated against `PlanLimit`.
- **AuditLog:** `adminId`, `action`, `resourceName`, `resourceId`, `payload`.

## H. API Architecture (NestJS)
**RESTful Endpoints:**
```text
# Customers
GET    /api/v1/admin/organizations
GET    /api/v1/admin/organizations/:id
POST   /api/v1/admin/organizations/:id/suspend

# Commerce
GET    /api/v1/admin/plans
POST   /api/v1/admin/plans
GET    /api/v1/admin/subscriptions
POST   /api/v1/admin/subscriptions/:id/cancel

# Product
GET    /api/v1/admin/projects
POST   /api/v1/admin/projects/:id/archive

# System
GET    /api/v1/admin/audit-logs
```

## I. Authentication & RBAC
- **Auth System:** Unified identity for both Customers and Admins.
- **Admin Differentiation:** Defined purely by `AdminMembership` -> `AdminRole`.
- **Role Examples:**
  - `SUPER_ADMIN`: `users.*`, `billing.*`, `settings.*`
  - `FINANCE`: `billing.view`, `payments.view`, `refunds.create`
  - `SUPPORT`: `users.view`, `organizations.view`
- **MFA:** Enforced for Admin accounts.

## J. Billing & Subscription Architecture
- **Source of Truth:** Razorpay (or Stripe) drives state changes, but internal db maintains canonical records.
- **Lifecycle & Grace Period:**
  - Subscriptions don't cut off immediately on failure.
  - Lifecycle: `Payment Failed ➔ Past Due ➔ Grace Period ➔ Retry ➔ Still Failed ➔ Restricted ➔ Cancelled`.
  - State tracked via `subscription.status`, `billingStatus`, `accessStatus`, and `gracePeriodEndsAt`.
- **Idempotency:** All incoming webhooks (e.g., `subscription.charged`) are checked against the `WebhookEvent` table to prevent duplicate processing.
- **Subscription History:** Every state change generates a `SubscriptionEvent`.

## K. Usage & Plan Limit Architecture
- **Dynamic Limits:** Plans define limits via relational `PlanLimit` rows.
- **Enforcement Flow:** `Plan ➔ PlanLimit ➔ UsageMetric ➔ Access Decision`.
- **Backend Enforcement:** NestJS Interceptors/Guards strictly validate current `UsageMetric` amounts against limits before allowing resource creation.

## L. Frontend Architecture (Next.js)
- **Framework:** Next.js 14+ (App Router).
- **Styling/UI:** TailwindCSS + shadcn/ui.
- **State/Data Fetching:** TanStack React Query.
- **Strategy:** Build UI against defined API contracts first, avoiding the "visual-first" trap that leads to incompatible data models.

## M. Backend Architecture (NestJS)
- **Structure:** Modular design (`AuthModule`, `TenantModule`, `BillingModule`, `AdminModule`).
- **ORM:** Prisma.
- **Validation:** `class-validator` and `class-transformer` for strict DTOs.
- **Background Jobs:** BullMQ (Redis) for webhook processing and sending emails.

## N. Security Architecture
- **CORS:** Strictly limited to the frontend domains.
- **Rate Limiting:** NestJS `ThrottlerModule` applied globally.
- **Webhooks:** Signature verification required. Idempotent processing via `WebhookEvent`.
- **Data:** Passwords hashed with bcrypt. Secrets managed via environment variables.

## O. Testing Strategy
- **Unit Tests (Jest):** Coverage on Billing logic, limits calculation, and RBAC guards.
- **Integration Tests:** Mandatory tests verifying Tenant Isolation at the repository layer.
- **E2E Tests:** Playwright for critical flows (Admin Login ➔ Create Plan ➔ Suspend Organization).

## P. Implementation Phases
* **PHASE 0:** Repository + monorepo foundation
* **PHASE 1:** Database schema + migrations
* **PHASE 2:** Identity + authentication
* **PHASE 3:** Organizations + memberships + tenancy
* **PHASE 4:** RBAC + admin authorization
* **PHASE 5:** Admin API
* **PHASE 6:** Admin Next.js UI
* **PHASE 7:** Plans + billing + Razorpay
* **PHASE 8:** Projects + persistence (Project versions)
* **PHASE 9:** Flutter API integration
* **PHASE 10:** Audit + testing + production hardening

## Q. File/Folder Changes
```text
adminpanel/
  ├── api/                 (NestJS)
  │   ├── prisma/schema.prisma
  │   └── src/
  │       ├── auth/
  │       ├── admin/
  │       ├── billing/
  │       └── projects/
  └── web/                 (Next.js App Router)
      ├── src/app/
      │   ├── (auth)/login/
      │   └── dashboard/
      │       ├── users/
      │       ├── organizations/
      │       └── plans/
      └── components/ui/   (shadcn/ui)
```

## R. Risks & Migration Concerns
1. **Flutter State Sync:** The Flutter app currently holds layout state synchronously. Syncing to the backend will be mitigated by the `ProjectVersion` architecture, allowing users to explicitly "Save" versions.
2. **Visual-First Dashboard:** High risk of building a UI disconnected from real relational data. Mitigated by enforcing Phase 1-5 (Database -> API) before Phase 6 (UI).

## S. Definition of Done
1. Database schema explicitly includes proper RBAC, Relational Plan Limits, Idempotent Webhooks, and Project Versioning.
2. Mandatory integration tests for tenant isolation pass.
3. NestJS exposes secure, tenant-isolated APIs.
4. Next.js Admin Panel is built directly against real API contracts.
5. The existing Flutter app connects to the API to load/save project versions.

---
IMPLEMENTATION STATUS:
PLANNING ONLY

NEXT STEP:
Awaiting architectural approval.
