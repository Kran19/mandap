import { AdminPlansService } from '../services/admin-plans.service.js';
import { AdminPlanQueryDto, AdminCreatePlanDto, AdminUpdatePlanDto } from '../dto/admin-plans.dto.js';
export declare class AdminPlansController {
    private readonly plansService;
    constructor(plansService: AdminPlansService);
    findAll(actor: any, query: AdminPlanQueryDto): Promise<{
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
    findOne(actor: any, id: string): Promise<{
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
    createPlan(actor: any, dto: AdminCreatePlanDto): Promise<{
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
    updatePlan(actor: any, id: string, dto: AdminUpdatePlanDto): Promise<{
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
