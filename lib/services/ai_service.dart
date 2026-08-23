import 'dart:convert';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:transaction_note/models/category.dart';
import 'package:transaction_note/models/wallet.dart';

class AiService {
  Future<List<Map<String, dynamic>>> parseTransaction({
    required String statement,
    required List<CategoryModel> categories,
    required List<WalletModel> wallets,
  }) async {
    final firebaseAI = FirebaseAI.googleAI();

    final model = firebaseAI.generativeModel(
      model: 'gemini-2.5-flash',
      generationConfig: GenerationConfig(responseMimeType: 'application/json'),
    );

    final categoryContext = categories
        .map(
          (c) =>
              '{"id": "${c.id}", "name": "${c.name}", "type": "${c.type.name}"}',
        )
        .join(',\n');
    final walletContext = wallets
        .map((w) => '{"id": "${w.id}", "name": "${w.name}"}')
        .join(',\n');
    final currentDate = DateTime.now().toIso8601String();

    final prompt =
        '''
You are an intelligent transaction parser.
Your task is to parse the following user statement which may contain multiple transactions, and convert it into a strictly valid JSON array of objects.

Current Date/Time: $currentDate

Available Categories (JSON array of objects):
[
$categoryContext
]

Available Wallets (JSON array of objects):
[
$walletContext
]

Instructions:
1. "date": Determine the date of the transaction in "yyyy-MM-dd" format. If the user says "yesterday", calculate it based on the Current Date. If "today" or no mention, use the Current Date.
2. "amount": Extract the amount as a number (double). Remove any currency symbols or formatting.
3. "note": Extract a short description of the transaction (e.g. "Lunch", "Salary").
4. "type": Determine if it is an "expense" or "income".
5. "category_id": Find the best matching category from the Available Categories list based on the "type" and "note". Return the EXACT "id" string of that category. If no match is found, return null.
6. "wallet_id": Find the best matching wallet from the Available Wallets list. Return the EXACT "id" string. If none matches or none is specified, return null.

The output must be a valid JSON array of objects. Each object must have the exact keys: "date", "amount", "note", "type", "category_id", "wallet_id". If there's only one transaction, still return it in an array.
Do not wrap it in markdown code blocks. Just the raw JSON.

User Statement: "$statement"
''';

    final content = [Content.text(prompt)];
    final response = await model.generateContent(content);

    if (response.text != null) {
      try {
        String jsonText = response.text!.trim();
        // Fallback in case the model ignores responseMimeType and wraps in markdown
        if (jsonText.startsWith('```json')) {
          jsonText = jsonText.replaceFirst('```json', '');
          if (jsonText.endsWith('```')) {
            jsonText = jsonText.substring(0, jsonText.length - 3);
          }
        }
        final List<dynamic> decoded = jsonDecode(jsonText.trim());
        return decoded.map((e) => e as Map<String, dynamic>).toList();
      } catch (e) {
        throw Exception('Failed to parse AI response: $e');
      }
    }

    throw Exception('AI returned an empty response');
  }
}
