import { Controller, Get } from '@nestjs/common';
import { PlansService } from '../services/plans.service.js';

@Controller('billing/plans')
export class PlansController {
  constructor(private readonly plansService: PlansService) {}

  @Get()
  async getPlans() {
    const plans = await this.plansService.getActivePlans();
    
    // Filter to return only customer-safe data (no internal IDs where unnecessary, etc. but we return basic info)
    return plans.map(plan => ({
      id: plan.id,
      name: plan.name,
      slug: plan.slug,
      description: plan.description,
      monthlyPrice: plan.monthlyPrice,
      yearlyPrice: plan.yearlyPrice,
      currency: plan.currency,
      trialEligible: true, // we assume all active plans are trial eligible for now
      features: plan.features.map(f => ({ key: f.featureKey })),
      limits: plan.limits.map(l => ({ key: l.key, value: l.value })),
    }));
  }
}
