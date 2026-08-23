import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:transaction_note/models/category.dart';
import 'package:transaction_note/providers/transaction_provider.dart';
import 'package:transaction_note/providers/wallet_provider.dart';
import 'package:transaction_note/providers/device_settings_provider.dart';
import 'package:transaction_note/components/screens/home_screen/transaction_list.dart';
import 'package:transaction_note/helper.dart';

class CategoryTransactionsScreen extends ConsumerStatefulWidget {
  final CategoryModel category;
  final DateTimeRange periodRange;

  const CategoryTransactionsScreen({
    super.key,
    required this.category,
    required this.periodRange,
  });

  @override
  ConsumerState<CategoryTransactionsScreen> createState() => _CategoryTransactionsScreenState();
}

class _CategoryTransactionsScreenState extends ConsumerState<CategoryTransactionsScreen> {
  String _searchQuery = '';
  String? _selectedWalletId;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsyncValue = ref.watch(transactionsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category.name),
        centerTitle: true,
      ),
      body: Column(
        children: [
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
          Consumer(
            builder: (context, ref, child) {
              final filterWalletIds = ref.watch(homeFilterWalletIdsProvider);
              final walletsAsync = ref.watch(walletsStreamProvider);

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('All'),
                      selected: _selectedWalletId == null,
                      onSelected: (_) {
                        setState(() {
                          _selectedWalletId = null;
                        });
                      },
                    ),
                    ...filterWalletIds.map((id) {
                      return walletsAsync.when(
                        data: (wallets) {
                          try {
                            final wallet = wallets.firstWhere((w) => w.id == id);
                            return Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: FilterChip(
                                label: Text(wallet.name),
                                selected: _selectedWalletId == id,
                                onSelected: (_) {
                                  setState(() {
                                    _selectedWalletId = id;
                                  });
                                },
                              ),
                            );
                          } catch (_) {
                            return const SizedBox.shrink();
                          }
                        },
                        loading: () => const SizedBox.shrink(),
                        error: (err, stack) => const SizedBox.shrink(),
                      );
                    }),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Expanded(
            child: transactionsAsyncValue.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
              data: (allTransactions) {
                final String startStr = _formatDateString(widget.periodRange.start);
                final String endStr = _formatDateString(widget.periodRange.end);

                final filteredTransactions = allTransactions.where((t) {
                  // Filter by category
                  if (t.categoryId != widget.category.id) return false;

                  // Filter by period
                  if (t.date.compareTo(startStr) < 0 || t.date.compareTo(endStr) > 0) {
                    return false;
                  }

                  // Filter by search query
                  if (_searchQuery.isNotEmpty) {
                    if (!t.note.toLowerCase().contains(_searchQuery)) {
                      return false;
                    }
                  }

                  // Filter by wallet
                  if (_selectedWalletId != null && t.walletId != _selectedWalletId) {
                    return false;
                  }

                  return true;
                }).toList();

                if (filteredTransactions.isEmpty) {
                  return const Center(child: Text('No transactions found.'));
                }

                // Sort descending
                filteredTransactions.sort((a, b) {
                  final dateA = DateTime.tryParse(a.date) ?? DateTime(1970);
                  final dateB = DateTime.tryParse(b.date) ?? DateTime(1970);
                  return dateB.compareTo(dateA);
                });

                final groupedTransactions = groupBy(
                  filteredTransactions,
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

                return ListView(children: transactionList);
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateString(DateTime date) {
    return "${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }
}
