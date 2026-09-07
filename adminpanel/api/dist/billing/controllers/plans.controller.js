var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
import { Controller, Get } from '@nestjs/common';
import { PlansService } from '../services/plans.service.js';
let PlansController = class PlansController {
    plansService;
    constructor(plansService) {
        this.plansService = plansService;
    }
    async getPlans() {
        const plans = await this.plansService.getActivePlans();
        return plans.map(plan => ({
            id: plan.id,
            name: plan.name,
            slug: plan.slug,
            description: plan.description,
            monthlyPrice: plan.monthlyPrice,
            yearlyPrice: plan.yearlyPrice,
            currency: plan.currency,
            trialEligible: true,
            features: plan.features.map(f => ({ key: f.featureKey })),
            limits: plan.limits.map(l => ({ key: l.key, value: l.value })),
        }));
    }
};
__decorate([
    Get(),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", Promise)
], PlansController.prototype, "getPlans", null);
PlansController = __decorate([
    Controller('billing/plans'),
    __metadata("design:paramtypes", [PlansService])
], PlansController);
export { PlansController };
//# sourceMappingURL=plans.controller.js.map