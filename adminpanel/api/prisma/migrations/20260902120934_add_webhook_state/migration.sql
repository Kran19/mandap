/*
  Warnings:

  - You are about to drop the column `errorMessage` on the `WebhookEvent` table. All the data in the column will be lost.
  - Added the required column `payloadHash` to the `WebhookEvent` table without a default value. This is not possible if the table is not empty.

*/
-- AlterTable
ALTER TABLE "WebhookEvent" DROP COLUMN "errorMessage",
ADD COLUMN     "attempts" INTEGER NOT NULL DEFAULT 0,
ADD COLUMN     "lastAttemptAt" TIMESTAMP(3),
ADD COLUMN     "lastError" TEXT,
ADD COLUMN     "payloadHash" TEXT NOT NULL;
