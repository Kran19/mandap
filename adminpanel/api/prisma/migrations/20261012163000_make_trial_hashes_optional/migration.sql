-- AlterTable
ALTER TABLE "TrialSetup" ALTER COLUMN "emailNormalizedHash" DROP NOT NULL;

-- AlterTable
ALTER TABLE "TrialClaim" ALTER COLUMN "emailNormalizedHash" DROP NOT NULL;
