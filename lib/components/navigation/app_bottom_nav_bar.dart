import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:transaction_note/providers/auth_provider.dart';

class AppBottomNavBar extends ConsumerWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = authState.value;

    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      items: <BottomNavigationBarItem>[
        const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        const BottomNavigationBarItem(
          icon: Icon(Icons.account_balance_wallet),
          label: 'Budget',
        ),
        const BottomNavigationBarItem(icon: Icon(Icons.add), label: 'Add'),
        const BottomNavigationBarItem(
          icon: Icon(Icons.bar_chart),
          label: 'Reports',
        ),
        BottomNavigationBarItem(
          icon: user?.photoURL != null
              ? CircleAvatar(
                  radius: 12,
                  backgroundImage: NetworkImage(user!.photoURL!),
                )
              : const Icon(Icons.person),
          activeIcon: user?.photoURL != null
              ? CircleAvatar(
                  radius: 12,
                  backgroundImage: NetworkImage(user!.photoURL!),
                  // Add a border when active
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Theme.of(context).colorScheme.primary, width: 2),
                    ),
                  ),
                )
              : const Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
}
