import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../models/reward_item.dart';

class RewardsRepository {
  RewardsRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<List<RewardItem>> watchCatalog() {
    return _firestore
        .collection('rewards')
        .where('isActive', isEqualTo: true)
        .orderBy('sortOrder')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) {
                final data = doc.data();
                return RewardItem(
                  id: doc.id,
                  title: _string(data['title'], 'Conteúdo'),
                  description: _string(data['description'], ''),
                  tier: _int(data['tier'], 1),
                  manadasCost: _int(data['manadasCost']),
                  category: _string(data['category'], 'Geral'),
                  preview: _string(data['preview'], ''),
                );
              })
              .toList(growable: false);
        });
  }

  Stream<Set<String>> watchUnlockedIds(String userId) {
    return _firestore.collection('users').doc(userId).snapshots().map((
      snapshot,
    ) {
      final data = snapshot.data();
      final ids = (data?['unlockedRewardIds'] as List?) ?? const [];
      return ids.whereType<String>().toSet();
    });
  }

  Future<bool> unlock({
    required String userId,
    required RewardItem reward,
  }) async {
    final userRef = _firestore.collection('users').doc(userId);

    return _firestore.runTransaction((transaction) async {
      final userSnap = await transaction.get(userRef);
      final userData = userSnap.data() ?? const <String, dynamic>{};
      final balance = _int(userData['manadas']);
      final unlocked = ((userData['unlockedRewardIds'] as List?) ?? const [])
          .whereType<String>()
          .toSet();

      if (unlocked.contains(reward.id)) {
        return true;
      }
      if (balance < reward.manadasCost) {
        return false;
      }

      transaction.update(userRef, <String, dynamic>{
        'manadas': balance - reward.manadasCost,
        'unlockedRewardIds': FieldValue.arrayUnion([reward.id]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    });
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
}
