import { PrismaService } from '../../prisma.service.js';
import { AdminAuditService } from './admin-audit.service.js';
import { AdminPlanQueryDto, AdminCreatePlanDto, AdminUpdatePlanDto } from '../dto/admin-plans.dto.js';
export declare class AdminPlansService {
    private readonly prisma;
    private readonly auditService;
    constructor(prisma: PrismaService, auditService: AdminAuditService);
    findAll(actorId: string, query: AdminPlanQueryDto): Promise<{
        data: ({
            features: {
                id: string;
                createdAt: Date;
                updatedAt: Date;
                enabled: boolean;
                planId: string;
                featureKey: string;
            }[];
            limits: {
                id: string;
                createdAt: Date;
                updatedAt: Date;
                planId: string;
                key: string;
                value: number;
            }[];
        } & {
            name: string;
            id: string;
            status: string;
            createdAt: Date;
            updatedAt: Date;
            slug: string;
            description: string | null;
            monthlyPrice: import("@prisma/client/runtime/library").Decimal;
            yearlyPrice: import("@prisma/client/runtime/library").Decimal;
            currency: string;
            monthlyProviderPlanId: string | null;
            yearlyProviderPlanId: string | null;
        })[];
        meta: {
            total: number;
            page: number | undefined;
            limit: number | undefined;
        };
    }>;
    findOne(actorId: string, planId: string): Promise<{
        features: {
            id: string;
            createdAt: Date;
            updatedAt: Date;
            enabled: boolean;
            planId: string;
            featureKey: string;
        }[];
        limits: {
            id: string;
            createdAt: Date;
            updatedAt: Date;
            planId: string;
            key: string;
            value: number;
        }[];
    } & {
        name: string;
        id: string;
        status: string;
        createdAt: Date;
        updatedAt: Date;
        slug: string;
        description: string | null;
        monthlyPrice: import("@prisma/client/runtime/library").Decimal;
        yearlyPrice: import("@prisma/client/runtime/library").Decimal;
        currency: string;
        monthlyProviderPlanId: string | null;
        yearlyProviderPlanId: string | null;
    }>;
    createPlan(actorId: string, dto: AdminCreatePlanDto): Promise<{
        features: {
            id: string;
            createdAt: Date;
            updatedAt: Date;
            enabled: boolean;
            planId: string;
            featureKey: string;
        }[];
        limits: {
            id: string;
            createdAt: Date;
            updatedAt: Date;
            planId: string;
            key: string;
            value: number;
        }[];
    } & {
        name: string;
        id: string;
        status: string;
        createdAt: Date;
        updatedAt: Date;
        slug: string;
        description: string | null;
        monthlyPrice: import("@prisma/client/runtime/library").Decimal;
        yearlyPrice: import("@prisma/client/runtime/library").Decimal;
        currency: string;
        monthlyProviderPlanId: string | null;
        yearlyProviderPlanId: string | null;
    }>;
    updatePlan(actorId: string, planId: string, dto: AdminUpdatePlanDto): Promise<{
        features: {
            id: string;
            createdAt: Date;
            updatedAt: Date;
            enabled: boolean;
            planId: string;
            featureKey: string;
        }[];
        limits: {
            id: string;
            createdAt: Date;
            updatedAt: Date;
            planId: string;
            key: string;
            value: number;
        }[];
    } & {
        name: string;
        id: string;
        status: string;
        createdAt: Date;
        updatedAt: Date;
        slug: string;
        description: string | null;
        monthlyPrice: import("@prisma/client/runtime/library").Decimal;
        yearlyPrice: import("@prisma/client/runtime/library").Decimal;
        currency: string;
        monthlyProviderPlanId: string | null;
        yearlyProviderPlanId: string | null;
    }>;
}
