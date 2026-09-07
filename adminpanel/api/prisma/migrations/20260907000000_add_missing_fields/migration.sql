-- CreateEnum
CREATE TYPE "TrialStatus" AS ENUM ('REQUESTED', 'ESTABLISHED', 'CANCELLED', 'CONVERTED', 'EXPIRED');

-- AlterEnum
BEGIN;
CREATE TYPE "SubscriptionStatus_new" AS ENUM ('PENDING_AUTHORIZATION', 'TRIALING', 'ACTIVE', 'PAST_DUE', 'RESTRICTED', 'CANCELLED', 'EXPIRED');
ALTER TABLE "public"."Subscription" ALTER COLUMN "status" DROP DEFAULT;
ALTER TABLE "Subscription" ALTER COLUMN "status" TYPE "SubscriptionStatus_new" USING ("status"::text::"SubscriptionStatus_new");
ALTER TYPE "SubscriptionStatus" RENAME TO "SubscriptionStatus_old";
ALTER TYPE "SubscriptionStatus_new" RENAME TO "SubscriptionStatus";
DROP TYPE "public"."SubscriptionStatus_old";
ALTER TABLE "Subscription" ALTER COLUMN "status" SET DEFAULT 'TRIALING';
COMMIT;

-- DropIndex
DROP INDEX "ProjectVersion_projectId_version_key";

-- AlterTable
ALTER TABLE "AuditLog" ADD COLUMN     "actorUserId" TEXT,
ADD COLUMN     "organizationId" TEXT,
ALTER COLUMN "adminId" DROP NOT NULL;

-- AlterTable
ALTER TABLE "Project" ADD COLUMN     "archivedAt" TIMESTAMP(3),
ADD COLUMN     "description" TEXT;

-- AlterTable
ALTER TABLE "ProjectVersion" DROP COLUMN "version",
ADD COLUMN     "metadata" JSONB,
ADD COLUMN     "versionNumber" INTEGER NOT NULL;

-- AlterTable
ALTER TABLE "Subscription" ALTER COLUMN "status" SET DEFAULT 'TRIALING';

-- AlterTable
ALTER TABLE "User" ADD COLUMN     "aadhaarBackUrl" TEXT,
ADD COLUMN     "aadhaarFrontUrl" TEXT,
ADD COLUMN     "aadhaarNumber" TEXT,
ADD COLUMN     "gender" TEXT,
ADD COLUMN     "identityVerifiedAt" TIMESTAMP(3),
ADD COLUMN     "mobileVerifiedAt" TIMESTAMP(3);

-- CreateTable
CREATE TABLE "IdempotencyRecord" (
    "id" TEXT NOT NULL,
    "organizationId" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "endpoint" TEXT NOT NULL,
    "idempotencyKey" TEXT NOT NULL,
    "requestHash" TEXT NOT NULL,
    "status" TEXT NOT NULL DEFAULT 'PENDING',
    "responseStatus" INTEGER,
    "responseBody" JSONB,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "expiresAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "IdempotencyRecord_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "TrialSetup" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "organizationId" TEXT NOT NULL,
    "planId" TEXT NOT NULL,
    "emailNormalizedHash" TEXT NOT NULL,
    "mobileNormalizedHash" TEXT,
    "identityReferenceHash" TEXT,
    "providerSubscriptionId" TEXT,
    "status" TEXT NOT NULL DEFAULT 'PENDING',
    "expiresAt" TIMESTAMP(3) NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "TrialSetup_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "TrialClaim" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "organizationId" TEXT NOT NULL,
    "trialPlanId" TEXT NOT NULL,
    "subscriptionId" TEXT,
    "emailNormalizedHash" TEXT NOT NULL,
    "mobileNormalizedHash" TEXT,
    "identityReferenceHash" TEXT,
    "paymentFingerprint" TEXT,
    "status" "TrialStatus" NOT NULL DEFAULT 'ESTABLISHED',
    "requestedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "startedAt" TIMESTAMP(3),
    "endsAt" TIMESTAMP(3),
    "consumedAt" TIMESTAMP(3),
    "cancelledAt" TIMESTAMP(3),
    "abandonedAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "TrialClaim_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "IdempotencyRecord_expiresAt_idx" ON "IdempotencyRecord"("expiresAt");

-- CreateIndex
CREATE UNIQUE INDEX "IdempotencyRecord_organizationId_userId_endpoint_idempotenc_key" ON "IdempotencyRecord"("organizationId", "userId", "endpoint", "idempotencyKey");

-- CreateIndex
CREATE UNIQUE INDEX "TrialSetup_providerSubscriptionId_key" ON "TrialSetup"("providerSubscriptionId");

-- CreateIndex
CREATE INDEX "TrialSetup_userId_idx" ON "TrialSetup"("userId");

-- CreateIndex
CREATE INDEX "TrialSetup_organizationId_idx" ON "TrialSetup"("organizationId");

-- CreateIndex
CREATE INDEX "TrialSetup_status_idx" ON "TrialSetup"("status");

-- CreateIndex
CREATE UNIQUE INDEX "TrialClaim_subscriptionId_key" ON "TrialClaim"("subscriptionId");

-- CreateIndex
CREATE UNIQUE INDEX "TrialClaim_emailNormalizedHash_key" ON "TrialClaim"("emailNormalizedHash");

-- CreateIndex
CREATE UNIQUE INDEX "TrialClaim_mobileNormalizedHash_key" ON "TrialClaim"("mobileNormalizedHash");

-- CreateIndex
CREATE UNIQUE INDEX "TrialClaim_identityReferenceHash_key" ON "TrialClaim"("identityReferenceHash");

-- CreateIndex
CREATE UNIQUE INDEX "TrialClaim_paymentFingerprint_key" ON "TrialClaim"("paymentFingerprint");

-- CreateIndex
CREATE INDEX "TrialClaim_userId_idx" ON "TrialClaim"("userId");

-- CreateIndex
CREATE INDEX "TrialClaim_organizationId_idx" ON "TrialClaim"("organizationId");

-- CreateIndex
CREATE INDEX "TrialClaim_status_idx" ON "TrialClaim"("status");

-- CreateIndex
CREATE INDEX "AuditLog_actorUserId_idx" ON "AuditLog"("actorUserId");

-- CreateIndex
CREATE INDEX "AuditLog_organizationId_idx" ON "AuditLog"("organizationId");

-- CreateIndex
CREATE INDEX "ProjectVersion_projectId_idx" ON "ProjectVersion"("projectId");

-- CreateIndex
CREATE INDEX "ProjectVersion_projectId_createdAt_idx" ON "ProjectVersion"("projectId", "createdAt");

-- CreateIndex
CREATE UNIQUE INDEX "ProjectVersion_projectId_versionNumber_key" ON "ProjectVersion"("projectId", "versionNumber");

-- AddForeignKey
ALTER TABLE "TrialSetup" ADD CONSTRAINT "TrialSetup_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "TrialSetup" ADD CONSTRAINT "TrialSetup_organizationId_fkey" FOREIGN KEY ("organizationId") REFERENCES "Organization"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "TrialSetup" ADD CONSTRAINT "TrialSetup_planId_fkey" FOREIGN KEY ("planId") REFERENCES "Plan"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "TrialClaim" ADD CONSTRAINT "TrialClaim_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "TrialClaim" ADD CONSTRAINT "TrialClaim_organizationId_fkey" FOREIGN KEY ("organizationId") REFERENCES "Organization"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "TrialClaim" ADD CONSTRAINT "TrialClaim_trialPlanId_fkey" FOREIGN KEY ("trialPlanId") REFERENCES "Plan"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "TrialClaim" ADD CONSTRAINT "TrialClaim_subscriptionId_fkey" FOREIGN KEY ("subscriptionId") REFERENCES "Subscription"("id") ON DELETE SET NULL ON UPDATE CASCADE;

