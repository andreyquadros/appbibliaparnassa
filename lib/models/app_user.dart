import 'streak_state.dart';

class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.denomination = 'Outro Evangélico',
    this.goals = const <String>[],
    this.xp = 0,
    this.manadas = 0,
    this.level = 1,
    this.title = 'Neófito',
    this.streak = const StreakState(),
    this.spiritualProfile = const SpiritualProfile(),
  });

  final String id;
  final String name;
  final String? avatarUrl;
  final String denomination;
  final List<String> goals;
  final int xp;
  final int manadas;
  final int level;
  final String title;
  final StreakState streak;
  final SpiritualProfile spiritualProfile;

  AppUser copyWith({
    String? id,
    String? name,
    String? avatarUrl,
    String? denomination,
    List<String>? goals,
    int? xp,
    int? manadas,
    int? level,
    String? title,
    StreakState? streak,
    SpiritualProfile? spiritualProfile,
  }) {
    return AppUser(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      denomination: denomination ?? this.denomination,
      goals: goals ?? this.goals,
      xp: xp ?? this.xp,
      manadas: manadas ?? this.manadas,
      level: level ?? this.level,
      title: title ?? this.title,
      streak: streak ?? this.streak,
      spiritualProfile: spiritualProfile ?? this.spiritualProfile,
    );
  }
}

class SpiritualProfile {
  const SpiritualProfile({
    this.topicScores = const <String, int>{},
    this.dominantTopics = const <SpiritualTopic>[],
    this.suggestedFocus = '',
    this.interactionCount = 0,
  });

  final Map<String, int> topicScores;
  final List<SpiritualTopic> dominantTopics;
  final String suggestedFocus;
  final int interactionCount;

  bool get hasSignals => dominantTopics.isNotEmpty || suggestedFocus.isNotEmpty;
}

class SpiritualTopic {
  const SpiritualTopic({
    required this.id,
    required this.label,
    required this.score,
  });

  final String id;
  final String label;
  final int score;
}
