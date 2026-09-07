enum AppAuthState {
  initializing,
  unauthenticated,
  authenticated,
  refreshing,
  authBlocked
}

enum OnboardingState {
  complete,
  emailVerificationRequired,
  mobileVerificationRequired,
  identityVerificationRequired,
  billingAuthorizationRequired,
  trialEstablishmentPending,
  billingActionRequired,
  blocked
}

enum AppDestination {
  login,
  register,
  verifyEmail,
  verifyMobile,
  verifyIdentity,
  authorizeBilling,
  projects,
  blocked,
  loading
}
