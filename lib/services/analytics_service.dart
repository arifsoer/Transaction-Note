import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService(FirebaseAnalytics.instance);
});

class AnalyticsService {
  final FirebaseAnalytics _analytics;

  AnalyticsService(this._analytics);

  Future<void> logAddTransaction({
    required String method,
    required int totalTransactions,
  }) async {
    await _analytics.logEvent(
      name: 'add_transaction',
      parameters: {
        'method': method,
        'total_transactions': totalTransactions,
      },
    );
  }

  Future<void> logCategoryAction({
    required String action,
    required bool hasBudgetSetup,
  }) async {
    await _analytics.logEvent(
      name: 'category_action',
      parameters: {
        'action': action,
        'has_budget_setup': hasBudgetSetup.toString(),
      },
    );
  }

  Future<void> logDeleteTransaction({required String transactionType}) async {
    await _analytics.logEvent(
      name: 'delete_transaction',
      parameters: {
        'type': transactionType,
      },
    );
  }

  Future<void> logCategoryTap({required String categoryName, required String type}) async {
    await _analytics.logEvent(
      name: 'category_tap',
      parameters: {
        'category_name': categoryName,
        'type': type,
      },
    );
  }

  Future<void> logWalletTap({required String walletName, required String type}) async {
    await _analytics.logEvent(
      name: 'wallet_tap',
      parameters: {
        'wallet_name': walletName,
        'type': type,
      },
    );
  }
}
