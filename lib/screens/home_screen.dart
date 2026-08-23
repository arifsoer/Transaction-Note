import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:transaction_note/components/screens/home_screen/home_header.dart';
import 'package:transaction_note/components/screens/home_screen/transaction_list.dart';
import 'package:transaction_note/theme/app_theme.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Obtain centralized custom design parameters from ThemeExtension
    final customTheme = theme.extension<FuturisticThemeExtension>()!;

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 220,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: customTheme.headerGradient,
              border: Border(
                bottom: BorderSide(
                  color: isDark
                      ? customTheme.borderColor.withValues(alpha: 0.5)
                      : Colors.transparent,
                ),
              ),
            ),
            child: const HomeHeader(),
          ),
        ),
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.3)
                      : Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Consumer(
              builder: (context, ref, child) {
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                      child: Text(
                        'Showing transactions for today and yesterday. For a detailed list, go to the Transactions tab.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () async {
                          // Log the event as requested
                          await FirebaseAnalytics.instance.logEvent(name: 'pull_to_refresh_home');
                          // Data updates reactively, so we just wait for the animation
                          await Future.delayed(const Duration(milliseconds: 500));
                        },
                        child: const TransactionListHomeScreen(),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
