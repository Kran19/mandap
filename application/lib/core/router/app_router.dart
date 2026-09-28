import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../theme/app_theme.dart';
import '../../l10n/app_localizations.dart';

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
import '../../features/mandap/presentation/wizard/truss_configuration_wizard_screen.dart';
import '../../features/module_selection/presentation/module_selection_screen.dart';
import '../../features/projects/presentation/component_wizard_screen.dart';
import '../../features/pole/presentation/pole_calculator_screen.dart';
import '../../features/stage/presentation/stage_calculator_screen.dart';
import '../../features/flooring/presentation/flooring_calculator_screen.dart';
import '../../features/truss_boundary/presentation/truss_boundary_planner_screen.dart';

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
               AppDestination.projects => '/editor',
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
                 return '/modules';
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
        // --- Module Selection & Wizard ---
        GoRoute(
          path: '/modules',
          builder: (context, state) => const ModuleSelectionScreen(),
          onExit: (context) async {
            final l10n = AppLocalizations.of(context);
            final shouldExit = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: const Color(0xFF1E293B),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Color(0xFF334155), width: 1),
                ),
                title: Text(
                  l10n?.exitApp ?? 'Exit MANDAP?',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
                content: Text(
                  l10n?.confirmExit ?? 'Are you sure you want to exit the application?',
                  style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 14),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: Text(
                      l10n?.cancel ?? 'Cancel',
                      style: const TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.trussPrimary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: Text(l10n?.exit ?? 'Exit'),
                  ),
                ],
              ),
            );
            if (shouldExit == true) {
              SystemNavigator.pop();
            }
            return shouldExit ?? false;
          },
        ),
        GoRoute(
          path: '/truss-wizard',
          builder: (context, state) {
            final projectId = state.uri.queryParameters['projectId'];
            return TrussConfigurationWizardScreen(existingProjectId: projectId);
          },
        ),
        GoRoute(
          path: '/truss-planner',
          builder: (context, state) {
            final projectId = state.uri.queryParameters['projectId'];
            final trussSizeStr = state.uri.queryParameters['trussSize'];
            final widthStr = state.uri.queryParameters['width'];
            final lengthStr = state.uri.queryParameters['length'];
            final trussSize = trussSizeStr != null ? double.tryParse(trussSizeStr) : null;
            final width = widthStr != null ? double.tryParse(widthStr) : null;
            final length = lengthStr != null ? double.tryParse(lengthStr) : null;
            return MandapEditorScreen(
              projectId: projectId ?? 'new',
              initialTrussSize: trussSize,
              initialPlotWidth: width,
              initialPlotLength: length,
            );
          },
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
            final trussSizeStr = state.uri.queryParameters['trussSize'];
            final calcSizeStr = state.uri.queryParameters['calcSize'];
            final widthStr = state.uri.queryParameters['width'];
            final lengthStr = state.uri.queryParameters['length'];
            final trussSize = trussSizeStr != null ? double.tryParse(trussSizeStr) : null;
            final calcSize = calcSizeStr != null ? double.tryParse(calcSizeStr) : null;
            final width = widthStr != null ? double.tryParse(widthStr) : null;
            final length = lengthStr != null ? double.tryParse(lengthStr) : null;
            return MandapEditorScreen(
              projectId: projectId ?? 'new',
              initialTrussSize: trussSize,
              initialCalculationUnitSize: calcSize,
              initialPlotWidth: width,
              initialPlotLength: length,
            );
          },
        ),
        GoRoute(
          path: '/component-wizard',
          builder: (context, state) {
            final projectId = state.uri.queryParameters['projectId'] ?? 'new';
            return ComponentWizardScreen(projectId: projectId);
          },
        ),
        GoRoute(
          path: '/pole',
          builder: (context, state) {
            final projectId = state.uri.queryParameters['projectId'];
            final len = double.tryParse(state.uri.queryParameters['length'] ?? '');
            final wid = double.tryParse(state.uri.queryParameters['width'] ?? '');
            final pipe = double.tryParse(state.uri.queryParameters['pipeSize'] ?? '');
            return PoleCalculatorScreen(
              projectId: projectId ?? 'new',
              initialLength: len,
              initialWidth: wid,
              initialPipeSize: pipe,
            );
          },
        ),
        GoRoute(
          path: '/stage',
          builder: (context, state) {
            final projectId = state.uri.queryParameters['projectId'];
            final len = double.tryParse(state.uri.queryParameters['length'] ?? '');
            final wid = double.tryParse(state.uri.queryParameters['width'] ?? '');
            final tl = double.tryParse(state.uri.queryParameters['tableLength'] ?? '');
            final tw = double.tryParse(state.uri.queryParameters['tableWidth'] ?? '');
            return StageCalculatorScreen(
              projectId: projectId ?? 'new',
              initialLength: len,
              initialWidth: wid,
              initialTableLength: tl,
              initialTableWidth: tw,
            );
          },
        ),
        GoRoute(
          path: '/flooring',
          builder: (context, state) {
            final projectId = state.uri.queryParameters['projectId'];
            final len = double.tryParse(state.uri.queryParameters['length'] ?? '');
            final wid = double.tryParse(state.uri.queryParameters['width'] ?? '');
            final cl = double.tryParse(state.uri.queryParameters['carpetLength'] ?? '');
            final cw = double.tryParse(state.uri.queryParameters['carpetWidth'] ?? '');
            return FlooringCalculatorScreen(
              projectId: projectId ?? 'new',
              initialLength: len,
              initialWidth: wid,
              initialCarpetLength: cl,
              initialCarpetWidth: cw,
            );
          },
        ),
      ],
    );
  }
}
