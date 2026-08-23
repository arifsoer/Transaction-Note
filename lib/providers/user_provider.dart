import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:transaction_note/models/user.dart';
import 'package:transaction_note/providers/auth_provider.dart';

final currentUserProvider = FutureProvider<AppUser?>((ref) async {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return null;
  
  final service = ref.read(userServiceProvider);
  final doc = await service.getUser(user.uid);
  return doc.data();
});

// Stream provider to get live updates of user data
final currentUserStreamProvider = StreamProvider<AppUser?>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value(null);

  final service = ref.read(userServiceProvider);
  // Need to use the raw firestore stream for updates
  return service.getUserStream(user.uid);
});
