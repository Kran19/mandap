class EntitlementResult {
  final bool applicationAccess;
  final String? subscriptionStatus;
  final String? planId;
  final String? currentPeriodEndsAt;
  final String? reason;

  const EntitlementResult({
    required this.applicationAccess,
    this.subscriptionStatus,
    this.planId,
    this.currentPeriodEndsAt,
    this.reason,
  });

  factory EntitlementResult.fromJson(Map<String, dynamic> json) {
    return EntitlementResult(
      applicationAccess: json['applicationAccess'] as bool? ?? false,
      subscriptionStatus: json['subscriptionStatus'] as String?,
      planId: json['planId'] as String?,
      currentPeriodEndsAt: json['currentPeriodEndsAt'] as String?,
      reason: json['reason'] as String?,
    );
  }
}
