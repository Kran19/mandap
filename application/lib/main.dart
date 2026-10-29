import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';

import 'core/router/app_router.dart';
import 'core/localization/locale_notifier.dart';
import 'features/auth/application/bootstrap_coordinator.dart';
import 'features/auth/infrastructure/auth_repository.dart';
import 'features/billing/infrastructure/billing_repository.dart';
import 'features/projects/infrastructure/projects_repository.dart';
import 'core/network/api_client.dart';
import 'features/projects/infrastructure/project_version_repository.dart';

import 'package:flutter/foundation.dart';

// API URL - Automatically points to localhost:3001 when running in Chrome Web, and remote server on mobile
String get apiBaseUrl {
  if (kIsWeb) {
    return 'http://localhost:3001/api/v1';
  }
  return const String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://mandapbuilder.vardaansmartsolutions.com/api/v1',
  );
}

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
          create: (_) => AuthRepository(baseUrl: apiBaseUrl),
        ),
        ProxyProvider<AuthRepository, BillingRepository>(
          update: (_, auth, __) => BillingRepository(
            baseUrl: apiBaseUrl,
            tokenProvider: auth,
          ),
        ),
        ProxyProvider<AuthRepository, ProjectsRepository>(
          update: (_, auth, __) => ProjectsRepository(
            baseUrl: apiBaseUrl,
            tokenProvider: auth,
          ),
        ),
        ProxyProvider<AuthRepository, ApiClient>(
          update: (_, auth, __) => ApiClient(
            baseUrl: apiBaseUrl,
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
        ChangeNotifierProvider<LocaleNotifier>(
          create: (_) => LocaleNotifier(),
        ),
      ],
      child: Builder(
        builder: (context) {
          final coordinator = context.read<BootstrapCoordinator>();
          final router = AppRouter.createRouter(coordinator);
          
          return MaterialApp.router(
            title: 'Mandap Builder',
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
            locale: context.watch<LocaleNotifier>().locale,
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en'),
              Locale('hi'),
              Locale('gu'),
              Locale('ta'),
              Locale('te'),
              Locale('mr'),
              Locale('bn'),
            ],
            localeResolutionCallback: (locale, supportedLocales) {
              if (locale != null) {
                for (final supportedLocale in supportedLocales) {
                  if (supportedLocale.languageCode == locale.languageCode) {
                    return supportedLocale;
                  }
                }
              }
              return const Locale('en');
            },
          );
        }
      ),
    );
  }
}
