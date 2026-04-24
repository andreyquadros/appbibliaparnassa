import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:palavra_viva/core/constants/app_colors.dart';
import 'package:palavra_viva/features/videos/data/christian_video_repository.dart';
import 'package:palavra_viva/shared/widgets/pv_scaffold.dart';

class VideosPage extends StatefulWidget {
  const VideosPage({super.key});

  @override
  State<VideosPage> createState() => _VideosPageState();
}

class _VideosPageState extends State<VideosPage> {
  final ChristianVideoRepository _repository = ChristianVideoRepository();
  late Future<List<ChannelVideosResult>> _videosFuture;

  @override
  void initState() {
    super.initState();
    _videosFuture = _repository.fetchAll(limit: 3);
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    final launched = await launchUrl(
      uri,
      mode: kIsWeb
          ? LaunchMode.platformDefault
          : LaunchMode.externalApplication,
      webOnlyWindowName: '_blank',
    );
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não conseguimos abrir este link agora. Tente novamente em instantes.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PvScaffold(
      title: 'Vídeos cristãos',
      showBackButton: true,
      body: FutureBuilder<List<ChannelVideosResult>>(
        future: _videosFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final results = snapshot.data ?? const <ChannelVideosResult>[];
          final featured =
              results.expand((item) => item.videos).toList(growable: false)
                ..sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
          final featuredDaily = featured.isEmpty
              ? null
              : featured[
                  DateTime.now().difference(DateTime(2026, 1, 1)).inDays %
                      featured.length
                ];

          return ListView(
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
                      'Vídeos cristãos recomendados',
                      style: Theme.of(
                        context,
                      ).textTheme.headlineSmall?.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Aqui reunimos canais confiáveis para te acompanhar com mensagens, estudos e reflexões durante a semana.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white.withValues(alpha: 0.84),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (kIsWeb && featuredDaily == null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Rodando no navegador',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Sim. No navegador, o YouTube costuma bloquear a leitura automática da lista de vídeos. Mesmo assim, você ainda pode abrir os canais e assistir normalmente em uma nova aba.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              if (kIsWeb && featuredDaily == null) const SizedBox(height: 12),
              if (featuredDaily != null) ...[
                Text(
                  'Vídeo em destaque de hoje',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _FeaturedVideoCard(
                    video: featuredDaily,
                    onTap: () => _openUrl(featuredDaily.watchUrl),
                  ),
                ),
                const SizedBox(height: 20),
              ],
              Text(
                'Canais recomendados',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 10),
              ...ChristianVideoRepository.channels.map((channel) {
                final result = results
                    .where((item) => item.channel == channel)
                    .firstOrNull;
                final videos = result?.videos ?? const <ChristianVideo>[];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ChannelSection(
                    channel: channel,
                    videos: videos,
                    helperText: result?.errorMessage,
                    onOpenChannel: () => _openUrl(channel.url),
                    onOpenVideo: (video) => _openUrl(video.watchUrl),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

class _FeaturedVideoCard extends StatelessWidget {
  const _FeaturedVideoCard({required this.video, required this.onTap});

  final ChristianVideo video;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Ink(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(22),
              ),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  video.thumbnailUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    color: AppColors.surfaceTint,
                    alignment: Alignment.center,
                    child: const Icon(Icons.ondemand_video_rounded),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video.channel.name,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.secondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    video.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatDate(video.publishedAt),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChannelSection extends StatelessWidget {
  const _ChannelSection({
    required this.channel,
    required this.videos,
    required this.onOpenChannel,
    required this.onOpenVideo,
    this.helperText,
  });

  final ChristianChannel channel;
  final List<ChristianVideo> videos;
  final String? helperText;
  final VoidCallback onOpenChannel;
  final ValueChanged<ChristianVideo> onOpenVideo;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        channel.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        videos.isNotEmpty
                            ? 'Uploads recentes do canal'
                            : 'Abra o canal para ver os vídeos diretamente no YouTube',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: onOpenChannel,
                  icon: const Icon(Icons.open_in_new_rounded, size: 16),
                  label: const Text('Canal'),
                ),
              ],
            ),
            if (helperText != null) ...[
              const SizedBox(height: 8),
              Text(
                helperText!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ],
            const SizedBox(height: 12),
            if (videos.isEmpty)
              const ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.ondemand_video_outlined),
                title: Text('Abra este canal para assistir'),
                subtitle: Text(
                  'O conteúdo continua disponível normalmente no YouTube.',
                ),
              )
            else
              ...videos.map(
                (video) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 86,
                      child: Image.network(
                        video.thumbnailUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          color: AppColors.surfaceTint,
                          alignment: Alignment.center,
                          child: const Icon(Icons.ondemand_video_rounded),
                        ),
                      ),
                    ),
                  ),
                  title: Text(
                    video.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(_formatDate(video.publishedAt)),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => onOpenVideo(video),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

String _formatDate(DateTime value) {
  return DateFormat('dd MMM yyyy').format(value.toLocal());
}
