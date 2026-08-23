import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:transaction_note/providers/wallet_provider.dart';
import 'package:transaction_note/providers/device_settings_provider.dart';

class WalletListScreen extends ConsumerWidget {
  const WalletListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletsAsync = ref.watch(walletsStreamProvider);
    final defaultWalletId = ref.watch(defaultWalletIdProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Wallets'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              context.push('/profile/wallets/form');
            },
          ),
        ],
      ),
      body: walletsAsync.when(
        data: (wallets) {
          if (wallets.isEmpty) {
            return const Center(child: Text('No wallets found. Add one above!'));
          }

          return ListView.builder(
            itemCount: wallets.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final wallet = wallets[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.account_balance_wallet),
                  ),
                  title: Row(
                    children: [
                      Text(wallet.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      if (wallet.id == defaultWalletId) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Default',
                            style: TextStyle(
                              fontSize: 10,
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    onPressed: () {
                      context.push('/profile/wallets/form', extra: wallet);
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
