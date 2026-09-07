const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  const users = await prisma.user.findMany({
    include: {
      organizations: true
    }
  });
  console.log(JSON.stringify(users, null, 2));

  const orgs = await prisma.organization.findMany();
  console.log('ORGS:', JSON.stringify(orgs, null, 2));
}

main().catch(console.error).finally(() => prisma.$disconnect());
