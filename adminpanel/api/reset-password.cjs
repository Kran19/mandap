const { PrismaClient } = require('@prisma/client');
const argon2 = require('argon2');

const prisma = new PrismaClient();

async function resetPassword() {
  const hash = await argon2.hash('password123');
  await prisma.user.updateMany({
    where: { email: 'abc@gmail.com' },
    data: { passwordHash: hash }
  });
  console.log('Password reset to password123');
}

resetPassword()
  .catch(console.error)
  .finally(() => prisma.$disconnect());
