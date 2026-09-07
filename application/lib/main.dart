import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/router/app_router.dart';
import 'features/auth/application/bootstrap_coordinator.dart';
import 'features/auth/infrastructure/auth_repository.dart';
import 'features/billing/infrastructure/billing_repository.dart';
import 'features/projects/infrastructure/projects_repository.dart';
import 'core/network/api_client.dart';
import 'features/projects/infrastructure/project_version_repository.dart';

// Change this to your computer's local IP (found via ipconfig)
// Your phone and computer must be on the same WiFi network.
const String _kApiBaseUrl = 'http://192.168.1.6:3001/api/v1';

void main() {
  runApp(const MandapApp());
}

class MandapApp extends StatelessWidget {
  const MandapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthRepository>(
          create: (_) => AuthRepository(baseUrl: _kApiBaseUrl),
        ),
        ProxyProvider<AuthRepository, BillingRepository>(
          update: (_, auth, __) => BillingRepository(
            baseUrl: _kApiBaseUrl,
            tokenProvider: auth,
          ),
        ),
        ProxyProvider<AuthRepository, ProjectsRepository>(
          update: (_, auth, __) => ProjectsRepository(
            baseUrl: _kApiBaseUrl,
            tokenProvider: auth,
          ),
        ),
        ProxyProvider<AuthRepository, ApiClient>(
          update: (_, auth, __) => ApiClient(
            baseUrl: _kApiBaseUrl,
            tokenProvider: auth,
          ),
        ),
        ProxyProvider<ApiClient, ProjectVersionRepository>(
          update: (_, client, __) => ProjectVersionRepository(
            apiClient: client,
          ),
        ),
        ChangeNotifierProvider<BootstrapCoordinator>(
          create: (context) {
            final coordinator = BootstrapCoordinator(
              authRepository: context.read<AuthRepository>(),
              billingRepository: context.read<BillingRepository>(),
            );
            coordinator.bootstrap();
            return coordinator;
          },
        ),
      ],
      child: Builder(
        builder: (context) {
          final coordinator = context.read<BootstrapCoordinator>();
          final router = AppRouter.createRouter(coordinator);
          
          return MaterialApp.router(
            title: 'MANDAP — Mandap Truss Calculator',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              brightness: Brightness.dark,
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF0F172A),
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
            ),
            routerConfig: router,
          );
        }
      ),
    );
  }
}
