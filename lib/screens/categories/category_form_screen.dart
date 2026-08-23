import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:transaction_note/models/category.dart';
import 'package:transaction_note/models/transaction.dart';
import 'package:transaction_note/providers/auth_provider.dart';
import 'package:transaction_note/providers/category_provider.dart';
import 'package:transaction_note/helper.dart';
import 'package:transaction_note/services/analytics_service.dart';

const List<String> availableIcons = [
  'attach_money', 'restaurant', 'shopping_bag', 'work', 'directions_car',
  'subscriptions', 'card_giftcard', 'local_grocery_store', 'movie', 'trending_up',
  'home', 'flight', 'local_hospital', 'school', 'pets', 'label'
];

class CategoryFormScreen extends ConsumerStatefulWidget {
  final CategoryModel? existingCategory;

  const CategoryFormScreen({super.key, this.existingCategory});

  @override
  ConsumerState<CategoryFormScreen> createState() => _CategoryFormScreenState();
}

class _CategoryFormScreenState extends ConsumerState<CategoryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _budgetController = TextEditingController(text: '0');
  TransactionType _selectedType = TransactionType.expense;
  String _selectedIcon = 'label';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingCategory != null) {
      _nameController.text = widget.existingCategory!.name;
      if (widget.existingCategory!.budget > 0) {
        final formatter = NumberFormat('#,###', 'en_US');
        _budgetController.text = formatter.format(widget.existingCategory!.budget).replaceAll(',', '.');
      } else {
        _budgetController.text = '';
      }
      _selectedType = widget.existingCategory!.type;
      _selectedIcon = widget.existingCategory!.iconName;
    } else {
      _budgetController.text = '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _saveCategory() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    
    final user = ref.read(authStateProvider).value;
    if (user == null) return;
    
    final categoryService = ref.read(categoryServiceProvider);
    
    try {
      final budgetText = _budgetController.text.replaceAll('.', '').trim();
      final budget = double.tryParse(budgetText) ?? 0.0;
      
      if (widget.existingCategory == null) {
        // Add new
        await categoryService.addCategory(user.uid, _nameController.text.trim(), _selectedType, _selectedIcon, budget);
      } else {
        // Edit existing
        await categoryService.updateCategory(user.uid, widget.existingCategory!.id, _nameController.text.trim(), _selectedType, _selectedIcon, budget);
      }
      
      // Track category action
      ref.read(analyticsServiceProvider).logCategoryAction(
        action: widget.existingCategory == null ? 'add' : 'edit',
        hasBudgetSetup: budget > 0,
      );
      
      if (mounted) {
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  Future<void> _deleteCategory() async {
    if (widget.existingCategory == null) return;
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: const Text('Are you sure you want to delete this category?'),
        actions: [
          TextButton(onPressed: () => context.pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => context.pop(true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    
    if (confirm != true) return;
    
    setState(() => _isLoading = true);
    final user = ref.read(authStateProvider).value;
    if (user == null) return;
    
    final categoryService = ref.read(categoryServiceProvider);
    
    try {
      await categoryService.deleteCategory(user.uid, widget.existingCategory!.id);
      if (mounted) {
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingCategory != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Category' : 'Add Category'),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _isLoading ? null : _deleteCategory,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Category Name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.label_outline),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a category name';
                        }
                        return null;
                      },
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _budgetController,
                      decoration: const InputDecoration(
                        labelText: 'Budget (Optional)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.attach_money),
                        prefixText: 'Rp ',
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        CurrencyInputFormatter(),
                      ],
                      validator: (value) {
                        if (value != null && value.trim().isNotEmpty) {
                          final cleanValue = value.replaceAll('.', '').trim();
                          if (double.tryParse(cleanValue) == null) {
                            return 'Please enter a valid number';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    const Text('Transaction Type', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    SegmentedButton<TransactionType>(
                      segments: const [
                        ButtonSegment(value: TransactionType.expense, label: Text('Expense'), icon: Icon(Icons.arrow_downward)),
                        ButtonSegment(value: TransactionType.income, label: Text('Income'), icon: Icon(Icons.arrow_upward)),
                      ],
                      selected: {_selectedType},
                      onSelectionChanged: (Set<TransactionType> newSelection) {
                        setState(() {
                          _selectedType = newSelection.first;
                        });
                      },
                    ),
                    const SizedBox(height: 24),
                    const Text('Icon', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: availableIcons.map((iconName) {
                        final isSelected = iconName == _selectedIcon;
                        return InkWell(
                          onTap: () {
                            setState(() {
                              _selectedIcon = iconName;
                            });
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSelected ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.2) : Colors.transparent,
                              border: Border.all(
                                color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).dividerColor,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(getIconFromName(iconName), 
                              color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).iconTheme.color,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _saveCategory,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(isEditing ? 'Save Changes' : 'Create Category'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }
    
    // Remove all non-digits
    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (digitsOnly.isEmpty) {
      return newValue.copyWith(text: '');
    }
    
    final value = double.parse(digitsOnly);
    final formatter = NumberFormat('#,###', 'en_US');
    String newText = formatter.format(value).replaceAll(',', '.');
    
    return newValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}
