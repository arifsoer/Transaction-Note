import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transaction.dart';
import 'auth_provider.dart';

final transactionServiceProvider = Provider<TransactionService>((ref) {
  return TransactionService(ref: ref);
});

final transactionsStreamProvider = StreamProvider<List<TransactionModel>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) {
    return Stream.value([]);
  }
  
  final transactionService = ref.watch(transactionServiceProvider);
  return transactionService.getTransactionsStream(user.uid);
});

class TransactionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Ref ref;

  TransactionService({required this.ref});
  
  Stream<List<TransactionModel>> getTransactionsStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('transactions')
        // We order by 'date' but date is string (YYYY-MM-DD), so descending ordering works lexicographically
        .orderBy('date', descending: true) 
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TransactionModel.fromJson(doc.data(), doc.id))
            .toList());
  }

  Future<String> addTransaction(String userId, TransactionModel transaction) async {
    final docRef = await _firestore
        .collection('users')
        .doc(userId)
        .collection('transactions')
        .add(transaction.toJson());
    return docRef.id;
  }

  Future<void> updateTransaction(String userId, String transactionId, TransactionModel transaction) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('transactions')
        .doc(transactionId)
        .update(transaction.toJson());
  }

  Future<void> deleteTransaction(String userId, String transactionId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('transactions')
        .doc(transactionId)
        .delete();
  }
}
