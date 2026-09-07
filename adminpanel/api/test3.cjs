const { PrismaClient } = require('@prisma/client');
const crypto = require('crypto');
const jwt = require('jsonwebtoken');
const http = require('http');

const prisma = new PrismaClient();

async function main() {
  const user = await prisma.user.findFirst({
    where: { email: { startsWith: 'abc' } },
    include: { organizations: true }
  });

  if (!user) {
    console.error('User not found');
    return;
  }

  const payload = { sub: user.id };
  const accessToken = jwt.sign(payload, process.env.JWT_ACCESS_SECRET || 'secret123', { expiresIn: '1h' });

  const reqMe = http.request({
    hostname: 'localhost',
    port: 3001,
    path: '/api/v1/auth/me',
    method: 'GET',
    headers: { 'Authorization': 'Bearer ' + accessToken }
  }, (res) => {
    let data = '';
    res.on('data', chunk => data += chunk);
    res.on('end', () => {
      console.log('ME STATUS:', res.statusCode);
      console.log('ME BODY:', data);
    });
  });

  reqMe.end();
}

main().catch(console.error).finally(() => prisma.$disconnect());
