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
import 'package:transaction_note/providers/device_settings_provider.dart';
import 'package:transaction_note/theme/app_theme.dart';
import 'package:transaction_note/helper.dart';
import 'package:transaction_note/providers/user_provider.dart';
import 'package:transaction_note/helper/period_helper.dart';
import 'package:transaction_note/services/analytics_service.dart';

class ManualForm extends ConsumerStatefulWidget {
  final TransactionModel? existingTransaction;
  final bool isEmbedded;

  const ManualForm({
    super.key,
    this.existingTransaction,
    this.isEmbedded = false,
  });

  @override
  ConsumerState<ManualForm> createState() => _ManualFormState();
}

class _ManualFormState extends ConsumerState<ManualForm> {
  String _amountString = '0';
  TransactionType _selectedType = TransactionType.expense;
  DateTime _selectedDate = DateTime.now();
  String _note = '';
  CategoryModel? _selectedCategory;
  WalletModel? _selectedWallet;
  bool _isLoading = false;

  String get _formattedAmount {
    if (_amountString.isEmpty) return '0';
    final parsed = double.tryParse(_amountString) ?? 0;
    final formatter = NumberFormat('#,###', 'en_US');
    return formatter.format(parsed).replaceAll(',', '.');
  }

  @override
  void initState() {
    super.initState();
    if (widget.existingTransaction != null) {
      _amountString = widget.existingTransaction!.amount.toStringAsFixed(0);
      _selectedType = widget.existingTransaction!.type;
      _selectedDate =
          DateTime.tryParse(widget.existingTransaction!.date) ?? DateTime.now();
      _note = widget.existingTransaction!.note;
    }
  }

  void _appendAmount(String val) {
    setState(() {
      if (_amountString == '0') {
        _amountString = val;
      } else {
        _amountString += val;
      }
    });
  }

  void _backspaceAmount() {
    setState(() {
      if (_amountString.length > 1) {
        _amountString = _amountString.substring(0, _amountString.length - 1);
      } else {
        _amountString = '0';
      }
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveTransaction(
    List<CategoryModel> categories,
    List<WalletModel> wallets,
  ) async {
    if (_amountString == '0') {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please enter an amount')));
      return;
    }
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please select a category')));
      return;
    }

    setState(() => _isLoading = true);
    final user = ref.read(authStateProvider).value;
    if (user == null) return;
    final currentUser = ref.read(currentUserProvider).value;

    final transactionService = ref.read(transactionServiceProvider);

    final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final amount = double.tryParse(_amountString) ?? 0.0;

    final transaction = TransactionModel(
      id: widget.existingTransaction?.id,
      date: formattedDate,
      amount: amount,
      note: _note,
      type: _selectedType,
      categoryId: _selectedCategory!.id,
      categoryName: _selectedCategory!.name,
      walletId: _selectedWallet?.id,
      walletName: _selectedWallet?.name,
    );

    try {
      if (widget.existingTransaction == null) {
        await transactionService.addTransaction(user.uid, transaction);
        
        // Track manual transaction addition
        ref.read(analyticsServiceProvider).logAddTransaction(
          method: 'manual',
          totalTransactions: 1,
        );
        
        // Calculate remaining budget
        double? remainingBudget;
        if (_selectedCategory != null && _selectedCategory!.budget > 0 && transaction.type == TransactionType.expense) {
           final allTransactions = ref.read(transactionsStreamProvider).value ?? [];
           final periodStartDay = currentUser?.periodStartDay ?? 1;
           final period = PeriodHelper.calculatePeriod(periodStartDay, DateTime.now());
           
           final startStr = "${period.start.year.toString().padLeft(4, '0')}-${period.start.month.toString().padLeft(2, '0')}-${period.start.day.toString().padLeft(2, '0')}";
           final endStr = "${period.end.year.toString().padLeft(4, '0')}-${period.end.month.toString().padLeft(2, '0')}-${period.end.day.toString().padLeft(2, '0')}";
           
           double totalSpent = 0;
           for (var t in allTransactions) {
             if (t.categoryId == _selectedCategory!.id && t.type == TransactionType.expense) {
                if (t.date.compareTo(startStr) >= 0 && t.date.compareTo(endStr) <= 0) {
                   totalSpent += t.amount;
                }
             }
           }
           totalSpent += transaction.amount;
           remainingBudget = _selectedCategory!.budget - totalSpent;
        }

        if (mounted) {
           await showDialog(
             context: context,
             barrierDismissible: false,
             builder: (ctx) => AlertDialog(
                title: const Text('Success!'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Transaction added successfully.'),
                    const SizedBox(height: 16),
                    Text('Amount: ${formatRupiah(transaction.amount)}'),
                    Text('Category: ${transaction.categoryName}'),
                    if (remainingBudget != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Sisa Budget: ${formatRupiah(remainingBudget)}',
                        style: TextStyle(
                          color: remainingBudget < 0 ? Colors.red : Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                    },
                    child: const Text('OK'),
                  ),
                ],
             ),
           );
           
           if (!mounted) return;
           if (widget.isEmbedded) {
               setState(() {
                 _amountString = '0';
                 _note = '';
                 _selectedCategory = null;
                 _selectedWallet = null;
                 _selectedDate = DateTime.now();
                 _selectedType = TransactionType.expense;
               });
           } else {
               context.pop();
           }
        }
      } else {
        await transactionService.updateTransaction(
          user.uid,
          widget.existingTransaction!.id!,
          transaction,
        );
        if (mounted) context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildKeypadButton(String label, ThemeData theme) {
    return InkWell(
      onTap: () => _appendAmount(label),
      borderRadius: BorderRadius.circular(12),
      child: Center(
        child: Text(
          label,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ext = theme.extension<FuturisticThemeExtension>();
    final categoriesAsync = ref.watch(categoriesStreamProvider);
    final walletsAsync = ref.watch(walletsStreamProvider);

    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Transaction Type Toggle
                Center(
                  child: SegmentedButton<TransactionType>(
                    segments: const [
                      ButtonSegment(
                        value: TransactionType.expense,
                        label: Text('Expense'),
                      ),
                      ButtonSegment(
                        value: TransactionType.income,
                        label: Text('Income'),
                      ),
                    ],
                    selected: {_selectedType},
                    onSelectionChanged: (Set<TransactionType> newSelection) {
                      setState(() {
                        _selectedType = newSelection.first;
                        _selectedCategory = null;
                      });
                    },
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.resolveWith<Color>(
                        (Set<WidgetState> states) {
                          if (states.contains(WidgetState.selected)) {
                            return _selectedType == TransactionType.income
                                ? Colors.green.withValues(alpha: 0.2)
                                : Colors.red.withValues(alpha: 0.2);
                          }
                          return theme.colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.3);
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Amount Display
                Center(
                  child: Text(
                    'Rp $_formattedAmount',
                    style: theme.textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _selectedType == TransactionType.income
                          ? Colors.green
                          : Colors.red,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Custom Keypad
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  childAspectRatio: 2,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  children: [
                    '1',
                    '2',
                    '3',
                    '4',
                    '5',
                    '6',
                    '7',
                    '8',
                    '9',
                    '000',
                    '0',
                    '⌫',
                  ].map((label) {
                    if (label == '⌫') {
                      return InkWell(
                        onTap: _backspaceAmount,
                        borderRadius: BorderRadius.circular(12),
                        child: Center(
                          child: Icon(
                            Icons.backspace_outlined,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      );
                    }
                    return _buildKeypadButton(label, theme);
                  }).toList(),
                ),
                const SizedBox(height: 32),

                // Category Selection
                const Text(
                  'Category',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                categoriesAsync.when(
                  loading: () => const CircularProgressIndicator(),
                  error: (err, stack) => Text('Error: $err'),
                  data: (categories) {
                    final filteredCategories = categories
                        .where((c) => c.type == _selectedType)
                        .toList();

                    if (widget.existingTransaction != null &&
                        _selectedCategory == null) {
                      try {
                        _selectedCategory = filteredCategories.firstWhere(
                          (c) => c.id == widget.existingTransaction!.categoryId,
                        );
                      } catch (_) {}
                    }

                    return DropdownButtonFormField<CategoryModel>(
                      initialValue: _selectedCategory,
                      hint: const Text('Select Category'),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.3),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: filteredCategories.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Row(
                            children: [
                              Icon(getIconFromName(category.iconName)),
                              const SizedBox(width: 8),
                              Text(category.name),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedCategory = val;
                        });
                      },
                    );
                  },
                ),
                const SizedBox(height: 24),

                // Wallet Selection
                const Text(
                  'Wallet (Optional)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                walletsAsync.when(
                  loading: () => const CircularProgressIndicator(),
                  error: (err, stack) => Text('Error: $err'),
                  data: (wallets) {
                    if (widget.existingTransaction != null &&
                        _selectedWallet == null &&
                        widget.existingTransaction!.walletId != null) {
                      try {
                        _selectedWallet = wallets.firstWhere(
                          (w) => w.id == widget.existingTransaction!.walletId,
                        );
                      } catch (_) {}
                    } else if (widget.existingTransaction == null && _selectedWallet == null) {
                      final defaultWalletId = ref.read(defaultWalletIdProvider);
                      if (defaultWalletId != null) {
                        try {
                          _selectedWallet = wallets.firstWhere(
                            (w) => w.id == defaultWalletId,
                          );
                        } catch (_) {}
                      }
                    }

                    return DropdownButtonFormField<WalletModel>(
                      initialValue: _selectedWallet,
                      hint: const Text('Select Wallet'),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.3),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: [
                        const DropdownMenuItem<WalletModel>(
                          value: null,
                          child: Text('None'),
                        ),
                        ...wallets.map((wallet) {
                          return DropdownMenuItem(
                            value: wallet,
                            child: Text(wallet.name),
                          );
                        }),
                      ],
                      onChanged: (val) {
                        setState(() {
                          _selectedWallet = val;
                        });
                      },
                    );
                  },
                ),
                const SizedBox(height: 24),

                // Date Selection
                const Text(
                  'Date',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_month,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          DateFormat(
                            'EEEE, MMMM d, yyyy',
                          ).format(_selectedDate),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Note
                const Text(
                  'Note (Optional)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                TextField(
                  onChanged: (val) => _note = val,
                  controller: TextEditingController(text: _note)
                    ..selection = TextSelection.collapsed(offset: _note.length),
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Add a description...',
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Save Button
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
                      categoriesAsync.whenData((cats) {
                        walletsAsync.whenData((wals) {
                          _saveTransaction(cats, wals);
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
                    child: Text(
                      widget.existingTransaction != null
                          ? 'Save Changes'
                          : 'Create Transaction',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
  }
}
