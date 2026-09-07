# Prisma Database Schema

This directory contains the database integration for the MANDAP SaaS API.

## Database Technology
- **Database Engine:** PostgreSQL 15+
- **ORM:** Prisma
- **Environment Variable:** `DATABASE_URL`

## Core Concepts (Phase 1)
- **Multi-tenancy:** The `Organization` model represents a tenant. All scoped entities (Projects, Subscriptions, Users via Memberships) link to this tenant.
- **Billing Strategy:** Plans and Limits are explicitly normalized via `Plan`, `PlanFeature`, and `PlanLimit`. We do not rely on JSON blobs for financial or product entitlement boundaries. Idempotent webhooks can be stored in `WebhookEvent`.
- **Project Data:** 3D editor data is versioned under `ProjectVersion.layoutData` (stored as JSON) rather than mutating a live entity.
- **RBAC Strategy:** Admin privileges are managed explicitly via `AdminRoleModel`, `AdminPermission`, and `AdminMembership`. No `isAdmin` column exists on the User table.

## Commands

### Migrations
Apply the Prisma schema to the database (run when schema changes):
```bash
npx prisma migrate dev --name <migration_name>
```

### Reset & Seed
Wipes the database and re-runs migrations and seed scripts:
```bash
npx prisma migrate reset
```
*Never run this in production!*

### Generating Prisma Client
```bash
npx prisma generate
```

### Prisma Studio
Launch the visual database viewer:
```bash
npx prisma studio
```
