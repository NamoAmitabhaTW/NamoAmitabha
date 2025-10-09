import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/app_user.dart';

class FirestoreUserRepository {
  final _db = FirebaseFirestore.instance;

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
}
