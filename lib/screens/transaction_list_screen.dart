import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:transaction_note/providers/transaction_provider.dart';
import 'package:transaction_note/helper.dart';
import 'package:transaction_note/components/screens/home_screen/transaction_list.dart';
import 'package:transaction_note/theme/app_theme.dart';
import 'package:transaction_note/components/screens/home_screen/home_header.dart';
import 'package:transaction_note/providers/user_provider.dart';
import 'package:transaction_note/helper/period_helper.dart';
import 'package:transaction_note/helper/csv_helper.dart';
import 'package:transaction_note/models/transaction.dart';
import 'package:go_router/go_router.dart';

class TransactionListScreen extends ConsumerStatefulWidget {
  const TransactionListScreen({super.key});

  @override
  ConsumerState<TransactionListScreen> createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends ConsumerState<TransactionListScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsyncValue = ref.watch(transactionsStreamProvider);
    final theme = Theme.of(context);
    final customTheme = theme.extension<FuturisticThemeExtension>();
    final isDark = theme.brightness == Brightness.dark;

    final offset = ref.watch(monthOffsetProvider);
    final user = ref.watch(currentUserProvider).value;
    
    DateTimeRange? periodRange;
    if (user?.periodStartDay != null) {
      periodRange = PeriodHelper.calculatePeriod(user!.periodStartDay!, DateTime.now(), monthOffset: offset);
    }

    final displayPeriod = periodRange != null
        ? '${DateFormat('d MMMM yyyy').format(periodRange.start)} - ${DateFormat('d MMMM yyyy').format(periodRange.end)}'
        : 'Loading period...';

    List<TransactionModel>? filteredTransactions;
    if (transactionsAsyncValue.hasValue) {
      filteredTransactions = transactionsAsyncValue.value!.where((tx) {
        if (periodRange != null) {
          final startStr = "${periodRange.start.year.toString().padLeft(4, '0')}-${periodRange.start.month.toString().padLeft(2, '0')}-${periodRange.start.day.toString().padLeft(2, '0')}";
          final endStr = "${periodRange.end.year.toString().padLeft(4, '0')}-${periodRange.end.month.toString().padLeft(2, '0')}-${periodRange.end.day.toString().padLeft(2, '0')}";
          if (tx.date.compareTo(startStr) < 0 || tx.date.compareTo(endStr) > 0) {
            return false;
          }
        }

        if (_searchQuery.isNotEmpty) {
          if (!tx.note.toLowerCase().contains(_searchQuery)) {
            return false;
          }
        }

        return true;
      }).toList();

      // Sort by date descending (latest first)
      filteredTransactions.sort((a, b) {
        final dateA = DateTime.tryParse(a.date) ?? DateTime(1970);
        final dateB = DateTime.tryParse(b.date) ?? DateTime(1970);
        return dateB.compareTo(dateA);
      });
    }

    return Column(
      children: [
        // Top Header Bar
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: customTheme?.headerGradient,
            boxShadow: [
              if (isDark)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => context.pop(),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_left, color: Colors.white),
                onPressed: () {
                  ref.read(monthOffsetProvider.notifier).state--;
                },
              ),
              Expanded(
                child: Text(
                  displayPeriod,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.0,
                    fontSize: 14,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.download, color: Colors.white),
                onPressed: filteredTransactions != null && filteredTransactions.isNotEmpty
                    ? () {
                        CsvHelper.exportTransactionsToCsv(context, filteredTransactions!, displayPeriod);
                      }
                    : null,
              ),
              IconButton(
                icon: Icon(
                  Icons.chevron_right, 
                  color: offset < 0 ? Colors.white : Colors.white.withValues(alpha: 0.3),
                ),
                onPressed: offset < 0 
                    ? () {
                        ref.read(monthOffsetProvider.notifier).state++;
                      }
                    : null,
              ),
            ],
          ),
        ),
        
        // Search Bar
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by note...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value.toLowerCase();
              });
            },
          ),
        ),

        // Transaction List
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(color: theme.colorScheme.surface),
            child: transactionsAsyncValue.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
              data: (transactions) {
                final filtered = filteredTransactions ?? [];

                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      'No transactions found for this period.',
                      style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  );
                }

                // Group by date
                final groupedTransactions = groupBy(
                  filtered,
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

                return SingleChildScrollView(
                  child: Column(children: transactionList),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
