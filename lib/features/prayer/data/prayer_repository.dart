import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../../../models/prayer_entry.dart';

class PrayerRepository {
  PrayerRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _collection(String userId) {
    return _firestore.collection('users').doc(userId).collection('prayers');
  }

  DocumentReference<Map<String, dynamic>> _dailyPrayerRef(
    String userId,
    DateTime date,
  ) {
    final dateKey = DateFormat('yyyy-MM-dd').format(date);
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('prayerLogs')
        .doc(dateKey);
  }

  Stream<List<PrayerEntry>> watchEntries(String userId) {
    return _collection(
      userId,
    ).orderBy('createdAt', descending: true).snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) {
            final data = doc.data();
            return PrayerEntry(
              id: doc.id,
              title: _string(data['title'], 'Pedido de oração'),
              content: _string(data['content'], ''),
              verse: _string(data['verse'], ''),
              status: _string(data['status'], 'believing') == 'answered'
                  ? PrayerStatus.answered
                  : PrayerStatus.believing,
              createdAt: _date(data['createdAt']) ?? DateTime.now(),
              answeredAt: _date(data['answeredAt']),
            );
          })
          .toList(growable: false);
    });
  }

  Future<void> add({
    required String userId,
    required String title,
    required String content,
    required String verse,
  }) async {
    await _collection(userId).add(<String, dynamic>{
      'title': title.trim(),
      'content': content.trim(),
      'verse': verse.trim(),
      'status': 'believing',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> markToday({required String userId}) async {
    await _dailyPrayerRef(userId, DateTime.now()).set(<String, dynamic>{
      'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
      'markedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'title': 'Orei hoje',
    }, SetOptions(merge: true));
  }

  Future<void> markAnswered({
    required String userId,
    required String prayerId,
  }) async {
    await _collection(userId).doc(prayerId).set(<String, dynamic>{
      'status': 'answered',
      'answeredAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  String _string(Object? value, String fallback) {
    final text = value is String ? value.trim() : '';
    return text.isEmpty ? fallback : text;
  }

  DateTime? _date(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
