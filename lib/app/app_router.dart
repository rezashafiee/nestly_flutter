import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../features/account/presentation/account_screen.dart';
import '../features/auth/presentation/auth_screen.dart';
import '../features/auth/state/auth_controller.dart';
import '../features/chat/presentation/chat_screen.dart';
import '../features/marketplace/presentation/marketplace_screen.dart';
import '../features/sell/data/photo_repository.dart';
import '../features/sell/presentation/sell_screen.dart';
import '../features/sell/state/sell_controller.dart';
import '../features/shell/presentation/main_shell.dart';
import '../features/splash/presentation/splash_screen.dart';
import '../features/marketplace/state/marketplace_controller.dart';
import 'app_controller.dart';

abstract final class AppRoutes {
  static const splash = '/splash';
  static const auth = '/auth';
  static const buy = '/buy';
  static const sell = '/sell';
  static const chat = '/chat';
  static const account = '/account';
}

GoRouter createAppRouter({
  required AppController appController,
  required AuthController authController,
  required Listenable refreshListenable,
}) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: refreshListenable,
    redirect: (context, state) {
      final location = state.uri.path;
      if (!appController.splashComplete) {
        return location == AppRoutes.splash ? null : AppRoutes.splash;
      }
      if (!authController.isAuthenticated) {
        return location == AppRoutes.auth ? null : AppRoutes.auth;
      }
      if (location == AppRoutes.splash ||
          location == AppRoutes.auth ||
          location == '/') {
        return AppRoutes.buy;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: SplashScreen()),
      ),
      GoRoute(
        path: AppRoutes.auth,
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: AuthScreen()),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return MainShell(location: state.uri.path, child: child);
        },
        routes: [
          GoRoute(
            path: AppRoutes.buy,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: MarketplaceScreen()),
          ),
          GoRoute(
            path: AppRoutes.sell,
            pageBuilder: (context, state) {
              return NoTransitionPage(
                child: ChangeNotifierProvider(
                  create: (context) => SellController(
                    context.read<PhotoRepository>(),
                    context.read<MarketplaceController>(),
                  ),
                  child: const SellScreen(),
                ),
              );
            },
          ),
          GoRoute(
            path: AppRoutes.chat,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ChatScreen()),
          ),
          GoRoute(
            path: AppRoutes.account,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: AccountScreen()),
          ),
        ],
      ),
    ],
  );
}
