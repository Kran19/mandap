export type UserStatus = 'ACTIVE' | 'SUSPENDED' | 'ARCHIVED' | 'DELETED';
export type OrganizationStatus = 'ACTIVE' | 'SUSPENDED' | 'ARCHIVED' | 'DELETED';
export type ProjectStatus = 'ACTIVE' | 'ARCHIVED' | 'DELETED';
export type AdminRole = 'SUPER_ADMIN' | 'ADMIN' | 'FINANCE' | 'SUPPORT' | 'OPERATIONS';
export type MembershipRole = 'OWNER' | 'EDITOR' | 'VIEWER';

export interface Pagination {
  total: number;
  page: number;
  limit: number;
}

export interface PaginatedResponse<T> {
  data: T[];
  meta: Pagination;
}

export interface ApiError {
  status: number;
  message: string;
  error?: string;
  details?: any;
}

export interface User {
  id: string;
  email: string;
  firstName: string | null;
  lastName: string | null;
  phone: string | null;
  status: UserStatus;
  createdAt: string;
  updatedAt: string;
}

export interface Organization {
  id: string;
  name: string;
  slug: string;
  status: OrganizationStatus;
  createdAt: string;
  updatedAt: string;
}

export interface OrganizationMember {
  id: string;
  organizationId: string;
  userId: string;
  role: MembershipRole;
  createdAt: string;
  user?: Partial<User>;
}

export interface AdminPermission {
  id: string;
  roleId: string;
  action: string;
}

export interface AdminRoleModel {
  id: string;
  name: AdminRole;
  description: string | null;
  isActive: boolean;
  createdAt: string;
  updatedAt: string;
  permissions?: AdminPermission[];
}

export interface PlanFeature {
  id: string;
  planId: string;
  featureKey: string;
  enabled: boolean;
}

export interface PlanLimit {
  id: string;
  planId: string;
  key: string;
  value: number;
}

export interface Plan {
  id: string;
  name: string;
  slug: string;
  description: string | null;
  monthlyPrice: string;
  yearlyPrice: string;
  currency: string;
  status: string;
  features?: PlanFeature[];
  limits?: PlanLimit[];
  createdAt: string;
  updatedAt: string;
}

export interface Project {
  id: string;
  organizationId: string;
  name: string;
  status: ProjectStatus;
  currentVersionId: string | null;
  createdBy: string | null;
  stateData?: any;
  createdAt: string;
  updatedAt: string;
  organization?: Partial<Organization>;
  _count?: {
    versions: number;
  };
}

export interface FeatureFlag {
  id: string;
  key: string;
  type: 'BOOLEAN' | 'STRING' | 'NUMBER' | 'JSON';
  value: string | null;
  description: string | null;
  isEnabled: boolean;
  createdAt: string;
  updatedAt: string;
}

export interface AuditLog {
  id: string;
  actorUserId: string | null;
  action: string;
  targetResource: string;
  targetResourceId: string | null;
  organizationId: string | null;
  previousState: any | null;
  newState: any | null;
  metadata: any | null;
  ipAddress: string | null;
  userAgent: string | null;
  createdAt: string;
  actorUser?: Partial<User>;
}

// Current User Context
export interface CurrentAdminUser {
  id: string;
  email: string;
  firstName: string | null;
  lastName: string | null;
  status: UserStatus;
  roles: AdminRoleModel[];
}
