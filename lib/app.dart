import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_track/core/constants/app_theme.dart';
import 'package:task_track/core/providers/locale_provider.dart';
import 'package:task_track/features/auth/presentation/email_verification_screen.dart';
import 'package:task_track/features/auth/presentation/login_screen.dart';
import 'package:task_track/features/auth/providers/auth_provider.dart';
import 'package:task_track/features/navigation/presentation/main_navigation_screen.dart';
import 'package:task_track/features/profile/presentation/profile_setup_screen.dart';
import 'package:task_track/features/profile/providers/profile_provider.dart';
import 'package:task_track/shared/widgets/ambient_background.dart';
import 'package:task_track/shared/widgets/loading_view.dart';
import 'package:task_track/shared/widgets/error_view.dart';

class App extends ConsumerWidget {
  const App({super.key, this.navigatorKey});

  final GlobalKey<NavigatorState>? navigatorKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final authState = ref.watch(authStateProvider);

    return MaterialApp(
      title: 'Takumi',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      theme: AppTheme.darkTheme,
      locale: locale,
      supportedLocales: const [Locale('id'), Locale('en')],
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: authState.when(
        data: (user) {
          if (user == null) return const LoginScreen();
          if (!user.emailVerified) {
            return const EmailVerificationScreen();
          }
          return ref
              .watch(profileGateProvider)
              .when(
                data: (profile) => profile.setupComplete
                    ? const MainNavigationScreen()
                    : ProfileSetupScreen(initialProfile: profile),
                loading: () => const _GateScaffold(child: LoadingView()),
                error: (_, _) => _GateScaffold(
                  child: ErrorView(
                    onRetry: () => ref.invalidate(profileGateProvider),
                  ),
                ),
              );
        },
        loading: () => const _GateScaffold(
          style: AmbientBackgroundStyle.auth,
          child: LoadingView(),
        ),
        error: (_, _) => _GateScaffold(
          style: AmbientBackgroundStyle.auth,
          child: ErrorView(onRetry: () => ref.invalidate(authStateProvider)),
        ),
      ),
    );
  }
}

class _GateScaffold extends StatelessWidget {
  const _GateScaffold({
    required this.child,
    this.style = AmbientBackgroundStyle.standard,
  });

  final Widget child;
  final AmbientBackgroundStyle style;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(child: AmbientBackground(style: style)),
          SafeArea(child: child),
        ],
      ),
    );
  }
}
