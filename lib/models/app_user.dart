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
    );
  }
}
