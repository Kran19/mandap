const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();
async function main() {
  console.log(await prisma.project.findMany({ where: { organizationId: 'ecc98bb6-8015-4c97-8766-0a8cde768af1' } }));
}
main().catch(console.error).finally(() => prisma.$disconnect());
