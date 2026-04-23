import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/app_user.dart';
import '../../models/streak_state.dart';
import '../constants/gamification.dart';

class UserProfileRepository {
  UserProfileRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _userRef(String uid) {
    return _firestore.collection('users').doc(uid);
  }

  Future<AppUser> ensureUser(User user) async {
    final ref = _userRef(user.uid);
    final snapshot = await ref.get();
    final fallbackName = (user.displayName?.trim().isNotEmpty ?? false)
        ? user.displayName!.trim()
        : (user.email?.split('@').first.trim().isNotEmpty ?? false)
        ? user.email!.split('@').first.trim()
        : 'Discípulo';

    if (!snapshot.exists) {
      final levelInfo = GamificationTable.levelForXp(0);
      final now = FieldValue.serverTimestamp();
      await ref.set(<String, dynamic>{
        'displayName': fallbackName,
        'photoUrl': user.photoURL,
        'email': user.email,
        'denomination': 'Outro Evangélico',
        'goals': const <String>[],
        'xp': 0,
        'weekXp': 0,
        'monthXp': 0,
        'manadas': 0,
        'level': levelInfo.level,
        'title': levelInfo.title,
        'streak': <String, dynamic>{
          'studyStreak': 0,
          'prayerStreak': 0,
          'fastingStreak': 0,
          'availableFreeze': 1,
        },
        'unlockedRewardIds': const <String>[],
        'createdAt': now,
        'updatedAt': now,
      });
      final created = await ref.get();
      return _fromMap(user.uid, created.data() ?? const <String, dynamic>{});
    }

    await ref.set(<String, dynamic>{
      'displayName': snapshot.data()?['displayName'] ?? fallbackName,
      'photoUrl': user.photoURL ?? snapshot.data()?['photoUrl'],
      'email': user.email ?? snapshot.data()?['email'],
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return _fromMap(user.uid, snapshot.data() ?? const <String, dynamic>{});
  }

  Stream<AppUser> watchUser(String uid) {
    return _userRef(uid).snapshots().map((snapshot) {
      final data = snapshot.data();
      if (data == null) {
        return const AppUser(id: 'guest', name: 'Convidado');
      }
      return _fromMap(uid, data);
    });
  }

  Future<void> saveUser(AppUser user) async {
    await _userRef(user.id).set(_toMap(user), SetOptions(merge: true));
  }

  AppUser _fromMap(String uid, Map<String, dynamic> data) {
    final xp = _asInt(data['xp']);
    final levelInfo = GamificationTable.levelForXp(xp);
    final streakData =
        (data['streak'] as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{};

    return AppUser(
      id: uid,
      name: _asString(data['displayName'], 'Discípulo'),
      avatarUrl: _nullableString(data['photoUrl']),
      denomination: _asString(data['denomination'], 'Outro Evangélico'),
      goals: _asStringList(data['goals']),
      xp: xp,
      manadas: _asInt(data['manadas']),
      level: _asInt(data['level'], levelInfo.level),
      title: _asString(data['title'], levelInfo.title),
      streak: StreakState(
        studyStreak: _asInt(streakData['studyStreak']),
        prayerStreak: _asInt(streakData['prayerStreak']),
        fastingStreak: _asInt(streakData['fastingStreak']),
        lastStudyDate: _asDate(streakData['lastStudyDate']),
        lastPrayerDate: _asDate(streakData['lastPrayerDate']),
        lastFastDate: _asDate(streakData['lastFastDate']),
        availableFreeze: _asInt(streakData['availableFreeze'], 1),
      ),
    );
  }

  Map<String, dynamic> _toMap(AppUser user) {
    return <String, dynamic>{
      'displayName': user.name,
      'photoUrl': user.avatarUrl,
      'denomination': user.denomination,
      'goals': user.goals,
      'xp': user.xp,
      'weekXp': user.xp,
      'monthXp': user.xp,
      'manadas': user.manadas,
      'level': user.level,
      'title': user.title,
      'streak': <String, dynamic>{
        'studyStreak': user.streak.studyStreak,
        'prayerStreak': user.streak.prayerStreak,
        'fastingStreak': user.streak.fastingStreak,
        'lastStudyDate': user.streak.lastStudyDate,
        'lastPrayerDate': user.streak.lastPrayerDate,
        'lastFastDate': user.streak.lastFastDate,
        'availableFreeze': user.streak.availableFreeze,
      },
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  int _asInt(Object? value, [int fallback = 0]) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return fallback;
  }

  String _asString(Object? value, String fallback) {
    final text = value is String ? value.trim() : '';
    return text.isEmpty ? fallback : text;
  }

  String? _nullableString(Object? value) {
    final text = value is String ? value.trim() : '';
    return text.isEmpty ? null : text;
  }

  List<String> _asStringList(Object? value) {
    if (value is! List) return const <String>[];
    return value
        .whereType<String>()
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  DateTime? _asDate(Object? value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    return null;
  }
}
