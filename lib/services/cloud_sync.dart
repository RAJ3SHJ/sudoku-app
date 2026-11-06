import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/progress.dart';

/// Backs up progress to Cloud Firestore at users/{uid}.
///
/// Firestore keeps working offline: writes made without internet are queued
/// on the phone and sent when the connection returns.
/// Security rules (firestore.rules) let each player read and write only
/// their own document.
class CloudSync {
  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      FirebaseFirestore.instance.collection('users').doc(uid);

  Future<Progress?> fetch(String uid) async {
    final snap = await _doc(uid).get();
    final data = snap.data();
    return data == null ? null : Progress.fromJson(data);
  }

  Future<void> push(String uid, Progress progress) => _doc(uid).set({
        ...progress.toJson(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

  Future<void> delete(String uid) => _doc(uid).delete();
}
