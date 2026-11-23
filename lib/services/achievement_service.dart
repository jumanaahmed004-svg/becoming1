import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/achievement.dart';

/// All Firestore CRUD lives here. Every query uses the signed-in user's UID,
/// so each user only ever reads and writes their own achievements.
class AchievementService {
  AchievementService(this.uid);
  final String uid;

  CollectionReference<Map<String, dynamic>> get _col =>
      FirebaseFirestore.instance.collection('users').doc(uid).collection('achievements');

  // READ: live list, newest first.
  Stream<List<Achievement>> watch() => _col
      .orderBy('achievementDate', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map(Achievement.fromDoc).toList());

  // CREATE
  Future<void> create(Achievement a) => _col.add({
        ...a.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

  // UPDATE (full edit)
  Future<void> update(Achievement a) =>
      _col.doc(a.id).update({...a.toMap(), 'updatedAt': FieldValue.serverTimestamp()});

  // UPDATE (quick status toggle from the card)
  Future<void> setStatus(String id, String status, {DateTime? date}) => _col.doc(id).update({
        'status': status,
        if (date != null) 'achievementDate': Timestamp.fromDate(date),
        'updatedAt': FieldValue.serverTimestamp(),
      });

  // DELETE
  Future<void> delete(String id) => _col.doc(id).delete();

  // Used by "Undo" after a delete: writes the record back with the same id.
  Future<void> restore(Achievement a) => _col.doc(a.id).set({
        ...a.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
}
