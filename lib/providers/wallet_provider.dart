import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/wallet.dart';
import 'auth_provider.dart';

final walletServiceProvider = Provider<WalletService>((ref) {
  return WalletService();
});

final walletsStreamProvider = StreamProvider<List<WalletModel>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) {
    return Stream.value([]);
  }
  
  final walletService = ref.watch(walletServiceProvider);
  return walletService.getWalletsStream(user.uid);
});

class WalletService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  Stream<List<WalletModel>> getWalletsStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('wallets')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => WalletModel.fromJson(doc.data(), doc.id))
            .toList());
  }

  Future<void> addWallet(String userId, String name) async {
    final wallet = WalletModel(
      id: '',
      userId: userId,
      name: name,
      createdAt: DateTime.now(),
    );
    
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('wallets')
        .add(wallet.toJson());
  }

  Future<void> updateWallet(String userId, String walletId, String newName) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('wallets')
        .doc(walletId)
        .update({
      'name': newName,
    });
  }

  Future<void> deleteWallet(String userId, String walletId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('wallets')
        .doc(walletId)
        .delete();
  }
}
