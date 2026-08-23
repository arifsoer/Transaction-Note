import 'package:flutter/material.dart';
import 'package:transaction_note/helper.dart';

class BudgetProgressBar extends StatelessWidget {
  final String categoryName;
  final String iconName;
  final double expenseAmount;
  final double budgetAmount;
  final VoidCallback? onTap;

  const BudgetProgressBar({
    super.key,
    required this.categoryName,
    required this.iconName,
    required this.expenseAmount,
    required this.budgetAmount,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // If budget is 0, we can define the progress as 0 or 1.
    // Let's set it to a ratio. If budget is 0 and expense > 0, it's technically over budget.
    double progress = budgetAmount > 0 ? (expenseAmount / budgetAmount) : (expenseAmount > 0 ? 1.0 : 0.0);
    
    // Clamp the progress for the visual bar between 0 and 1
    double visualProgress = progress.clamp(0.0, 1.0);
    
    // Determine color based on progress
    Color progressColor = Theme.of(context).colorScheme.primary;
    if (progress > 1.0) {
      progressColor = Colors.redAccent;
    } else if (progress > 0.8) {
      progressColor = Colors.orangeAccent;
    }

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(getIconFromName(iconName), size: 20, color: Theme.of(context).colorScheme.onSurface),
                  const SizedBox(width: 8),
                  Text(
                    categoryName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
              Text(
                budgetAmount > 0 
                  ? '${formatRupiah(expenseAmount)} / ${formatRupiah(budgetAmount)}'
                  : formatRupiah(expenseAmount),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: progress > 1.0 ? Colors.redAccent : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: visualProgress,
              minHeight: 10,
              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
          ),
          if (progress > 1.0)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                'Over budget by ${formatRupiah(expenseAmount - budgetAmount)}',
                style: const TextStyle(color: Colors.redAccent, fontSize: 12),
              ),
            ),
        ],
      ),
    ));
  }
}
