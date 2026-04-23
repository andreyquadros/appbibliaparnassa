import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../models/ranking_entry.dart';
import '../domain/ranking_period.dart';

class RankingRepository {
  RankingRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<List<RankingEntry>> watchEntries(
    RankingPeriod period, {
    String? currentUserId,
  }) {
    switch (period) {
      case RankingPeriod.weekly:
      case RankingPeriod.friends:
        return _watchWeekly();
      case RankingPeriod.monthly:
        return _watchUsersBy('monthXp');
      case RankingPeriod.allTime:
        return _watchUsersBy('xp');
    }
  }

  Stream<List<RankingEntry>> _watchWeekly() {
    final weekKey = _weekKey(DateTime.now());
    return _firestore
        .collection('weeklyRankings')
        .doc(weekKey)
        .collection('entries')
        .orderBy('score', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) {
          var pos = 1;
          return snapshot.docs
              .map((doc) {
                final data = doc.data();
                return RankingEntry(
                  userId: _string(data['userId'], doc.id),
                  name: _string(data['displayName'], 'Discípulo'),
                  avatarUrl: _nullableString(data['photoUrl']),
                  level: _int(data['level'], 1),
                  streak: _int(data['streak']),
                  weekXp: _int(data['score']),
                  position: _int(data['rank'], pos++),
                  delta: _int(data['delta']),
                );
              })
              .toList(growable: false);
        });
  }

  Stream<List<RankingEntry>> _watchUsersBy(String field) {
    return _firestore
        .collection('users')
        .orderBy(field, descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) {
          var pos = 1;
          return snapshot.docs
              .map((doc) {
                final data = doc.data();
                final streak =
                    (data['streak'] as Map?)?.cast<String, dynamic>() ??
                    const <String, dynamic>{};
                return RankingEntry(
                  userId: doc.id,
                  name: _string(data['displayName'], 'Discípulo'),
                  avatarUrl: _nullableString(data['photoUrl']),
                  level: _int(data['level'], 1),
                  streak: _int(streak['studyStreak']),
                  weekXp: _int(data[field]),
                  position: pos++,
                  delta: 0,
                );
              })
              .toList(growable: false);
        });
  }

  String _weekKey(DateTime date) {
    final utc = DateTime.utc(date.year, date.month, date.day);
    final day = (utc.weekday + 6) % 7;
    final monday = utc.subtract(Duration(days: day));
    return monday.toIso8601String().substring(0, 10);
  }

  int _int(Object? value, [int fallback = 0]) {
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
}
