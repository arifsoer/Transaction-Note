import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:transaction_note/providers/wallet_provider.dart';
import 'package:transaction_note/providers/device_settings_provider.dart';
import 'package:transaction_note/models/wallet.dart';

class DefaultWalletSetupDialog extends ConsumerStatefulWidget {
  const DefaultWalletSetupDialog({super.key});

  @override
  ConsumerState<DefaultWalletSetupDialog> createState() => _DefaultWalletSetupDialogState();
}

class _DefaultWalletSetupDialogState extends ConsumerState<DefaultWalletSetupDialog> {
  String? _selectedWalletId;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final walletsAsync = ref.watch(walletsStreamProvider);

    return AlertDialog(
      title: const Text('Set Default Wallet'),
      content: walletsAsync.when(
        data: (wallets) {
          if (wallets.isEmpty) {
            return const Text('You do not have any wallets yet. You can create one later and set it as your default.');
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Select a wallet to be your default when adding new transactions.'),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedWalletId,
                hint: const Text('Select Wallet'),
                isExpanded: true,
                items: wallets.map((wallet) {
                  return DropdownMenuItem(
                    value: wallet.id,
                    child: Text(wallet.name),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedWalletId = value;
                  });
                },
              ),
            ],
          );
        },
        loading: () => const SizedBox(
          height: 100,
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => Text('Error loading wallets: $e'),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Skip'),
        ),
        walletsAsync.maybeWhen(
          data: (wallets) => wallets.isNotEmpty
              ? ElevatedButton(
                  onPressed: (_isLoading || _selectedWalletId == null)
                      ? null
                      : () async {
                          setState(() => _isLoading = true);
                          await ref.read(defaultWalletIdProvider.notifier).setDefaultWalletId(_selectedWalletId);
                          if (mounted) Navigator.of(context).pop();
                        },
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save'),
                )
              : const SizedBox.shrink(),
          orElse: () => const SizedBox.shrink(),
        ),
      ],
    );
  }
}
