import { PrismaService } from '../../prisma.service.js';
export declare class PlansService {
    private prisma;
    constructor(prisma: PrismaService);
    getActivePlans(): Promise<({
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
        id: string;
        status: string;
        createdAt: Date;
        updatedAt: Date;
        name: string;
        slug: string;
        description: string | null;
        monthlyPrice: import("@prisma/client/runtime/library").Decimal;
        yearlyPrice: import("@prisma/client/runtime/library").Decimal;
        currency: string;
        monthlyProviderPlanId: string | null;
        yearlyProviderPlanId: string | null;
    })[]>;
    getPlanBySlug(slug: string): Promise<{
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
        id: string;
        status: string;
        createdAt: Date;
        updatedAt: Date;
        name: string;
        slug: string;
        description: string | null;
        monthlyPrice: import("@prisma/client/runtime/library").Decimal;
        yearlyPrice: import("@prisma/client/runtime/library").Decimal;
        currency: string;
        monthlyProviderPlanId: string | null;
        yearlyProviderPlanId: string | null;
    }>;
}
