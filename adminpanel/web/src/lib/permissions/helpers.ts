import { CurrentAdminUser } from '@/types';

// Constants for known frontend permissions matching the backend AdminPermissions enum
export const AdminPermissions = {
  USERS_READ: 'USERS_READ',
  USERS_WRITE: 'USERS_WRITE',
  ORGANIZATIONS_READ: 'ORGANIZATIONS_READ',
  ORGANIZATIONS_WRITE: 'ORGANIZATIONS_WRITE',
  MEMBERSHIPS_WRITE: 'MEMBERSHIPS_WRITE',
  ROLES_READ: 'ROLES_READ',
  ROLES_WRITE: 'ROLES_WRITE',
  PLANS_READ: 'PLANS_READ',
  PLANS_WRITE: 'PLANS_WRITE',
  SUBSCRIPTIONS_READ: 'subscriptions.read',
  ORDERS_READ: 'orders.read',
  PAYMENTS_READ: 'payments.read',
  REFUNDS_READ: 'refunds.read',
  REFUNDS_CREATE: 'refunds.create',
  PROJECTS_READ: 'PROJECTS_READ',
  PROJECTS_WRITE: 'PROJECTS_WRITE',
  FEATURE_FLAGS_READ: 'FEATURE_FLAGS_READ',
  FEATURE_FLAGS_WRITE: 'FEATURE_FLAGS_WRITE',
  USAGE_READ: 'USAGE_READ',
  AUDIT_LOGS_READ: 'AUDIT_LOGS_READ',
};

/**
 * Checks if a user has a specific permission.
 * Users with the 'SUPER_ADMIN' role automatically have all permissions conceptually, 
 * but the backend role explicitly grants all permissions. 
 * This helper strictly checks the active permissions returned from the API.
 */
export function hasPermission(user: CurrentAdminUser | null, requiredPermission: string): boolean {
  if (!user || !user.roles) return false;
  
  for (const role of user.roles) {
    if (!role.isActive) continue;
    
    // Some backend architectures give SUPER_ADMIN explicit * or implicitly grant everything
    if (role.name === 'SUPER_ADMIN') return true;

    if (role.permissions && role.permissions.some(p => p.action === requiredPermission)) {
      return true;
    }
  }
  return false;
}

export function hasAnyPermission(user: CurrentAdminUser | null, permissions: string[]): boolean {
  if (!user || !user.roles) return false;
  return permissions.some(permission => hasPermission(user, permission));
}

export function hasAllPermissions(user: CurrentAdminUser | null, permissions: string[]): boolean {
  if (!user || !user.roles) return false;
  return permissions.every(permission => hasPermission(user, permission));
}
