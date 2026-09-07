import { PrismaClient, UserStatus, OrganizationStatus, MembershipRole, AdminRole, ProjectStatus } from '@prisma/client';
import * as argon2 from 'argon2';

const prisma = new PrismaClient();

async function main() {
  console.log('🌱 Starting seed...');

  // 1. Admin Roles & Permissions
  // Stable permission constants (avoiding src/ dependency)
  const ADMIN_PERMISSIONS = {
    USERS_READ: 'ADMIN_USERS_READ',
    USERS_WRITE: 'ADMIN_USERS_WRITE',
    ORGANIZATIONS_READ: 'ADMIN_ORGANIZATIONS_READ',
    ORGANIZATIONS_WRITE: 'ADMIN_ORGANIZATIONS_WRITE',
    MEMBERSHIPS_READ: 'ADMIN_MEMBERSHIPS_READ',
    MEMBERSHIPS_WRITE: 'ADMIN_MEMBERSHIPS_WRITE',
    ROLES_READ: 'ADMIN_ROLES_READ',
    ROLES_WRITE: 'ADMIN_ROLES_WRITE',
    PERMISSIONS_READ: 'ADMIN_PERMISSIONS_READ',
    PERMISSIONS_WRITE: 'ADMIN_PERMISSIONS_WRITE',
    AUDIT_LOGS_READ: 'ADMIN_AUDIT_LOGS_READ',
    PLANS_READ: 'ADMIN_PLANS_READ',
    PLANS_WRITE: 'ADMIN_PLANS_WRITE',
    PROJECTS_READ: 'ADMIN_PROJECTS_READ',
    PROJECTS_WRITE: 'ADMIN_PROJECTS_WRITE',
    FEATURE_FLAGS_READ: 'ADMIN_FEATURE_FLAGS_READ',
    FEATURE_FLAGS_WRITE: 'ADMIN_FEATURE_FLAGS_WRITE',
    USAGE_READ: 'ADMIN_USAGE_READ',
  };

  const allPermissions = Object.values(ADMIN_PERMISSIONS).map((action) => ({ action }));
  const supportPermissions = [
    { action: ADMIN_PERMISSIONS.USERS_READ },
    { action: ADMIN_PERMISSIONS.ORGANIZATIONS_READ },
    { action: ADMIN_PERMISSIONS.MEMBERSHIPS_READ },
    { action: ADMIN_PERMISSIONS.AUDIT_LOGS_READ },
  ];

  console.log('Seeding Admin Roles...');
  const superAdminRole = await prisma.adminRoleModel.upsert({
    where: { name: AdminRole.SUPER_ADMIN },
    update: {},
    create: {
      name: AdminRole.SUPER_ADMIN,
      description: 'Super Administrator with full access',
    },
  });

  const supportRole = await prisma.adminRoleModel.upsert({
    where: { name: AdminRole.SUPPORT },
    update: {},
    create: {
      name: AdminRole.SUPPORT,
      description: 'Customer Support Representative',
    },
  });

  // Idempotently create permissions
  await prisma.adminPermission.deleteMany({ where: { roleId: { in: [superAdminRole.id, supportRole.id] } } });
  
  await prisma.adminPermission.createMany({
    data: allPermissions.map(p => ({ roleId: superAdminRole.id, action: p.action }))
  });
  
  await prisma.adminPermission.createMany({
    data: supportPermissions.map(p => ({ roleId: supportRole.id, action: p.action }))
  });

  // 2. Users
  console.log('Seeding Users...');
  const devPasswordHash = await argon2.hash('Password123!'); // Development only

  const superAdminUser = await prisma.user.upsert({
    where: { email: 'admin@mandap.fake' },
    update: { passwordHash: devPasswordHash },
    create: {
      email: 'admin@mandap.fake',
      passwordHash: devPasswordHash, // Development only
      firstName: 'Super',
      lastName: 'Admin',
      status: UserStatus.ACTIVE,
      adminMembership: {
        create: {
          roleId: superAdminRole.id,
        },
      },
    },
  });

  const customerUser = await prisma.user.upsert({
    where: { email: 'customer@acme.fake' },
    update: { passwordHash: devPasswordHash },
    create: {
      email: 'customer@acme.fake',
      passwordHash: devPasswordHash, // Development only
      firstName: 'Jane',
      lastName: 'Doe',
      status: UserStatus.ACTIVE,
    },
  });

  // 3. Organization & Membership
  console.log('Seeding Organization...');
  const org = await prisma.organization.upsert({
    where: { slug: 'acme-corp' },
    update: {},
    create: {
      name: 'Acme Corp',
      slug: 'acme-corp',
      status: OrganizationStatus.ACTIVE,
      members: {
        create: [
          {
            userId: customerUser.id,
            role: MembershipRole.OWNER,
          },
        ],
      },
    },
  });

  // 4. Plans & Limits
  console.log('Seeding Plans...');
  const freePlan = await prisma.plan.upsert({
    where: { slug: 'free' },
    update: {},
    create: {
      name: 'Free Plan',
      slug: 'free',
      description: 'Basic features for individuals',
      monthlyPrice: 0.0,
      yearlyPrice: 0.0,
      limits: {
        create: [
          { key: 'max_projects', value: 1 },
          { key: 'max_storage_mb', value: 100 },
        ],
      },
      features: {
        create: [{ featureKey: 'THREE_D_EDITOR', enabled: true }],
      },
    },
  });

  const professionalPlan = await prisma.plan.upsert({
    where: { slug: 'professional' },
    update: {},
    create: {
      name: 'Professional Plan',
      slug: 'professional',
      description: 'Advanced features for event professionals',
      monthlyPrice: 2999.0,
      yearlyPrice: 29999.0,
      limits: {
        create: [
          { key: 'max_projects', value: 50 },
          { key: 'max_storage_mb', value: 50000 },
          { key: 'max_team_members', value: 10 },
        ],
      },
      features: {
        create: [
          { featureKey: 'THREE_D_EDITOR', enabled: true },
          { featureKey: 'PDF_EXPORT', enabled: true },
          { featureKey: 'ADVANCED_TEMPLATES', enabled: true },
        ],
      },
    },
  });

  // 5. Projects & Versions
  console.log('Seeding Projects...');
  const project = await prisma.project.create({
    data: {
      organizationId: org.id,
      name: 'Acme Grand Wedding',
      status: ProjectStatus.ACTIVE,
      createdBy: customerUser.id,
      versions: {
        create: [
          {
            versionNumber: 1,
            createdBy: customerUser.id,
            layoutData: { nodes: [], edges: [] }, // Fake 3D layout data
          },
        ],
      },
    },
  });

  console.log('✅ Seeding completed successfully.');
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
