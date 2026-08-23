import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:transaction_note/providers/transaction_provider.dart';
import 'package:transaction_note/providers/wallet_provider.dart';
import 'package:transaction_note/providers/category_provider.dart';
import 'package:transaction_note/components/screens/home_screen/transaction_list.dart';
import 'package:transaction_note/helper.dart';

class WalletTransactionsScreen extends ConsumerStatefulWidget {
  final String walletName;
  final DateTimeRange periodRange;

  const WalletTransactionsScreen({
    super.key,
    required this.walletName,
    required this.periodRange,
  });

  @override
  ConsumerState<WalletTransactionsScreen> createState() => _WalletTransactionsScreenState();
}

class _WalletTransactionsScreenState extends ConsumerState<WalletTransactionsScreen> {
  String _searchQuery = '';
  String? _selectedCategoryId;
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
        title: Text(widget.walletName),
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
              final categoriesAsync = ref.watch(categoriesStreamProvider);

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('All Categories'),
                      selected: _selectedCategoryId == null,
                      onSelected: (_) {
                        setState(() {
                          _selectedCategoryId = null;
                        });
                      },
                    ),
                    ...categoriesAsync.when(
                      data: (categories) {
                        return categories.map((cat) {
                          return Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: FilterChip(
                              label: Text(cat.name),
                              selected: _selectedCategoryId == cat.id,
                              onSelected: (_) {
                                setState(() {
                                  _selectedCategoryId = cat.id;
                                });
                              },
                            ),
                          );
                        }).toList();
                      },
                      loading: () => [const SizedBox.shrink()],
                      error: (err, stack) => [const SizedBox.shrink()],
                    ),
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
                  // Filter by wallet
                  final wName = t.walletName ?? 'Unassigned';
                  if (wName != widget.walletName) return false;

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

                  // Filter by category
                  if (_selectedCategoryId != null && t.categoryId != _selectedCategoryId) {
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
