import { describe, it, expect } from 'vitest';
import { hasPermission, AdminPermissions } from './helpers';
import { CurrentAdminUser } from '@/types';

describe('Permissions Helpers', () => {
  it('returns false for null user', () => {
    expect(hasPermission(null, AdminPermissions.USERS_READ)).toBe(false);
  });

  it('returns true if user has explicit permission', () => {
    const user: CurrentAdminUser = {
      id: '1',
      email: 'test@example.com',
      firstName: 'Test',
      lastName: 'User',
      status: 'ACTIVE',
      roles: [
        {
          id: 'role1',
          name: 'ADMIN',
          description: '',
          isActive: true,
          createdAt: '',
          updatedAt: '',
          permissions: [{ id: 'p1', roleId: 'role1', action: AdminPermissions.USERS_READ }]
        }
      ]
    };
    expect(hasPermission(user, AdminPermissions.USERS_READ)).toBe(true);
    expect(hasPermission(user, AdminPermissions.USERS_WRITE)).toBe(false);
  });

  it('returns true for SUPER_ADMIN regardless of explicit permissions', () => {
    const user: CurrentAdminUser = {
      id: '1',
      email: 'test@example.com',
      firstName: 'Test',
      lastName: 'User',
      status: 'ACTIVE',
      roles: [
        {
          id: 'role1',
          name: 'SUPER_ADMIN',
          description: '',
          isActive: true,
          createdAt: '',
          updatedAt: '',
          permissions: []
        }
      ]
    };
    expect(hasPermission(user, AdminPermissions.USERS_READ)).toBe(true);
    expect(hasPermission(user, AdminPermissions.USERS_WRITE)).toBe(true);
  });
});
