import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../features/auth/application/bootstrap_coordinator.dart';
import '../../features/auth/domain/models/auth_state.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';

import '../../features/auth/presentation/verify_email_screen.dart';
import '../../features/auth/presentation/verify_mobile_screen.dart';
import '../../features/auth/presentation/verify_identity_screen.dart';

import '../../features/billing/presentation/trial_authorization_screen.dart';
import '../../features/projects/presentation/projects_dashboard_screen.dart';

// Placeholder screen imports - these will be built out in later steps
import '../../features/mandap/presentation/mandap_editor_screen.dart';
import '../../features/projects/presentation/component_wizard_screen.dart';

class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          TextButton(
            onPressed: () => context.read<BootstrapCoordinator>().logout(),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Center(child: Text(title)),
    );
  }
}

class AppRouter {
  static GoRouter createRouter(BootstrapCoordinator coordinator) {
    return GoRouter(
      initialLocation: '/',
      refreshListenable: coordinator,
      redirect: (BuildContext context, GoRouterState state) {
        final current = coordinator.current;
        final path = state.uri.path;
        
        // 1. Initializing state -> show splash
        if (current.authState == AppAuthState.initializing || current.destination == AppDestination.loading) {
          return '/';
        }

        final isPublicRoute = path == '/login' || path == '/register';
        final isOnboardingRoute = path == '/verify-email' || 
                                  path == '/verify-mobile' || 
                                  path == '/verify-identity' || 
                                  path == '/billing/trial';

        // 2. Authentication Guard
        if (current.authState == AppAuthState.unauthenticated || current.authState == AppAuthState.authBlocked) {
          if (!isPublicRoute) {
             return '/login';
          }
          return null; // Already on login/register
        }

        // 3. Authenticated Users on Root or Public routes
        if ((isPublicRoute || path == '/') && current.authState == AppAuthState.authenticated) {
           return '/onboarding-redirect'; // We'll route them to their actual state
        }

        // 4. Verification/Onboarding Flow Routing
        if (current.authState == AppAuthState.authenticated) {
          // Force correct onboarding screen if they are on the wrong one
          if (isOnboardingRoute) {
            final expectedPath = switch (current.destination) {
               AppDestination.verifyEmail => '/verify-email',
               AppDestination.verifyMobile => '/verify-mobile',
               AppDestination.verifyIdentity => '/verify-identity',
               AppDestination.authorizeBilling => '/billing/trial',
               AppDestination.projects => '/projects',
               AppDestination.blocked => '/blocked',
               _ => '/',
            };
            if (path != expectedPath) {
              return expectedPath;
            }
          }
          // If trying to access protected App routes, Enforce Entitlement Guard
          final isAppRoute = path.startsWith('/projects') || path.startsWith('/editor') || path.startsWith('/component-wizard');

          if (current.destination != AppDestination.projects && isAppRoute) {
             // Block application access until onboarding/entitlement is complete
             return '/onboarding-redirect';
          }

          // Let them go to the specific redirect handler if they need to be routed
          if (path == '/onboarding-redirect') {
             switch (current.destination) {
               case AppDestination.verifyEmail:
                 return '/verify-email';
               case AppDestination.verifyMobile:
                 return '/verify-mobile';
               case AppDestination.verifyIdentity:
                 return '/verify-identity';
               case AppDestination.authorizeBilling:
                 return '/billing/trial';
               case AppDestination.projects:
                 return '/projects';
               case AppDestination.blocked:
                 return '/blocked';
               default:
                 return '/';
             }
          }
        }

        return null;
      },
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(body: Center(child: CircularProgressIndicator())),
        ),
        GoRoute(
          path: '/onboarding-redirect',
          builder: (context, state) => const Scaffold(body: Center(child: CircularProgressIndicator())),
        ),
        // --- Auth Routes ---
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterScreen(),
        ),
        // --- Verification Routes ---
        GoRoute(
          path: '/verify-email',
          builder: (context, state) => const VerifyEmailScreen(),
        ),
        GoRoute(
          path: '/verify-mobile',
          builder: (context, state) => const VerifyMobileScreen(),
        ),
        GoRoute(
          path: '/verify-identity',
          builder: (context, state) => const VerifyIdentityScreen(),
        ),
        // --- Billing Routes ---
        GoRoute(
          path: '/billing/trial',
          builder: (context, state) => const TrialAuthorizationScreen(),
        ),
        GoRoute(
          path: '/blocked',
          builder: (context, state) => const PlaceholderScreen(title: 'Account Blocked / Action Required'),
        ),
        // --- App Routes (Entitlement Protected) ---
        GoRoute(
          path: '/projects',
          builder: (context, state) => const ProjectsDashboardScreen(),
        ),
        GoRoute(
          path: '/editor',
          builder: (context, state) {
            final projectId = state.uri.queryParameters['projectId'] ?? 'new';
            return MandapEditorScreen(projectId: projectId);
          },
        ),
        GoRoute(
          path: '/component-wizard',
          builder: (context, state) {
            final projectId = state.uri.queryParameters['projectId'] ?? 'new';
            return ComponentWizardScreen(projectId: projectId);
          },
        ),
      ],
    );
  }
}
