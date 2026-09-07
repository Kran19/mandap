const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();
async function main() {
  await prisma.planLimit.updateMany({ where: { key: 'max_projects' }, data: { value: 100 } });
  console.log('Updated limits');
}
main().catch(console.error).finally(() => prisma.$disconnect());
