import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:transaction_note/models/transaction.dart';
import 'package:transaction_note/providers/category_provider.dart';

import 'package:transaction_note/helper.dart';

class CategoryListScreen extends ConsumerWidget {
  const CategoryListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Categories'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              context.push('/profile/categories/form');
            },
          ),
        ],
      ),
      body: categoriesAsync.when(
        data: (categories) {
          if (categories.isEmpty) {
            return const Center(child: Text('No categories found. Add one above!'));
          }

          return ListView.builder(
            itemCount: categories.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final category = categories[index];
              final isIncome = category.type == TransactionType.income;
              final typeColor = isIncome ? Colors.green : Colors.red;

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: typeColor.withValues(alpha: 0.1),
                    child: Icon(getIconFromName(category.iconName), color: typeColor),
                  ),
                  title: Text(category.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    category.budget > 0 
                        ? '${isIncome ? 'Income' : 'Expense'} • Budget: ${formatRupiah(category.budget)}'
                        : (isIncome ? 'Income' : 'Expense'),
                    style: TextStyle(color: typeColor, fontSize: 12),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    onPressed: () {
                      context.push('/profile/categories/form', extra: category);
                    },
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
