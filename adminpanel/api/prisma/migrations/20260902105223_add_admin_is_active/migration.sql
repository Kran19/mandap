-- AlterTable
ALTER TABLE "AdminMembership" ADD COLUMN     "isActive" BOOLEAN NOT NULL DEFAULT true;

-- AlterTable
ALTER TABLE "AdminRoleModel" ADD COLUMN     "isActive" BOOLEAN NOT NULL DEFAULT true;
