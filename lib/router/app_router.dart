import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import '../providers/auth_provider.dart';
import '../screens/login_screen.dart';
import '../screens/main_screen.dart';
import '../screens/wallets/wallet_list_screen.dart';
import '../screens/wallets/wallet_form_screen.dart';
import '../models/wallet.dart';
import '../screens/categories/category_list_screen.dart';
import '../screens/categories/category_form_screen.dart';
import '../models/category.dart';
import '../screens/transaction_form_screen.dart';
import '../models/transaction.dart';
import '../screens/category_transactions_screen.dart';
import '../screens/wallet_transactions_screen.dart';

class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
          (dynamic _) => notifyListeners(),
        );
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/',
    observers: [FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance)],
    refreshListenable: GoRouterRefreshStream(
      ref.watch(authServiceProvider).authStateChanges,
    ),
    routes: [
      GoRoute(name: 'MainScreen', path: '/', builder: (context, state) => const MainScreen()),
      GoRoute(name: 'LoginScreen', path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        name: 'WalletListScreen',
        path: '/profile/wallets',
        builder: (context, state) => const WalletListScreen(),
      ),
      GoRoute(
        name: 'WalletFormScreen',
        path: '/profile/wallets/form',
        builder: (context, state) {
          final existingWallet = state.extra as WalletModel?;
          return WalletFormScreen(existingWallet: existingWallet);
        },
      ),
      GoRoute(
        name: 'CategoryListScreen',
        path: '/profile/categories',
        builder: (context, state) => const CategoryListScreen(),
      ),
      GoRoute(
        name: 'CategoryFormScreen',
        path: '/profile/categories/form',
        builder: (context, state) {
          final existingCategory = state.extra as CategoryModel?;
          return CategoryFormScreen(existingCategory: existingCategory);
        },
      ),
      GoRoute(
        name: 'TransactionFormScreen',
        path: '/transactions/form',
        builder: (context, state) {
          final existingTransaction = state.extra as TransactionModel?;
          return TransactionFormScreen(existingTransaction: existingTransaction);
        },
      ),
      GoRoute(
        name: 'CategoryTransactionsScreen',
        path: '/report/category-transactions',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          final category = extra['category'] as CategoryModel;
          final periodRange = extra['periodRange'] as DateTimeRange;
          return CategoryTransactionsScreen(category: category, periodRange: periodRange);
        },
      ),
      GoRoute(
        name: 'WalletTransactionsScreen',
        path: '/report/wallet-transactions',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          final walletName = extra['walletName'] as String;
          final periodRange = extra['periodRange'] as DateTimeRange;
          return WalletTransactionsScreen(walletName: walletName, periodRange: periodRange);
        },
      ),
    ],
    redirect: (BuildContext context, GoRouterState state) {
      // Check auth state status
      final bool loggedIn = authState.value != null;
      final bool loggingIn = state.uri.toString() == '/login';

      // While authenticating or loading initial state, do not redirect
      if (authState.isLoading) {
        return null;
      }

      if (!loggedIn) {
        return '/login';
      }

      if (loggingIn) {
        return '/';
      }

      return null;
    },
  );
});
