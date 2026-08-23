import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:transaction_note/models/user.dart';

const _collectionName = 'users';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late CollectionReference _collection;
  late CollectionReference<AppUser> _withConverter;

  UserService() {
    _collection = _firestore.collection(_collectionName);
    _withConverter = _collection.withConverter<AppUser>(
      fromFirestore: (snapshot, options) => AppUser.fromMap(snapshot.data()!),
      toFirestore: (user, options) => user.toMap(),
    );
  }

  // read single user based on uid
  Future<DocumentSnapshot<AppUser>> getUser(String uid) async {
    final doc = await _withConverter.doc(uid).get();
    return doc;
  }

  // stream single user based on uid
  Stream<AppUser?> getUserStream(String uid) {
    return _withConverter.doc(uid).snapshots().map((snapshot) => snapshot.data());
  }

  // to save user data to firestore and initialize defaults
  Future<void> saveUserData(User user) async {
    final docRef = _withConverter.doc(user.uid);
    final docSnap = await docRef.get();

    // Only create/overwrite if the user is new
    if (!docSnap.exists) {
      await docRef.set(
        AppUser(
          uid: user.uid,
          name: user.displayName ?? '',
          email: user.email ?? '',
          photoUrl: user.photoURL ?? '',
          createdAt: DateTime.now(),
          periodStartDay: null, // Will be set later via UI
        ),
      );

      // Create default "Other" categories for both types
      final categoriesRef = _firestore
          .collection(_collectionName)
          .doc(user.uid)
          .collection('categories');

      final otherExpense = {
        'userId': user.uid,
        'name': 'Other',
        'type': 'expense',
        'iconName': 'label',
        'createdAt': FieldValue.serverTimestamp(),
      };

      final otherIncome = {
        'userId': user.uid,
        'name': 'Other',
        'type': 'income',
        'iconName': 'label',
        'createdAt': FieldValue.serverTimestamp(),
      };

      await Future.wait([
        categoriesRef.doc('default_other_expense').set(otherExpense),
        categoriesRef.doc('default_other_income').set(otherIncome),
      ]);
    }
  }

  // update the user's period start day
  Future<void> updatePeriodStartDay(String uid, int day) async {
    await _collection.doc(uid).update({
      'periodStartDay': day,
    });
  }
}
