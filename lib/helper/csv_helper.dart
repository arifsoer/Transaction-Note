import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:transaction_note/models/transaction.dart';
import 'package:flutter/material.dart';

class CsvHelper {
  static Future<void> exportTransactionsToCsv(BuildContext context, List<TransactionModel> transactions, String periodName) async {
    try {
      List<List<dynamic>> rows = [];
      // Header
      rows.add([
        "Date",
        "Type",
        "Category",
        "Amount",
        "Wallet",
        "Notes"
      ]);

      for (var tx in transactions) {
        rows.add([
          tx.date,
          tx.type,
          tx.categoryName,
          tx.amount,
          tx.walletName ?? tx.walletId ?? "", 
          tx.note 
        ]);
      }

      String csv = rows.map((row) => row.map((item) {
        String str = item.toString().replaceAll('"', '""');
        return '"$str"';
      }).join(',')).join('\n');

      final directory = await getApplicationDocumentsDirectory();
      final path = "${directory.path}/transactions_$periodName.csv";
      final file = File(path);
      await file.writeAsString(csv);

      // Using the currently available API in share_plus 13.x
      final result = await Share.shareXFiles([XFile(path)], text: 'Transactions for $periodName');
      
      if (result.status == ShareResultStatus.success) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Exported successfully!')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export: $e')),
        );
      }
    }
  }
}
