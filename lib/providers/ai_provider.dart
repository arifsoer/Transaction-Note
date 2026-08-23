import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:transaction_note/services/ai_service.dart';

final aiServiceProvider = Provider<AiService>((ref) {
  return AiService();
});
