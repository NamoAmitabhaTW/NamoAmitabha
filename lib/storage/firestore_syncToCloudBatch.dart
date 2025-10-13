/* //amitabha/lib/storage/firestore_syncToCloudBatch.dart
import 'package:amitabha/storage/models.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> syncToCloudBatch(SessionSnapshot s, String ymd, int delta) async {
  final db = FirebaseFirestore.instance;
  final batch = db.batch();

  final userRef = db.collection('users').doc(s.userId);
  final dailyRef = userRef.collection('daily').doc(ymd);
  final sessRef = userRef.collection('sessions').doc(s.sessionId);

  batch.set(dailyRef, {
    'schemaVersion': 1,
    'date': ymd,
    'userId': s.userId,
    'userName': s.userName,
    'amitabhaCount': FieldValue.increment(delta),
    'updatedAt':FieldValue.serverTimestamp(),
  },SetOptions(merge: true));

  batch.set(sessRef, {
    'schemaVersion': 1,
    'sessionId': s.sessionId,
    'userId': s.userId,
    'userName': s.userName,
    'startedAt': s.startedAt,
    'lastAt': s.lastAt,
    'amitabhaCount': s.amitabhaCount,
    'updatedAt': FieldValue.serverTimestamp(),
  },SetOptions(merge: true));

  await batch.commit();
} */