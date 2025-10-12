//amitabha/lib/features/auth/data/firestore_user_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/app_user.dart';

class FirestoreUserRepository {
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  Future<void> upsertUserDocFromModel(AppUser user) async {
    final ref = _db.collection('users').doc(user.uid);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final base = {
        ...user.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (!snap.exists) {
        tx.set(ref, {
          ...base,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        tx.update(ref, base);
      }
    });
  }

  Future<void> deleteAllUserData(String uid) async {
    final userRef = _db.collection('users').doc(uid);

    Future<void> _deleteCollection(CollectionReference coll, {int batchSize = 300}) async {
      while (true) {
        final snap = await coll.limit(batchSize).get();
        if (snap.docs.isEmpty) break;
        final batch = _db.batch();
        for (final d in snap.docs) {
          batch.delete(d.reference);
        }
        await batch.commit();
        await Future.delayed(const Duration(milliseconds: 50));
      }
    }

    await _deleteCollection(userRef.collection('daily'));
    await _deleteCollection(userRef.collection('sessions'));

    try {
      await userRef.delete();
    } catch (_) {}
  }
}
