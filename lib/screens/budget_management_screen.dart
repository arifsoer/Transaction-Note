import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:transaction_note/models/transaction.dart';
import 'package:transaction_note/providers/category_provider.dart';
import 'package:transaction_note/providers/auth_provider.dart';
import 'package:transaction_note/providers/transaction_provider.dart';
import 'package:transaction_note/helper.dart';
import 'package:transaction_note/theme/app_theme.dart';
import 'package:transaction_note/models/category.dart';
import 'package:transaction_note/screens/categories/category_form_screen.dart';

class BudgetManagementScreen extends ConsumerStatefulWidget {
  const BudgetManagementScreen({super.key});

  @override
  ConsumerState<BudgetManagementScreen> createState() => _BudgetManagementScreenState();
}

class _BudgetManagementScreenState extends ConsumerState<BudgetManagementScreen> {
  Future<void> _showSetBudgetDialog(BuildContext context, CategoryModel category, String userId, double previousExpense) async {
    final controller = TextEditingController(
      text: category.budget > 0 ? category.budget.toInt().toString() : '',
    );
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Set Budget for ${category.name}'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (previousExpense > 0)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      'Previous period expense:\n${formatRupiah(previousExpense)}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                TextFormField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    CurrencyInputFormatter(),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Budget Amount',
                    prefixText: 'Rp ',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a budget';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final rawValue = controller.text.replaceAll('.', '');
                  final newBudget = double.tryParse(rawValue) ?? 0.0;
                  final service = ref.read(categoryServiceProvider);
                  await service.updateCategory(
                    userId,
                    category.id,
                    category.name,
                    category.type,
                    category.iconName,
                    newBudget,
                  );
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesStreamProvider);
    final transactionsAsync = ref.watch(transactionsStreamProvider);
    final user = ref.watch(authStateProvider).value;
    final theme = Theme.of(context);
    final customTheme = theme.extension<FuturisticThemeExtension>();
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        // Header
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: categoriesAsync.when(
            data: (categories) {
              final expenses = categories.where((c) => c.type == TransactionType.expense).toList();
              final totalBudget = expenses.fold(0.0, (sum, item) => sum + item.budget);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Planned Budget',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    formatRupiah(totalBudget),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
            error: (err, stack) => Text('Error: $err', style: const TextStyle(color: Colors.white)),
          ),
        ),

        // List
        Expanded(
          child: categoriesAsync.when(
            data: (categories) {
              final expenses = categories.where((c) => c.type == TransactionType.expense).toList();
              
              if (expenses.isEmpty) {
                return const Center(child: Text('No expense categories found.'));
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: expenses.length,
                itemBuilder: (context, index) {
                  final category = expenses[index];
                  final hasBudget = category.budget > 0;

                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        if (user != null) {
                          double prevExpense = 0;
                          transactionsAsync.whenData((transactions) {
                            final now = DateTime.now();
                            final prevMonth = DateTime(now.year, now.month - 1);
                            final prevMonthPrefix = "${prevMonth.year}-${prevMonth.month.toString().padLeft(2, '0')}";
                            
                            prevExpense = transactions
                                .where((t) => 
                                    t.categoryId == category.id && 
                                    t.type == TransactionType.expense &&
                                    t.date.startsWith(prevMonthPrefix))
                                .fold(0.0, (sum, item) => sum + item.amount);
                          });
                          _showSetBudgetDialog(context, category, user.uid, prevExpense);
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.red.withValues(alpha: 0.1),
                              child: Icon(getIconFromName(category.iconName), color: Colors.red),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    category.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    hasBudget ? formatRupiah(category.budget) : 'No budget set',
                                    style: TextStyle(
                                      color: hasBudget ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.edit, size: 20),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error: $err')),
          ),
        ),
      ],
    );
  }
}
