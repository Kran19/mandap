# MANDAP SaaS Admin Panel

This directory contains the foundational architecture for the MANDAP SaaS Platform.

## Monorepo Projects

1. **`api/` (NestJS)**: The backend API handling business logic, authentication, multi-tenancy, and interactions with the Postgres database via Prisma.
2. **`web/` (Next.js)**: The administrative dashboard and customer portal built with the App Router and Tailwind CSS v4.

---

## 🚀 Local Development

### 1. Database Setup

We use PostgreSQL as the primary database, managed by Prisma. 

You can start a local PostgreSQL instance via Docker from the root of `adminpanel`:
```bash
docker compose up -d
```
*(This starts PostgreSQL on port 5433 to avoid conflicts with default port 5432.)*

### 2. API Setup

Navigate into the `api` folder:
```bash
cd api
```

Create your environment variables by copying `.env.example`:
```bash
cp .env.example .env
```

Install dependencies, run Prisma migrations, and seed the database:
```bash
npm install
npx prisma migrate dev --name init
npm run start:dev
```

### 3. Web Setup

Navigate into the `web` folder:
```bash
cd web
npm install
npm run dev
```

*(Phase 0 Foundation established)*
