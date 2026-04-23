import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../models/fast_entry.dart';

class FastingRepository {
  FastingRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _collection(String userId) {
    return _firestore.collection('users').doc(userId).collection('fasts');
  }

  Stream<List<FastEntry>> watchEntries(String userId) {
    return _collection(
      userId,
    ).orderBy('startedAt', descending: true).snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) {
            final data = doc.data();
            return FastEntry(
              id: doc.id,
              type: _type(data['type']),
              durationHours: _int(data['durationHours'], 1),
              purpose: _string(data['purpose'], ''),
              verse: _string(data['verse'], ''),
              startedAt: _date(data['startedAt']) ?? DateTime.now(),
              completedAt: _date(data['completedAt']),
              testimony: _nullableString(data['testimony']),
            );
          })
          .toList(growable: false);
    });
  }

  Future<void> start({
    required String userId,
    required FastType type,
    required int durationHours,
    required String purpose,
    required String verse,
  }) async {
    await _collection(userId).add(<String, dynamic>{
      'type': type.name,
      'durationHours': durationHours,
      'purpose': purpose.trim(),
      'verse': verse.trim(),
      'startedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> complete({
    required String userId,
    required String fastId,
    required String testimony,
  }) async {
    await _collection(userId).doc(fastId).set(<String, dynamic>{
      'completedAt': FieldValue.serverTimestamp(),
      'testimony': testimony.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  FastType _type(Object? value) {
    final raw = value is String ? value.trim().toLowerCase() : '';
    return FastType.values.firstWhere(
      (item) => item.name == raw,
      orElse: () => FastType.parcial,
    );
  }

  int _int(Object? value, int fallback) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return fallback;
  }

  String _string(Object? value, String fallback) {
    final text = value is String ? value.trim() : '';
    return text.isEmpty ? fallback : text;
  }

  String? _nullableString(Object? value) {
    final text = value is String ? value.trim() : '';
    return text.isEmpty ? null : text;
  }

  DateTime? _date(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
