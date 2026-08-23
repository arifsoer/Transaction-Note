import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:enum_to_string/enum_to_string.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:transaction_note/models/transaction.dart';
import '../models/category.dart';
import 'auth_provider.dart';

final categoryServiceProvider = Provider<CategoryService>((ref) {
  return CategoryService();
});

final categoriesStreamProvider = StreamProvider<List<CategoryModel>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) {
    return Stream.value([]);
  }
  
  final categoryService = ref.watch(categoryServiceProvider);
  return categoryService.getCategoriesStream(user.uid);
});

class CategoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  Stream<List<CategoryModel>> getCategoriesStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('categories')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CategoryModel.fromJson(doc.data(), doc.id))
            .toList());
  }

  Future<void> addCategory(String userId, String name, TransactionType type, String iconName, [double budget = 0.0]) async {
    final category = CategoryModel(
      id: '',
      userId: userId,
      name: name,
      type: type,
      iconName: iconName,
      budget: budget,
      createdAt: DateTime.now(),
    );
    
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('categories')
        .add(category.toJson());
  }

  Future<void> updateCategory(String userId, String categoryId, String name, TransactionType type, String iconName, [double budget = 0.0]) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('categories')
        .doc(categoryId)
        .update({
      'name': name,
      'type': EnumToString.convertToString(type),
      'iconName': iconName,
      'budget': budget,
    });
  }

  Future<void> deleteCategory(String userId, String categoryId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('categories')
        .doc(categoryId)
        .delete();
  }
}
