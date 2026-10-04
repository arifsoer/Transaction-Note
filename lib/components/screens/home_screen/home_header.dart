import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:transaction_note/helper/period_helper.dart';
import 'package:transaction_note/providers/dashboard_provider.dart';
import 'package:transaction_note/providers/device_settings_provider.dart';
import 'package:transaction_note/providers/user_provider.dart';
import 'package:transaction_note/providers/wallet_provider.dart';
import 'package:transaction_note/helper.dart';

final monthOffsetProvider = StateProvider<int>((ref) => 0);



class HomeHeader extends ConsumerWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offset = ref.watch(monthOffsetProvider);
    final appUserAsync = ref.watch(currentUserStreamProvider);
    final totalsAsync = ref.watch(dashboardTotalsProvider);

    DateTimeRange? periodRange;
    appUserAsync.whenData((user) {
      if (user?.periodStartDay != null) {
        periodRange = PeriodHelper.calculatePeriod(
          user!.periodStartDay!,
          DateTime.now(),
          monthOffset: offset,
        );
      }
    });



    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () {
                  ref.read(monthOffsetProvider.notifier).state--;
                },
                icon: const Icon(
                  Icons.chevron_left_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      periodRange != null
                          ? '${DateFormat('d MMMM yyyy').format(periodRange!.start)} - ${DateFormat('d MMMM yyyy').format(periodRange!.end)}'
                          : 'Setting up period...',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('EEEE, d MMMM yyyy').format(DateTime.now()),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: offset < 0 ? () {
                  ref.read(monthOffsetProvider.notifier).state++;
                } : null,
                icon: Icon(
                  Icons.chevron_right_rounded,
                  color: offset < 0 ? Colors.white : Colors.white.withValues(alpha: 0.3),
                  size: 32,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                totalsAsync.when(
                  data: (totals) {
                    final difference = totals.income - totals.expense;
                    final isPositive = difference >= 0;
                    
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Row 1: Difference
                        Row(
                          children: [
                            Icon(
                              isPositive ? Icons.account_balance_wallet : Icons.money_off,
                              color: isPositive ? Colors.greenAccent : Colors.redAccent,
                              size: 28,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                formatRupiah(difference.abs()),
                                style: Theme.of(context).textTheme.headlineLarge!.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 32,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Row 2: Income and Expense
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Income
                            Expanded(
                              child: Row(
                                children: [
                                  const Icon(Icons.arrow_downward, color: Colors.greenAccent, size: 20),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      formatRupiah(totals.income),
                                      style: Theme.of(context).textTheme.titleLarge!.copyWith(
                                        color: Colors.white70,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Expense
                            Expanded(
                              child: Row(
                                children: [
                                  const Icon(Icons.arrow_upward, color: Colors.redAccent, size: 20),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      formatRupiah(totals.expense),
                                      style: Theme.of(context).textTheme.titleLarge!.copyWith(
                                        color: Colors.white70,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                  loading: () => const SizedBox(
                    height: 80,
                    child: Center(
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    ),
                  ),
                  error: (error, stackTrace) => const Text(
                    'Error loading totals',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                Consumer(
                  builder: (context, ref, child) {
                    final filterWalletIds = ref.watch(
                      homeFilterWalletIdsProvider,
                    );
                    final activeFilter = ref.watch(activeHomeFilterProvider);
                    final walletsAsync = ref.watch(walletsStreamProvider);
                    final defaultWalletId = ref.watch(defaultWalletIdProvider);

                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          FilterChip(
                            label: const Text('All'),
                            selected: activeFilter == null,
                            onSelected: (_) {
                              ref
                                      .read(activeHomeFilterProvider.notifier)
                                      .state =
                                  null;
                            },
                            labelStyle: TextStyle(
                              color: Colors.white,
                              fontWeight: activeFilter == null
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          ...filterWalletIds.map((id) {
                            return walletsAsync.when(
                              data: (wallets) {
                                try {
                                  final wallet = wallets.firstWhere(
                                    (w) => w.id == id,
                                  );
                                  return Padding(
                                    padding: const EdgeInsets.only(left: 8.0),
                                    child: FilterChip(
                                      label: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(wallet.name),
                                          if (wallet.id == defaultWalletId) ...[
                                            const SizedBox(width: 4),
                                            const Icon(Icons.star, size: 14, color: Colors.amber),
                                          ],
                                        ],
                                      ),
                                      selected: activeFilter == id,
                                      onSelected: (_) {
                                        ref
                                                .read(
                                                  activeHomeFilterProvider
                                                      .notifier,
                                                )
                                                .state =
                                            id;
                                      },
                                      labelStyle: TextStyle(
                                        color: Colors.white,
                                        fontWeight: activeFilter == id
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  );
                                } catch (_) {
                                  return const SizedBox.shrink();
                                }
                              },
                              loading: () => const SizedBox.shrink(),
                              error: (error, stackTrace) =>
                                  const SizedBox.shrink(),
                            );
                          }),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
