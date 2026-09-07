import { AdminPermissions } from '../constants/admin-permissions.js';
export declare class AdminPermissionsController {
    findAll(): {
        action: AdminPermissions;
    }[];
    findOne(action: string): {
        action: string;
    } | null;
}
