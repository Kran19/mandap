import { PlansService } from '../services/plans.service.js';
export declare class PlansController {
    private readonly plansService;
    constructor(plansService: PlansService);
    getPlans(): Promise<{
        id: string;
        name: string;
        slug: string;
        description: string | null;
        monthlyPrice: import("@prisma/client/runtime/library").Decimal;
        yearlyPrice: import("@prisma/client/runtime/library").Decimal;
        currency: string;
        trialEligible: boolean;
        features: {
            key: string;
        }[];
        limits: {
            key: string;
            value: number;
        }[];
    }[]>;
}
