import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:transaction_note/helper.dart';
import 'package:transaction_note/models/transaction.dart';
import 'package:transaction_note/providers/category_provider.dart';
import 'package:transaction_note/providers/transaction_provider.dart';
import 'package:transaction_note/providers/device_settings_provider.dart';
import 'package:transaction_note/providers/auth_provider.dart';
import 'package:transaction_note/services/analytics_service.dart';

class TransactionListHomeScreen extends ConsumerWidget {
  const TransactionListHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsyncValue = ref.watch(transactionsStreamProvider);

    return transactionsAsyncValue.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
      data: (allTransactions) {
        final activeFilter = ref.watch(activeHomeFilterProvider);

        final today = DateTime.now();
        final yesterday = today.subtract(const Duration(days: 1));
        final todayStr =
            "${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
        final yesterdayStr =
            "${yesterday.year.toString().padLeft(4, '0')}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}";

        final transactions = allTransactions.where((t) {
          if (activeFilter != null && t.walletId != activeFilter) {
            return false;
          }
          if (t.date != todayStr && t.date != yesterdayStr) {
            return false;
          }
          return true;
        }).toList();

        // Sort descending
        transactions.sort((a, b) {
          final dateA = DateTime.tryParse(a.date) ?? DateTime(1970);
          final dateB = DateTime.tryParse(b.date) ?? DateTime(1970);
          return dateB.compareTo(dateA);
        });

        if (transactions.isEmpty) {
          return const Center(child: Text('No transactions yet for Today or Yesterday.'));
        }

        final groupedTransactions = groupBy(
          transactions,
          (transaction) => transaction.date,
        );

        List<Widget> transactionList = [];

        for (var entry in groupedTransactions.entries) {
          transactionList.add(DateItem(dateTime: entry.key, transactions: entry.value));
          transactionList.addAll(
            entry.value.map(
              (transaction) => TransactionItem(transactionModel: transaction),
            ),
          );
        }

        return SingleChildScrollView(child: Column(children: transactionList));
      },
    );
  }
}

class TransactionItem extends ConsumerWidget {
  const TransactionItem({super.key, required this.transactionModel});

  final TransactionModel transactionModel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    String iconName = 'label';
    final categoriesAsync = ref.watch(categoriesStreamProvider);
    categoriesAsync.whenData((categories) {
      try {
        final cat = categories.firstWhere(
          (c) => c.id == transactionModel.categoryId,
        );
        iconName = cat.iconName;
      } catch (_) {}
    });

    final typeColor = transactionModel.type == TransactionType.income
        ? Colors.green
        : Colors.red;

    return Dismissible(
      key: ValueKey(transactionModel.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text("Confirm Delete"),
              content: const Text("Are you sure you want to delete this transaction?"),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text("CANCEL"),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text("DELETE", style: TextStyle(color: Colors.red)),
                ),
              ],
            );
          },
        );
      },
      onDismissed: (direction) async {
        final user = ref.read(authStateProvider).value;
        if (user != null && transactionModel.id != null) {
          final service = ref.read(transactionServiceProvider);
          await service.deleteTransaction(user.uid, transactionModel.id!);

          ref.read(analyticsServiceProvider).logDeleteTransaction(
                transactionType: transactionModel.type.name,
              );

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Transaction deleted')),
            );
          }
        }
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isDark
                  ? const Color(0xFF333852).withValues(alpha: 0.3)
                  : Colors.blueGrey.shade100,
            ),
          ),
        ),
        child: InkWell(
          onTap: () {
            context.push('/transactions/form', extra: transactionModel);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(getIconFromName(iconName), size: 40, color: typeColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transactionModel.note.isNotEmpty
                            ? transactionModel.note
                            : transactionModel.categoryName,
                        style: theme.textTheme.bodyLarge!.copyWith(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (transactionModel.note.isNotEmpty ||
                          transactionModel.walletName != null)
                        Text(
                          transactionModel.note.isNotEmpty
                              ? transactionModel.categoryName +
                                    (transactionModel.walletName != null
                                        ? ' • ${transactionModel.walletName}'
                                        : '')
                              : transactionModel.walletName!,
                          style: theme.textTheme.bodySmall!.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      transactionModel.type == TransactionType.income ? '+' : '-',
                      style: theme.textTheme.bodyLarge!.copyWith(
                        color: typeColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      formatRupiah(transactionModel.amount),
                      style: theme.textTheme.bodyLarge!.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DateItem extends StatelessWidget {
  const DateItem({super.key, required this.dateTime, required this.transactions});

  final String dateTime;
  final List<TransactionModel> transactions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    double income = 0;
    double expense = 0;
    for (var tx in transactions) {
      if (tx.type == TransactionType.income) {
        income += tx.amount;
      } else if (tx.type == TransactionType.expense) {
        expense += tx.amount;
      }
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E2235).withValues(alpha: 0.5)
            : Colors.blueGrey.shade50,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Text(
              dateTime,
              style: theme.textTheme.titleSmall!.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.bold,
                fontSize: 11,
                letterSpacing: 1.0,
              ),
            ),
          ),
          if (income > 0 || expense > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (income > 0)
                    Text(
                      '+${formatRupiah(income)}',
                      style: theme.textTheme.titleSmall!.copyWith(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  if (income > 0 && expense > 0) const SizedBox(width: 8),
                  if (expense > 0)
                    Text(
                      '-${formatRupiah(expense)}',
                      style: theme.textTheme.titleSmall!.copyWith(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
