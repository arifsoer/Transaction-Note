import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:transaction_note/models/transaction.dart';
import 'package:transaction_note/models/category.dart';
import 'package:transaction_note/models/wallet.dart';
import 'package:transaction_note/providers/auth_provider.dart';
import 'package:transaction_note/providers/category_provider.dart';
import 'package:transaction_note/providers/transaction_provider.dart';
import 'package:transaction_note/providers/wallet_provider.dart';
import 'package:transaction_note/providers/ai_provider.dart';
import 'package:transaction_note/providers/device_settings_provider.dart';
import 'package:transaction_note/helper.dart';
import 'package:transaction_note/theme/app_theme.dart';
import 'package:transaction_note/providers/nav_provider.dart';
import 'package:transaction_note/providers/user_provider.dart';
import 'package:transaction_note/helper/period_helper.dart';
import 'package:transaction_note/services/analytics_service.dart';

class AiForm extends ConsumerStatefulWidget {
  const AiForm({super.key});

  @override
  ConsumerState<AiForm> createState() => _AiFormState();
}

class _AiFormState extends ConsumerState<AiForm> {
  final TextEditingController _aiController = TextEditingController();
  bool _isLoading = false;
  final List<TransactionModel> _recentTransactions = [];

  @override
  void dispose() {
    _aiController.dispose();
    super.dispose();
  }

  Future<void> _parseAndSaveAiTransaction(
    String statement,
    List<CategoryModel> categories,
    List<WalletModel> wallets,
  ) async {
    setState(() => _isLoading = true);
    try {
      final aiService = ref.read(aiServiceProvider);
      final results = await aiService.parseTransaction(
        statement: statement,
        categories: categories,
        wallets: wallets,
      );

      final user = ref.read(authStateProvider).value;
      if (user == null) throw Exception('User not logged in');
      final transactionService = ref.read(transactionServiceProvider);

      List<TransactionModel> newTransactions = [];

      for (var result in results) {
        final amountString = result['amount']?.toString() ?? '0';
        final amount = double.tryParse(amountString) ?? 0.0;
        final note = result['note'] ?? '';
        final type = result['type'] == 'income'
            ? TransactionType.income
            : TransactionType.expense;
        final dateStr = result['date'] as String?;
        final date = dateStr != null
            ? (DateTime.tryParse(dateStr) ?? DateTime.now())
            : DateTime.now();
        final formattedDate = DateFormat('yyyy-MM-dd').format(date);

        CategoryModel? category;
        final categoryId = result['category_id'] as String?;
        if (categoryId != null) {
          try {
            category = categories.firstWhere((c) => c.id == categoryId);
          } catch (_) {}
        }

        WalletModel? wallet;
        final walletId = result['wallet_id'] as String?;
        if (walletId != null) {
          try {
            wallet = wallets.firstWhere((w) => w.id == walletId);
          } catch (_) {}
        }

        if (wallet == null) {
          final defaultWalletId = ref.read(defaultWalletIdProvider);
          if (defaultWalletId != null) {
            try {
              wallet = wallets.firstWhere((w) => w.id == defaultWalletId);
            } catch (_) {}
          }
        }

        if (category == null) {
          try {
            category = categories.firstWhere(
              (c) => c.name.toLowerCase() == 'other' && c.type == type,
            );
          } catch (_) {}

          if (category == null) {
            try {
              category = categories.firstWhere((c) => c.name.toLowerCase() == 'other');
            } catch (_) {}
          }

          if (category == null && categories.isNotEmpty) {
            category = categories.first;
          }

          if (category == null) continue;
        }

        final transaction = TransactionModel(
          date: formattedDate,
          amount: amount,
          note: note,
          type: type,
          categoryId: category.id,
          categoryName: category.name,
          walletId: wallet?.id,
          walletName: wallet?.name,
        );

        final id = await transactionService.addTransaction(user.uid, transaction);
        transaction.id = id;
        newTransactions.add(transaction);
      }

      if (mounted) {
        setState(() {
          _recentTransactions.addAll(newTransactions);
        });
        
        // Track the AI transaction addition
        if (newTransactions.isNotEmpty) {
          ref.read(analyticsServiceProvider).logAddTransaction(
            method: 'ai',
            totalTransactions: newTransactions.length,
          );
        }

        _aiController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved ${newTransactions.length} transactions!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('AI Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ext = theme.extension<FuturisticThemeExtension>();
    final categoriesAsync = ref.watch(categoriesStreamProvider);
    final walletsAsync = ref.watch(walletsStreamProvider);
    final transactionsAsync = ref.watch(transactionsStreamProvider);
    final userAsync = ref.watch(currentUserProvider);

    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.auto_awesome,
                  size: 60,
                  color: ext?.accentColor ?? theme.colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'AI Assist Mode',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: ext?.glowColor1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Describe your transaction naturally. For example:\n"I spent Rp 50.000 for lunch yesterday using cash"',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 32),
                if (_recentTransactions.isNotEmpty) ...[
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant.withValues(
                          alpha: 0.5,
                        ),
                      ),
                    ),
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Recently Saved',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                setState(() {
                                  _recentTransactions.clear();
                                });
                              },
                              tooltip: 'Clear recent list',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ..._recentTransactions.map((tx) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: tx.type == TransactionType.income
                                    ? Colors.green.withValues(alpha: 0.3)
                                    : Colors.red.withValues(alpha: 0.3),
                              ),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                ref.read(navigationIndexProvider.notifier).state = 1;
                                setState(() {
                                  _recentTransactions.clear();
                                });
                                context.push('/transactions/form', extra: tx);
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    Icon(
                                      tx.type == TransactionType.income
                                          ? Icons.arrow_downward
                                          : Icons.arrow_upward,
                                      color: tx.type == TransactionType.income
                                          ? Colors.green
                                          : Colors.red,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            tx.categoryName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          if (tx.note.isNotEmpty || tx.walletName != null)
                                            Text(
                                              tx.note.isNotEmpty 
                                                  ? '${tx.note}${tx.walletName != null ? ' • ${tx.walletName}' : ''}'
                                                  : tx.walletName!,
                                              style: theme.textTheme.bodySmall,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          Text(
                                            tx.date,
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              color: theme.colorScheme.onSurfaceVariant,
                                              fontSize: 10,
                                            ),
                                          ),
                                          Builder(
                                            builder: (context) {
                                              if (tx.type != TransactionType.expense) return const SizedBox.shrink();
                                              
                                              final categories = categoriesAsync.value ?? [];
                                              CategoryModel? category;
                                              try {
                                                category = categories.firstWhere((c) => c.id == tx.categoryId);
                                              } catch (_) {}
                                              
                                              if (category == null || category.budget <= 0) return const SizedBox.shrink();
                                              
                                              final allTransactions = transactionsAsync.value ?? [];
                                              final user = userAsync.value;
                                              
                                              if (user?.periodStartDay == null) return const SizedBox.shrink();
                                              
                                              final period = PeriodHelper.calculatePeriod(user!.periodStartDay!, DateTime.now());
                                              final startStr = "${period.start.year.toString().padLeft(4, '0')}-${period.start.month.toString().padLeft(2, '0')}-${period.start.day.toString().padLeft(2, '0')}";
                                              final endStr = "${period.end.year.toString().padLeft(4, '0')}-${period.end.month.toString().padLeft(2, '0')}-${period.end.day.toString().padLeft(2, '0')}";
                                              
                                              double totalSpent = 0;
                                              for (var t in allTransactions) {
                                                if (t.categoryId == category.id && t.type == TransactionType.expense) {
                                                  if (t.date.compareTo(startStr) >= 0 && t.date.compareTo(endStr) <= 0) {
                                                    totalSpent += t.amount;
                                                  }
                                                }
                                              }
                                              
                                              final remaining = category.budget - totalSpent;
                                              final isOverBudget = remaining < 0;
                                              
                                              return Padding(
                                                padding: const EdgeInsets.only(top: 4.0),
                                                child: Text(
                                                  'Sisa Budget: ${formatRupiah(remaining)}',
                                                  style: theme.textTheme.bodySmall?.copyWith(
                                                    color: isOverBudget ? Colors.red : Colors.green,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 10,
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      '${tx.type == TransactionType.income ? '+' : '-'} ${formatRupiah(tx.amount)}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: tx.type == TransactionType.income
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
                TextField(
                  controller: _aiController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Type your transaction here...',
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  decoration: BoxDecoration(
                    gradient: ext?.headerGradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: ext != null
                        ? [
                            BoxShadow(
                              color: ext.glowColor1.withValues(alpha: 0.4),
                              blurRadius: 12,
                              spreadRadius: 2,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      if (_aiController.text.trim().isEmpty) return;
                      categoriesAsync.whenData((cats) {
                        walletsAsync.whenData((wals) {
                          _parseAndSaveAiTransaction(
                            _aiController.text.trim(),
                            cats,
                            wals,
                          );
                        });
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Analyze & Save',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
  }
}
