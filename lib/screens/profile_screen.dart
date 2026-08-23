import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:transaction_note/providers/auth_provider.dart';
import 'package:transaction_note/providers/theme_provider.dart';
import 'package:transaction_note/providers/user_provider.dart';
import 'package:transaction_note/components/period_setup_dialog.dart';
import 'package:transaction_note/providers/device_settings_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = authState.value;
    final theme = Theme.of(context);

    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // User Header
          Row(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundImage: user.photoURL != null ? NetworkImage(user.photoURL!) : null,
                child: user.photoURL == null ? const Icon(Icons.person, size: 40) : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName ?? 'Unknown User',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email ?? '',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.logout),
                color: theme.colorScheme.error,
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Logout'),
                      content: const Text('Are you sure you want to logout?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('Logout'),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    ref.read(defaultWalletIdProvider.notifier).setDefaultWalletId(null);
                    ref.read(homeFilterWalletIdsProvider.notifier).clear();
                    ref.read(authServiceProvider).signOut();
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 32),
          // Sub Menus
          ListTile(
            leading: Icon(Icons.account_balance_wallet, color: theme.colorScheme.primary),
            title: const Text('Wallets'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              context.push('/profile/wallets');
            },
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            tileColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 12),
          ListTile(
            leading: Icon(Icons.category, color: theme.colorScheme.primary),
            title: const Text('Categories'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              context.push('/profile/categories');
            },
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            tileColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 12),
          Consumer(builder: (context, ref, child) {
            final appUserAsync = ref.watch(currentUserProvider);
            return ListTile(
              leading: Icon(Icons.calendar_today, color: theme.colorScheme.primary),
              title: const Text('Billing Period Start Date'),
              subtitle: Text(
                appUserAsync.when(
                  data: (appUser) => appUser?.periodStartDay != null
                      ? 'Starts on the ${appUser!.periodStartDay}th'
                      : 'Not set',
                  loading: () => 'Loading...',
                  error: (error, stackTrace) => 'Error',
                ),
              ),
              trailing: const Icon(Icons.edit),
              onTap: () {
                final currentDay = appUserAsync.value?.periodStartDay;
                showDialog(
                  context: context,
                  builder: (context) => PeriodSetupDialog(
                    isDismissible: true,
                    initialValue: currentDay,
                  ),
                ).then((_) {
                  // Refresh user provider after dialog closes
                  ref.invalidate(currentUserProvider);
                });
              },
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              tileColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            );
          }),
          const SizedBox(height: 12),
          ListTile(
            leading: Icon(
              theme.brightness == Brightness.dark ? Icons.light_mode : Icons.dark_mode,
              color: theme.colorScheme.primary,
            ),
            title: const Text('Theme Mode'),
            trailing: Switch(
              value: theme.brightness == Brightness.dark,
              onChanged: (value) {
                ref.read(themeModeProvider.notifier).toggleTheme();
              },
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            tileColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          ),
        ],
      ),
    );
  }
}
