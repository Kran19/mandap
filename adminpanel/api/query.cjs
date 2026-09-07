const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();
async function main() {
  const result = await prisma.subscription.findMany({
    where: { organizationId: 'ecc98bb6-8015-4c97-8766-0a8cde768af1' },
    include: { plan: { include: { limits: true } } }
  });
  console.log(JSON.stringify(result, null, 2));
}
main().catch(console.error).finally(() => prisma.$disconnect());
