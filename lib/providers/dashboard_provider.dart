import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:transaction_note/providers/transaction_provider.dart';
import 'package:transaction_note/models/transaction.dart';
import 'package:transaction_note/providers/user_provider.dart';
import 'package:transaction_note/helper/period_helper.dart';
import 'package:transaction_note/components/screens/home_screen/home_header.dart'; // for monthOffsetProvider
import 'package:transaction_note/providers/device_settings_provider.dart'; // for activeHomeFilterProvider

class DashboardTotals {
  final double income;
  final double expense;

  const DashboardTotals({this.income = 0, this.expense = 0});
}

final dashboardTotalsProvider = Provider<AsyncValue<DashboardTotals>>((ref) {
  final userAsync = ref.watch(currentUserStreamProvider);
  if (userAsync.value == null || userAsync.value!.periodStartDay == null) {
    return const AsyncValue.data(DashboardTotals());
  }

  final offset = ref.watch(monthOffsetProvider);
  final activeFilter = ref.watch(activeHomeFilterProvider);
  final transactionsAsync = ref.watch(transactionsStreamProvider);

  final periodRange = PeriodHelper.calculatePeriod(
    userAsync.value!.periodStartDay!,
    DateTime.now(),
    monthOffset: offset,
  );

  return transactionsAsync.whenData((transactions) {
    double totalIncome = 0.0;
    double totalExpense = 0.0;

    final String startStr = "${periodRange.start.year.toString().padLeft(4, '0')}-${periodRange.start.month.toString().padLeft(2, '0')}-${periodRange.start.day.toString().padLeft(2, '0')}";
    final String endStr = "${periodRange.end.year.toString().padLeft(4, '0')}-${periodRange.end.month.toString().padLeft(2, '0')}-${periodRange.end.day.toString().padLeft(2, '0')}";

    for (var tx in transactions) {
      if (activeFilter != null && activeFilter.isNotEmpty && tx.walletId != activeFilter) {
        continue;
      }
      if (tx.date.compareTo(startStr) >= 0 && tx.date.compareTo(endStr) <= 0) {
        if (tx.type == TransactionType.income) {
          totalIncome += tx.amount;
        } else if (tx.type == TransactionType.expense) {
          totalExpense += tx.amount;
        }
      }
    }

    return DashboardTotals(income: totalIncome, expense: totalExpense);
  });
});
