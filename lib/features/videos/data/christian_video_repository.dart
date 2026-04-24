import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../core/services/firebase_service.dart';

class ChristianChannel {
  const ChristianChannel({
    required this.name,
    required this.url,
    required this.channelId,
  });

  final String name;
  final String url;
  final String channelId;
}

class ChristianVideo {
  const ChristianVideo({
    required this.channel,
    required this.videoId,
    required this.title,
    required this.publishedAt,
  });

  final ChristianChannel channel;
  final String videoId;
  final String title;
  final DateTime publishedAt;

  String get watchUrl => 'https://www.youtube.com/watch?v=$videoId';
  String get thumbnailUrl => 'https://i.ytimg.com/vi/$videoId/hqdefault.jpg';
}

class ChannelVideosResult {
  const ChannelVideosResult({
    required this.channel,
    required this.videos,
    this.errorMessage,
  });

  final ChristianChannel channel;
  final List<ChristianVideo> videos;
  final String? errorMessage;

  bool get hasVideos => videos.isNotEmpty;
}

class ChristianVideoRepository {
  ChristianVideoRepository({http.Client? client, FirebaseFunctions? functions})
    : _client = client ?? http.Client(),
      _functions = functions ?? FirebaseService.functions;

  final http.Client _client;
  final FirebaseFunctions _functions;

  static const channels = <ChristianChannel>[
    ChristianChannel(
      name: 'Pastor Antônio Júnior',
      url: 'https://www.youtube.com/@prantoniojunior',
      channelId: 'UCKEM87jzVqdIfAdTr0xNBfA',
    ),
    ChristianChannel(
      name: 'Luciano Subirá',
      url: 'https://www.youtube.com/@lucianosubira',
      channelId: 'UCczPEsycoDKpG9ImCAnZSmg',
    ),
    ChristianChannel(
      name: 'JesusCopy',
      url: 'https://www.youtube.com/@jesus_copy',
      channelId: 'UC3PawQOWA2PJwnEqYkH7vHA',
    ),
    ChristianChannel(
      name: 'Helena Tannure',
      url: 'https://www.youtube.com/@HelenaTannure',
      channelId: 'UCjy56REvtTIQ5dxSYhYWj5A',
    ),
    ChristianChannel(
      name: 'Pastor Teo Hayashi',
      url: 'https://www.youtube.com/@teo.hayashi',
      channelId: 'UC6GGgZdIkwL7pvVo8PDWnbA',
    ),
    ChristianChannel(
      name: 'Pastor Elizeu Rodrigues',
      url: 'https://www.youtube.com/@pastorelizeurodrigues',
      channelId: 'UCcqO2S6IQU5ldiARtG5RPSQ',
    ),
    ChristianChannel(
      name: 'Pastor Hernandes Dias Lopes',
      url: 'https://www.youtube.com/@HernandesDiasLopesOficial',
      channelId: 'UCT8yKUrnFmq5COl15dasxog',
    ),
    ChristianChannel(
      name: 'Pastor Rodrigo Silva',
      url: 'https://www.youtube.com/@RodrigoSilvaArqueologia',
      channelId: 'UCTsZnZQmLpGh6GK-GyI4GoA',
    ),
    ChristianChannel(
      name: 'Israel com Aline',
      url: 'https://www.youtube.com/@IsraelcomAline',
      channelId: 'UCnDg9ffODoLqBB7ks3_re6Q',
    ),
  ];

  Future<List<ChannelVideosResult>> fetchAll({int limit = 3}) async {
    final remote = await _fetchFromCloud(limit: limit);
    if (remote.isNotEmpty && remote.any((item) => item.hasVideos)) {
      return remote;
    }

    final result = <ChannelVideosResult>[];
    for (final channel in channels) {
      result.add(await fetchChannel(channel, limit: limit));
    }
    return result;
  }

  Future<List<ChannelVideosResult>> _fetchFromCloud({int limit = 3}) async {
    try {
      final callable = _functions.httpsCallable('fetchChristianVideos');
      final response = await callable.call(<String, dynamic>{'limit': limit});
      final data = response.data as Map?;
      final items = (data?['channels'] as List?) ?? const [];
      return items
          .whereType<Map>()
          .map((raw) => _fromCloudItem(Map<String, dynamic>.from(raw), limit))
          .toList(growable: false);
    } catch (_) {
      return const <ChannelVideosResult>[];
    }
  }

  Future<ChannelVideosResult> fetchChannel(
    ChristianChannel channel, {
    int limit = 3,
  }) async {
    try {
      final uri = Uri.parse(
        'https://www.youtube.com/feeds/videos.xml?channel_id=${channel.channelId}',
      );
      final response = await _client.get(uri);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return ChannelVideosResult(
          channel: channel,
          videos: const <ChristianVideo>[],
          errorMessage: 'Não conseguimos carregar os vídeos deste canal agora.',
        );
      }

      final body = utf8.decode(response.bodyBytes);
      final entries = RegExp(r'<entry>([\s\S]*?)</entry>').allMatches(body);
      final videos = <ChristianVideo>[];
      for (final match in entries.take(limit)) {
        final entry = match.group(1) ?? '';
        final videoId = _extract(entry, r'<yt:videoId>(.*?)</yt:videoId>');
        final title = _decodeXml(_extract(entry, r'<title>(.*?)</title>'));
        final publishedText = _extract(entry, r'<published>(.*?)</published>');
        if (videoId.isEmpty || title.isEmpty || publishedText.isEmpty) {
          continue;
        }
        final publishedAt = DateTime.tryParse(publishedText) ?? DateTime.now();
        videos.add(
          ChristianVideo(
            channel: channel,
            videoId: videoId,
            title: title,
            publishedAt: publishedAt,
          ),
        );
      }

      return ChannelVideosResult(channel: channel, videos: videos);
    } catch (_) {
      return ChannelVideosResult(
        channel: channel,
        videos: const <ChristianVideo>[],
        errorMessage: kIsWeb
            ? 'No navegador, o YouTube pode bloquear a leitura automática dos vídeos. Você ainda pode abrir o canal normalmente.'
            : 'Não conseguimos carregar os vídeos deste canal agora.',
      );
    }
  }

  String _extract(String input, String pattern) {
    final match = RegExp(pattern).firstMatch(input);
    return match?.group(1)?.trim() ?? '';
  }

  String _decodeXml(String value) {
    return value
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>');
  }

  ChannelVideosResult _fromCloudItem(Map<String, dynamic> raw, int limit) {
    final channelId = (raw['channelId'] as String?)?.trim() ?? '';
    final fallbackChannel = channels.firstWhere(
      (item) => item.channelId == channelId,
      orElse: () => ChristianChannel(
        name: (raw['channelName'] as String?)?.trim() ?? 'Canal cristão',
        url: (raw['channelUrl'] as String?)?.trim() ?? '',
        channelId: channelId,
      ),
    );
    final videos = ((raw['videos'] as List?) ?? const [])
        .whereType<Map>()
        .take(limit)
        .map((video) {
          final parsed = Map<String, dynamic>.from(video);
          return ChristianVideo(
            channel: fallbackChannel,
            videoId: (parsed['videoId'] as String?)?.trim() ?? '',
            title: (parsed['title'] as String?)?.trim() ?? 'Vídeo',
            publishedAt:
                DateTime.tryParse(
                  (parsed['publishedAt'] as String?)?.trim() ?? '',
                ) ??
                DateTime.now(),
          );
        })
        .where((video) => video.videoId.isNotEmpty)
        .toList(growable: false);

    return ChannelVideosResult(
      channel: fallbackChannel,
      videos: videos,
      errorMessage: (raw['errorMessage'] as String?)?.trim(),
    );
  }
}
