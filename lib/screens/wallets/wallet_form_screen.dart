import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:transaction_note/models/wallet.dart';
import 'package:transaction_note/providers/auth_provider.dart';
import 'package:transaction_note/providers/wallet_provider.dart';
import 'package:transaction_note/providers/device_settings_provider.dart';

class WalletFormScreen extends ConsumerStatefulWidget {
  final WalletModel? existingWallet;

  const WalletFormScreen({super.key, this.existingWallet});

  @override
  ConsumerState<WalletFormScreen> createState() => _WalletFormScreenState();
}

class _WalletFormScreenState extends ConsumerState<WalletFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingWallet != null) {
      _nameController.text = widget.existingWallet!.name;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveWallet() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    
    final user = ref.read(authStateProvider).value;
    if (user == null) return;
    
    final walletService = ref.read(walletServiceProvider);
    
    try {
      if (widget.existingWallet == null) {
        // Add new
        await walletService.addWallet(user.uid, _nameController.text.trim());
      } else {
        // Edit existing
        await walletService.updateWallet(user.uid, widget.existingWallet!.id, _nameController.text.trim());
      }
      
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
  
  Future<void> _deleteWallet() async {
    if (widget.existingWallet == null) return;
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Wallet'),
        content: const Text('Are you sure you want to delete this wallet?'),
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
    
    final walletService = ref.read(walletServiceProvider);
    
    try {
      await walletService.deleteWallet(user.uid, widget.existingWallet!.id);
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
    final isEditing = widget.existingWallet != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Wallet' : 'Add Wallet'),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _isLoading ? null : _deleteWallet,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Wallet Name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.account_balance_wallet),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a wallet name';
                        }
                        return null;
                      },
                      textCapitalization: TextCapitalization.words,
                    ),
                    if (isEditing) ...[
                      const SizedBox(height: 16),
                      Consumer(builder: (context, ref, child) {
                        final defaultWalletId = ref.watch(defaultWalletIdProvider);
                        final isDefault = defaultWalletId == widget.existingWallet!.id;
                        return SwitchListTile(
                          title: const Text('Set as Default Wallet on this device'),
                          subtitle: const Text('Auto-selected for new transactions'),
                          value: isDefault,
                          onChanged: (value) {
                            if (value) {
                              ref.read(defaultWalletIdProvider.notifier).setDefaultWalletId(widget.existingWallet!.id);
                            } else {
                              ref.read(defaultWalletIdProvider.notifier).setDefaultWalletId(null);
                            }
                          },
                        );
                      }),
                      Consumer(builder: (context, ref, child) {
                        final filterWalletIds = ref.watch(homeFilterWalletIdsProvider);
                        final isFilter = filterWalletIds.contains(widget.existingWallet!.id);
                        return SwitchListTile(
                          title: const Text('Show on Home Screen Filter'),
                          subtitle: const Text('Max 2 wallets can be displayed'),
                          value: isFilter,
                          onChanged: (value) {
                            final notifier = ref.read(homeFilterWalletIdsProvider.notifier);
                            if (value) {
                              if (filterWalletIds.length >= 2) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('You can only select up to 2 filter wallets. Please deselect another one first.'),
                                  ),
                                );
                              } else {
                                notifier.addWalletId(widget.existingWallet!.id);
                              }
                            } else {
                              notifier.removeWalletId(widget.existingWallet!.id);
                              // If this was the active filter, reset it
                              final activeFilter = ref.read(activeHomeFilterProvider);
                              if (activeFilter == widget.existingWallet!.id) {
                                ref.read(activeHomeFilterProvider.notifier).state = null;
                              }
                            }
                          },
                        );
                      }),
                    ],
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _saveWallet,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(isEditing ? 'Save Changes' : 'Create Wallet'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
