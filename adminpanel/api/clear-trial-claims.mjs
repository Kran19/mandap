import { PrismaClient } from '@prisma/client';
const prisma = new PrismaClient();

async function main() {
  const deleted = await prisma.trialClaim.deleteMany({});
  console.log(`Deleted ${deleted.count} trial claim(s).`);
  
  const deletedSetups = await prisma.trialSetup.deleteMany({});
  console.log(`Deleted ${deletedSetups.count} trial setup(s).`);

  const deletedIdempotency = await prisma.idempotencyRecord.deleteMany({});
  console.log(`Deleted ${deletedIdempotency.count} idempotency record(s).`);
}

main().catch(console.error).finally(() => prisma.$disconnect());
