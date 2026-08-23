import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:transaction_note/models/transaction.dart';
import 'package:transaction_note/models/category.dart';
import 'package:transaction_note/providers/transaction_provider.dart';
import 'package:transaction_note/providers/category_provider.dart';
import 'package:transaction_note/providers/user_provider.dart';
import 'package:transaction_note/helper/period_helper.dart';
import 'package:transaction_note/helper.dart';
import 'package:transaction_note/components/charts/pie_chart_widget.dart';
import 'package:transaction_note/components/charts/budget_progress_bar.dart';
import 'package:transaction_note/services/analytics_service.dart';

class ReportScreen extends ConsumerStatefulWidget {
  const ReportScreen({super.key});

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen> {
  int _monthOffset = 0;

  final List<Color> _chartColors = [
    Colors.blueAccent,
    Colors.redAccent,
    Colors.greenAccent,
    Colors.orangeAccent,
    Colors.purpleAccent,
    Colors.cyanAccent,
    Colors.pinkAccent,
    Colors.amberAccent,
    Colors.tealAccent,
    Colors.limeAccent,
  ];

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserStreamProvider);
    final transactionsAsync = ref.watch(transactionsStreamProvider);
    final categoriesAsync = ref.watch(categoriesStreamProvider);

    return Scaffold(
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            return const Center(child: Text('User not found.'));
          }

          final int startDay = user.periodStartDay ?? 1;
          final periodRange = PeriodHelper.calculatePeriod(
            startDay,
            DateTime.now(),
            monthOffset: _monthOffset,
          );

          final dateFormat = DateFormat('MMM dd, yyyy');
          final periodText =
              '${dateFormat.format(periodRange.start)} - ${dateFormat.format(periodRange.end)}';

          return Column(
            children: [
              _buildPeriodSelector(periodText),
              Expanded(
                child: DefaultTabController(
                  length: 2,
                  child: Column(
                    children: [
                      const TabBar(
                        tabs: [
                          Tab(text: 'Expense'),
                          Tab(text: 'Income'),
                        ],
                      ),
                      Expanded(
                        child: transactionsAsync.when(
                          data: (allTransactions) {
                            // Filter transactions by period
                            final String startStr = _formatDateString(
                              periodRange.start,
                            );
                            final String endStr = _formatDateString(
                              periodRange.end,
                            );

                            final periodTransactions = allTransactions.where((
                              tx,
                            ) {
                              return tx.date.compareTo(startStr) >= 0 &&
                                  tx.date.compareTo(endStr) <= 0;
                            }).toList();

                            return categoriesAsync.when(
                              data: (allCategories) {
                                return TabBarView(
                                  children: [
                                    _buildExpenseTab(
                                      periodTransactions,
                                      allCategories,
                                      periodRange,
                                    ),
                                    _buildIncomeTab(
                                      periodTransactions,
                                      allCategories,
                                      periodRange,
                                    ),
                                  ],
                                );
                              },
                              loading: () => const Center(
                                child: CircularProgressIndicator(),
                              ),
                              error: (e, st) => Center(
                                child: Text('Error loading categories: $e'),
                              ),
                            );
                          },
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                          error: (e, st) => Center(
                            child: Text('Error loading transactions: $e'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildPeriodSelector(String periodText) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              setState(() {
                _monthOffset -= 1;
              });
            },
          ),
          Text(
            periodText,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              setState(() {
                _monthOffset += 1;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseTab(
    List<TransactionModel> transactions,
    List<CategoryModel> categories,
    DateTimeRange periodRange,
  ) {
    final expenses = transactions
        .where((t) => t.type == TransactionType.expense)
        .toList();

    // Group by category
    final Map<String, double> categorySums = {};
    for (var tx in expenses) {
      categorySums[tx.categoryName] =
          (categorySums[tx.categoryName] ?? 0) + tx.amount;
    }

    final categoryList = categorySums.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    List<PieChartDataModel> categoryPieData = [];
    double othersSum = 0;

    for (int i = 0; i < categoryList.length; i++) {
      if (i < 5) {
        categoryPieData.add(
          PieChartDataModel(
            label: categoryList[i].key,
            value: categoryList[i].value,
            color: _chartColors[i % _chartColors.length],
          ),
        );
      } else {
        othersSum += categoryList[i].value;
      }
    }

    if (othersSum > 0) {
      categoryPieData.add(
        PieChartDataModel(
          label: 'Others',
          value: othersSum,
          color: Colors.grey,
        ),
      );
    }

    // Group by wallet
    final Map<String, double> walletSums = {};
    for (var tx in expenses) {
      final wName = tx.walletName ?? 'Unassigned';
      walletSums[wName] = (walletSums[wName] ?? 0) + tx.amount;
    }

    final walletPieData = walletSums.entries.toList().asMap().entries.map((
      entry,
    ) {
      return PieChartDataModel(
        label: entry.value.key,
        value: entry.value.value,
        color:
            _chartColors[(entry.key + 5) %
                _chartColors.length], // Offset colors
      );
    }).toList();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Expenses by Category',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          CustomPieChartWidget(data: categoryPieData),

          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Expenses by Wallet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          CustomPieChartWidget(
            data: walletPieData,
            onSectionTap: (data) {
              ref.read(analyticsServiceProvider).logWalletTap(
                walletName: data.label,
                type: 'expense',
              );
              context.push(
                '/report/wallet-transactions',
                extra: {'walletName': data.label, 'periodRange': periodRange},
              );
            },
          ),

          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Budget Progress',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ...(() {
            final expenseCategories = categories
                .where((c) => c.type == TransactionType.expense)
                .toList();
            expenseCategories.sort((a, b) {
              final spentA = categorySums[a.name] ?? 0.0;
              final spentB = categorySums[b.name] ?? 0.0;
              
              if (spentA == 0 && spentB == 0) return 0;
              if (spentA == 0) return 1;
              if (spentB == 0) return -1;

              final isOverBudgetA = a.budget > 0 ? spentA > a.budget : spentA > 0;
              final isOverBudgetB = b.budget > 0 ? spentB > b.budget : spentB > 0;

              if (isOverBudgetA && !isOverBudgetB) return -1;
              if (!isOverBudgetA && isOverBudgetB) return 1;

              if (isOverBudgetA && isOverBudgetB) {
                // Both over budget, sort by higher absolute expense first
                return spentB.compareTo(spentA);
              }
              
              // Both under budget, sort by percentage consumed
              final percentageA = a.budget > 0 ? (spentA / a.budget) : 0.0;
              final percentageB = b.budget > 0 ? (spentB / b.budget) : 0.0;
              
              return percentageB.compareTo(percentageA);
            });
            
            return expenseCategories.map((cat) {
              final spent = categorySums[cat.name] ?? 0.0;
              return BudgetProgressBar(
                categoryName: cat.name,
                iconName: cat.iconName,
                expenseAmount: spent,
                budgetAmount: cat.budget,
                onTap: () {
                  ref.read(analyticsServiceProvider).logCategoryTap(
                    categoryName: cat.name,
                    type: 'expense',
                  );
                  context.push(
                    '/report/category-transactions',
                    extra: {'category': cat, 'periodRange': periodRange},
                  );
                },
              );
            });
          })(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildIncomeTab(
    List<TransactionModel> transactions,
    List<CategoryModel> categories,
    DateTimeRange periodRange,
  ) {
    final incomes = transactions
        .where((t) => t.type == TransactionType.income)
        .toList();

    // Group by category
    final Map<String, double> categorySums = {};
    for (var tx in incomes) {
      categorySums[tx.categoryName] =
          (categorySums[tx.categoryName] ?? 0) + tx.amount;
    }

    final categoryPieData = categorySums.entries.toList().asMap().entries.map((
      entry,
    ) {
      return PieChartDataModel(
        label: entry.value.key,
        value: entry.value.value,
        color: _chartColors[entry.key % _chartColors.length],
      );
    }).toList();

    // Group by wallet
    final Map<String, double> walletSums = {};
    for (var tx in incomes) {
      final wName = tx.walletName ?? 'Unassigned';
      walletSums[wName] = (walletSums[wName] ?? 0) + tx.amount;
    }

    final walletPieData = walletSums.entries.toList().asMap().entries.map((
      entry,
    ) {
      return PieChartDataModel(
        label: entry.value.key,
        value: entry.value.value,
        color:
            _chartColors[(entry.key + 3) %
                _chartColors.length], // Offset colors
      );
    }).toList();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Income by Category',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          CustomPieChartWidget(data: categoryPieData),

          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Income by Wallet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          CustomPieChartWidget(
            data: walletPieData,
            onSectionTap: (data) {
              ref.read(analyticsServiceProvider).logWalletTap(
                walletName: data.label,
                type: 'income',
              );
              context.push(
                '/report/wallet-transactions',
                extra: {'walletName': data.label, 'periodRange': periodRange},
              );
            },
          ),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Income Categories',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ...categories.where((c) => c.type == TransactionType.income).map((
            cat,
          ) {
            final earned = categorySums[cat.name] ?? 0.0;
            return ListTile(
              leading: Icon(getIconFromName(cat.iconName)),
              title: Text(cat.name),
              trailing: Text(
                '+${formatRupiah(earned)}',
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () {
                ref.read(analyticsServiceProvider).logCategoryTap(
                  categoryName: cat.name,
                  type: 'income',
                );
                context.push(
                  '/report/category-transactions',
                  extra: {'category': cat, 'periodRange': periodRange},
                );
              },
            );
          }),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  String _formatDateString(DateTime date) {
    return "${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }
}
