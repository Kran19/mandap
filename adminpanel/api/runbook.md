# Production Operations Runbook

## Database Backup & Recovery Policy

### 1. Recovery Objectives
- **RPO (Recovery Point Objective):** 5 minutes. (Maximum tolerable data loss is 5 minutes). Achieved via Continuous WAL archiving (e.g., AWS RDS or pgBackRest).
- **RTO (Recovery Time Objective):** 30 minutes. (Maximum time to restore full service availability from a critical failure).

### 2. Automated Backups
- **Daily Full Backups:** A full snapshot of the Postgres database is taken daily at 02:00 UTC. Retained for 35 days.
- **Continuous Archiving:** Write-Ahead Logs (WAL) are archived every 5 minutes to S3 (or equivalent object storage).

### 3. Restore Procedure
1. Identify the point-in-time required for restoration (e.g., `2024-10-01 14:00:00 UTC`).
2. Provision a new Postgres instance from the daily snapshot preceding the timestamp.
3. Replay WAL logs up to the exact timestamp.
4. Verify data integrity (e.g., spot-check `IdempotencyRecord` and recent `ProjectVersion` entries).
5. Update application `DATABASE_URL` secrets to point to the new instance.
6. Trigger a rolling restart of the API containers.

### 4. Restore Verification (Monthly)
- On the 1st of every month, a dry-run restore must be performed to an isolated staging environment.
- Verification includes running the `k6` load test against the restored database to ensure performance is maintained and indexes are intact.

## Database Migrations
- **Production Rule:** Never use `prisma db push` in production.
- All schema changes must be applied via `npx prisma migrate deploy` in the CI/CD pipeline.

## Health Checks
- `GET /health/live`: Verifies the NestJS process is running.
- `GET /health/ready`: Verifies database connectivity. Use this for Load Balancer routing.
