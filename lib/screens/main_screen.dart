import 'package:flutter/material.dart';
import 'package:transaction_note/components/navigation/app_bottom_nav_bar.dart';
import 'package:transaction_note/screens/home_screen.dart';
import 'package:transaction_note/screens/profile_screen.dart';
import 'package:transaction_note/screens/transaction_list_screen.dart';
import 'package:transaction_note/screens/transaction_form_screen.dart';
import 'package:transaction_note/screens/report_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:transaction_note/providers/nav_provider.dart';
import 'package:transaction_note/providers/user_provider.dart';
import 'package:transaction_note/components/period_setup_dialog.dart';
import 'package:transaction_note/components/default_wallet_setup_dialog.dart';
import 'package:transaction_note/models/user.dart';
import 'package:transaction_note/providers/device_settings_provider.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  bool _hasPromptedDefaultWallet = false;
  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(navigationIndexProvider);

    ref.listen<AsyncValue<AppUser?>>(currentUserStreamProvider, (previous, next) {
      next.whenData((user) {
        if (user != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            if (!mounted) return;
            // Check if dialog is already showing to prevent multiple dialogs
            if (!ModalRoute.of(context)!.isCurrent) return;

            // Prompt for Period Setup if missing
            if (user.periodStartDay == null) {
              await showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const PeriodSetupDialog(isDismissible: false),
              );
            }

            if (!mounted) return;
            if (!ModalRoute.of(context)!.isCurrent) return;

            // Prompt for Default Wallet if missing and haven't prompted this session
            final currentDefaultWallet = ref.read(defaultWalletIdProvider);
            if (currentDefaultWallet == null && !_hasPromptedDefaultWallet) {
              _hasPromptedDefaultWallet = true;
              await showDialog(
                context: context,
                barrierDismissible: true,
                builder: (context) => const DefaultWalletSetupDialog(),
              );
            }
          });
        }
      });
    });

    return SafeArea(
      child: Scaffold(
        body: IndexedStack(
          index: currentIndex,
          children: [
            // Index 0: Home Screen Layout
            const HomeScreen(),
            
            // Index 1: Transaction Tab
            const TransactionListScreen(),
            
            // Index 2: Add Tab
            const TransactionFormScreen(isEmbedded: true),
            
            // Index 3: Reports Tab
            const ReportScreen(),
            
            // Index 4: Profile Tab
            const ProfileScreen(),
          ],
        ),
        bottomNavigationBar: AppBottomNavBar(
          currentIndex: currentIndex,
          onTap: (index) {
            ref.read(navigationIndexProvider.notifier).state = index;
          },
        ),
      ),
    );
  }
}
