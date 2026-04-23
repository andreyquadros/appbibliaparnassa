import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/app_user.dart';
import '../../../models/community_post.dart';
import '../../auth/application/auth_controller.dart';
import '../data/community_repository.dart';

class CommunityController {
  CommunityController(this.ref, this._repository);

  final Ref ref;
  final CommunityRepository _repository;

  Future<void> publish({required String comment, required String verse}) async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      throw Exception('Usuário não autenticado.');
    }
    await _repository.publish(
      userId: user.id,
      author: _authorName(user),
      verse: verse,
      comment: comment,
    );
  }

  String _authorName(AppUser user) {
    final name = user.name.trim();
    if (name.isEmpty) {
      return 'Discípulo';
    }
    return name;
  }
}

final communityRepositoryProvider = Provider<CommunityRepository>((ref) {
  return CommunityRepository();
});

final communityControllerProvider = Provider<CommunityController>((ref) {
  return CommunityController(ref, ref.watch(communityRepositoryProvider));
});

final communityFeedProvider = StreamProvider<List<CommunityPost>>((ref) {
  return ref.watch(communityRepositoryProvider).watchFeed();
});
