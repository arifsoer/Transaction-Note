import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:transaction_note/theme/app_theme.dart';
import 'package:transaction_note/models/transaction.dart';
import 'package:transaction_note/components/add_transaction_form/ai_form.dart';
import 'package:transaction_note/components/add_transaction_form/manual_form.dart';

class TransactionFormScreen extends ConsumerStatefulWidget {
  final TransactionModel? existingTransaction;
  final bool isEmbedded;

  const TransactionFormScreen({
    super.key,
    this.existingTransaction,
    this.isEmbedded = false,
  });

  @override
  ConsumerState<TransactionFormScreen> createState() =>
      _TransactionFormScreenState();
}

class _TransactionFormScreenState extends ConsumerState<TransactionFormScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: 0,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final futuristicExt = theme.extension<FuturisticThemeExtension>();

    return Scaffold(
      appBar: widget.isEmbedded
          ? null
          : AppBar(
              title: Text(
                widget.existingTransaction != null
                    ? 'Edit Transaction'
                    : 'Add Transaction',
              ),
            ),
      body: SafeArea(
        child: Column(
          children: [
            if (widget.isEmbedded)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    widget.existingTransaction != null
                        ? 'Edit Transaction'
                        : 'Add Transaction',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            if (widget.existingTransaction == null)
              // Custom Sliding Segmented Tab Switch
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.3,
                  ),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color:
                        futuristicExt?.borderColor ??
                        Colors.grey.withValues(alpha: 0.2),
                  ),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  indicator: BoxDecoration(
                    gradient: futuristicExt?.headerGradient,
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: futuristicExt != null
                        ? [
                            BoxShadow(
                              color: futuristicExt.glowColor1.withValues(
                                alpha: 0.3,
                              ),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                  tabs: const [
                    Tab(text: 'AI Mode ✨'),
                    Tab(text: 'Manual'),
                  ],
                ),
              ),

            Expanded(
              child: widget.existingTransaction != null
                  ? ManualForm(
                      existingTransaction: widget.existingTransaction,
                      isEmbedded: widget.isEmbedded,
                    )
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        const AiForm(),
                        ManualForm(
                          existingTransaction: widget.existingTransaction,
                          isEmbedded: widget.isEmbedded,
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
