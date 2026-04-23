import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:palavra_viva/core/constants/app_colors.dart';
import 'package:palavra_viva/shared/widgets/pv_scaffold.dart';

import '../application/community_controller.dart';

class CommunityPage extends ConsumerStatefulWidget {
  const CommunityPage({super.key});

  @override
  ConsumerState<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends ConsumerState<CommunityPage> {
  final _commentController = TextEditingController();
  final _verseController = TextEditingController();
  bool _publishing = false;

  @override
  void dispose() {
    _commentController.dispose();
    _verseController.dispose();
    super.dispose();
  }

  Future<void> _publish() async {
    final comment = _commentController.text.trim();
    final verse = _verseController.text.trim();
    if (comment.isEmpty || verse.isEmpty) return;

    setState(() => _publishing = true);
    try {
      await ref
          .read(communityControllerProvider)
          .publish(comment: comment, verse: verse);
      if (!mounted) return;
      _commentController.clear();
      _verseController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Publicação enviada para a comunidade.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Falha ao publicar: $error')));
    } finally {
      if (mounted) {
        setState(() => _publishing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final feedAsync = ref.watch(communityFeedProvider);

    return PvScaffold(
      title: 'Comunidade',
      body: ListView(
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppColors.secondary),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Compartilhe o que Deus falou com você',
                  style: Theme.of(
                    context,
                  ).textTheme.headlineSmall?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 10),
                Text(
                  'Versículos, pedidos e testemunhos ganham vida quando a comunidade caminha junta.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.88),
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  TextField(
                    controller: _verseController,
                    decoration: const InputDecoration(
                      labelText: 'Versículo',
                      hintText: 'Ex: Romanos 8:1',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _commentController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText:
                          'Compartilhe um aprendizado, oração ou testemunho...',
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _publishing ? null : _publish,
                      child: Text(_publishing ? 'Publicando...' : 'Publicar'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Feed da comunidade',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 10),
          feedAsync.when(
            data: (posts) {
              if (posts.isEmpty) {
                return const Card(
                  child: ListTile(
                    title: Text('Sem publicações ainda'),
                    subtitle: Text(
                      'Seja o primeiro a compartilhar um versículo.',
                    ),
                  ),
                );
              }
              return Column(
                children: posts
                    .map(
                      (post) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const CircleAvatar(
                                      radius: 18,
                                      backgroundColor: AppColors.surfaceTint,
                                      child: Icon(
                                        Icons.person_outline_rounded,
                                        color: AppColors.primary,
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            post.author,
                                            style: Theme.of(
                                              context,
                                            ).textTheme.titleMedium,
                                          ),
                                          Text(
                                            DateFormat(
                                              'dd/MM HH:mm',
                                            ).format(post.createdAt),
                                            style: Theme.of(
                                              context,
                                            ).textTheme.labelMedium,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  post.verse,
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(color: AppColors.secondary),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  post.comment,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.bodyLarge?.copyWith(height: 1.7),
                                ),
                                const SizedBox(height: 14),
                                Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  children: [
                                    _Badge(
                                      icon: Icons.favorite_border,
                                      label: '${post.amemCount} amém',
                                    ),
                                    _Badge(
                                      icon: Icons.volunteer_activism_outlined,
                                      label: '${post.prayedCount} orou',
                                    ),
                                    _Badge(
                                      icon: Icons.lightbulb_outline,
                                      label: '${post.edifiedCount} edificou',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(growable: false),
              );
            },
            loading: () => const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
            error: (error, _) => Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Falha ao carregar comunidade: $error'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceTint,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
    );
  }
}
