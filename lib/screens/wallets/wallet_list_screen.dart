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
    final homeFilterWalletIds = ref.watch(homeFilterWalletIdsProvider);

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
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.amber, width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star, size: 12, color: Colors.amber),
                              const SizedBox(width: 4),
                              Text(
                                'Default',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Theme.of(context).colorScheme.onSurface,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  subtitle: homeFilterWalletIds.contains(wallet.id)
                      ? Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.home, size: 14, color: Theme.of(context).colorScheme.primary),
                              const SizedBox(width: 4),
                              Text(
                                'Shown on home screen',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        )
                      : null,
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
