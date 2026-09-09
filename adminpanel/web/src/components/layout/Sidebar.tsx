'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { 
  Users, 
  Building2, 
  CreditCard, 
  Settings, 
  Shield, 
  Activity, 
  Briefcase,
  Flag,
  Key,
  LayoutDashboard,
  Menu,
  X,
  Repeat,
  ShoppingCart,
  Banknote,
  Undo
} from 'lucide-react';
import { CurrentAdminUser } from '@/types';
import { hasPermission, AdminPermissions } from '@/lib/permissions/helpers';

interface SidebarProps {
  user: CurrentAdminUser | null;
  open: boolean;
  setOpen: (open: boolean) => void;
}

export default function Sidebar({ user, open, setOpen }: SidebarProps) {
  const pathname = usePathname();

  const navigationGroups: { title: string; items: { name: string; href: string; icon: any; permission?: string }[] }[] = [
    {
      title: 'DASHBOARD',
      items: [
        { name: 'Dashboard', href: '/admin', icon: LayoutDashboard },
      ],
    },
    {
      title: 'CUSTOMERS',
      items: [
        { name: 'Users', href: '/admin/users', icon: Users, permission: AdminPermissions.USERS_READ },
        { name: 'Organizations', href: '/admin/organizations', icon: Building2, permission: AdminPermissions.ORGANIZATIONS_READ },
      ],
    },
    {
      title: 'COMMERCE',
      items: [
        { name: 'Plans', href: '/admin/plans', icon: CreditCard, permission: AdminPermissions.PLANS_READ },
        { name: 'Subscriptions', href: '/admin/subscriptions', icon: Repeat, permission: AdminPermissions.SUBSCRIPTIONS_READ },
        { name: 'Orders', href: '/admin/orders', icon: ShoppingCart, permission: AdminPermissions.ORDERS_READ },
        { name: 'Payments', href: '/admin/payments', icon: Banknote, permission: AdminPermissions.PAYMENTS_READ },
        { name: 'Refunds', href: '/admin/refunds', icon: Undo, permission: AdminPermissions.REFUNDS_READ },
      ],
    },
    {
      title: 'PRODUCT',
      items: [
        { name: 'Projects', href: '/admin/projects', icon: Briefcase, permission: AdminPermissions.PROJECTS_READ },
        { name: 'Feature Flags', href: '/admin/feature-flags', icon: Flag, permission: AdminPermissions.FEATURE_FLAGS_READ },
      ],
    },
    {
      title: 'SYSTEM',
      items: [
        { name: 'Roles', href: '/admin/roles', icon: Shield, permission: AdminPermissions.ROLES_READ },
        { name: 'Permissions', href: '/admin/permissions', icon: Key, permission: AdminPermissions.ROLES_READ }, // Fallback to ROLES_READ if PERMISSIONS_READ isn't separate
        { name: 'Audit Logs', href: '/admin/audit-logs', icon: Activity, permission: AdminPermissions.AUDIT_LOGS_READ },
        { name: 'Settings', href: '/admin/settings', icon: Settings },
      ],
    }
  ];

  return (
    <>
      {/* Mobile overlay */}
      {open && (
        <div 
          className="fixed inset-0 z-20 bg-gray-600 bg-opacity-75 sm:hidden"
          onClick={() => setOpen(false)}
        />
      )}

      {/* Sidebar */}
      <div className={`
        fixed inset-y-0 left-0 z-30 w-64 transform bg-gray-900 transition-transform duration-300 ease-in-out sm:static sm:translate-x-0 sm:flex sm:flex-col
        ${open ? 'translate-x-0' : '-translate-x-full'}
      `}>
        <div className="flex h-16 items-center justify-between px-4 bg-gray-950 sm:justify-center">
          <span className="text-xl font-bold text-white tracking-wider">MANDAP</span>
          <button className="sm:hidden text-gray-300 hover:text-white" onClick={() => setOpen(false)}>
            <X size={24} />
          </button>
        </div>

        <div className="flex-1 overflow-y-auto pt-5 pb-4">
          <nav className="mt-2 px-3 space-y-6">
            {navigationGroups.map((group) => {
              // Filter items based on permissions
              const items = group.items.filter(item => 
                !item.permission || hasPermission(user, item.permission)
              );

              if (items.length === 0) return null;

              return (
                <div key={group.title}>
                  <h3 className="px-3 text-xs font-semibold text-gray-400 uppercase tracking-wider">
                    {group.title}
                  </h3>
                  <div className="mt-2 space-y-1">
                    {items.map((item) => {
                      const isActive = pathname === item.href || (pathname.startsWith(item.href + '/') && item.href !== '/admin');
                      return (
                        <Link
                          key={item.name}
                          href={item.href}
                          onClick={() => setOpen(false)}
                          className={`
                            group flex items-center px-3 py-2 text-sm font-medium rounded-md
                            ${isActive 
                              ? 'bg-gray-800 text-white' 
                              : 'text-gray-300 hover:bg-gray-800 hover:text-white'}
                          `}
                        >
                          <item.icon
                            className={`
                              mr-3 flex-shrink-0 h-5 w-5
                              ${isActive ? 'text-gray-300' : 'text-gray-400 group-hover:text-gray-300'}
                            `}
                            aria-hidden="true"
                          />
                          {item.name}
                        </Link>
                      );
                    })}
                  </div>
                </div>
              );
            })}
          </nav>
        </div>
      </div>
    </>
  );
}
