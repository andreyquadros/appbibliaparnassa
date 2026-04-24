import 'package:cloud_firestore/cloud_firestore.dart';

class DailyQuizProgress {
  const DailyQuizProgress({
    required this.dateId,
    required this.completed,
    required this.score,
    required this.questionsAnswered,
    this.completedAt,
  });

  final String dateId;
  final bool completed;
  final int score;
  final int questionsAnswered;
  final DateTime? completedAt;
}

class DailyQuizRepository {
  DailyQuizRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _doc(String userId, String dateId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('dailyQuizProgress')
        .doc(dateId);
  }

  Stream<DailyQuizProgress?> watchProgress(String userId, String dateId) {
    return _doc(userId, dateId).snapshots().map((snapshot) {
      final data = snapshot.data();
      if (!snapshot.exists || data == null) {
        return null;
      }
      return DailyQuizProgress(
        dateId: dateId,
        completed: data['completed'] == true,
        score: _asInt(data['score']),
        questionsAnswered: _asInt(data['questionsAnswered']),
        completedAt: _asDate(data['completedAt']),
      );
    });
  }

  Future<void> complete({
    required String userId,
    required String dateId,
    required int score,
    required int questionsAnswered,
  }) async {
    await _doc(userId, dateId).set(<String, dynamic>{
      'dateId': dateId,
      'completed': true,
      'score': score,
      'questionsAnswered': questionsAnswered,
      'completedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return 0;
  }

  DateTime? _asDate(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
