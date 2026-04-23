import 'package:flutter/material.dart';

import 'package:palavra_viva/core/constants/app_colors.dart';
import 'package:palavra_viva/core/constants/app_strings.dart';
import 'package:palavra_viva/core/services/bible_api_service.dart';
import 'package:palavra_viva/shared/widgets/main_bottom_nav_bar.dart';
import 'package:palavra_viva/shared/widgets/manadas_balance_chip.dart';
import 'package:palavra_viva/shared/widgets/pv_scaffold.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({
    super.key,
    this.userName = 'Discípulo',
    this.dailyVerse =
        'Lâmpada para os meus pés é a tua palavra e luz para o meu caminho.',
    this.dailyReference = 'Salmos 119:105',
    this.manadas = 120,
    this.level = 1,
    this.currentXp = 0,
    this.nextLevelXp = 500,
    this.studyStreak = 0,
    this.prayerStreak = 0,
    this.fastingStreak = 0,
    this.onOpenStudy,
    this.onOpenVideos,
    this.onOpenFlashcards,
    this.onOpenQuiz,
    this.onOpenPrayer,
    this.onOpenFasting,
    this.onOpenCommunity,
    this.onOpenRanking,
    this.onOpenRewards,
    this.onOpenNotifications,
    this.onOpenProfile,
  });

  final String userName;
  final String dailyVerse;
  final String dailyReference;
  final int manadas;
  final int level;
  final int currentXp;
  final int nextLevelXp;
  final int studyStreak;
  final int prayerStreak;
  final int fastingStreak;
  final VoidCallback? onOpenStudy;
  final VoidCallback? onOpenVideos;
  final VoidCallback? onOpenFlashcards;
  final VoidCallback? onOpenQuiz;
  final VoidCallback? onOpenPrayer;
  final VoidCallback? onOpenFasting;
  final VoidCallback? onOpenCommunity;
  final VoidCallback? onOpenRanking;
  final VoidCallback? onOpenRewards;
  final VoidCallback? onOpenNotifications;
  final VoidCallback? onOpenProfile;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final BibleApiService _bibleApiService = BibleApiService();
  late Future<String> _verseFuture;

  @override
  void initState() {
    super.initState();
    _verseFuture = _loadDailyVerse();
  }

  @override
  void didUpdateWidget(covariant DashboardPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dailyReference != widget.dailyReference ||
        oldWidget.dailyVerse != widget.dailyVerse) {
      _verseFuture = _loadDailyVerse();
    }
  }

  Future<String> _loadDailyVerse() async {
    final fallback = widget.dailyVerse.trim();
    final reference = widget.dailyReference.trim();
    if (reference.isEmpty) {
      return fallback.isEmpty ? 'Versículo não disponível.' : fallback;
    }
    try {
      final passage = await _bibleApiService.fetchPassage(reference);
      final directText = passage.verses.isNotEmpty
          ? passage.verses.first.text.trim()
          : passage.text.trim();
      if (directText.isNotEmpty) {
        return directText;
      }
      return fallback.isNotEmpty ? fallback : 'Versículo não disponível.';
    } catch (_) {
      return fallback.isNotEmpty ? fallback : 'Versículo não disponível.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.nextLevelXp <= 0
        ? 0.0
        : (widget.currentXp / widget.nextLevelXp).clamp(0.0, 1.0);
    final readingDay = widget.studyStreak <= 0 ? 1 : widget.studyStreak;

    return PvScaffold(
      title: AppStrings.appName,
      actions: [
        IconButton(
          onPressed: widget.onOpenNotifications,
          icon: const Icon(Icons.notifications_none_rounded),
        ),
        IconButton(
          onPressed: widget.onOpenProfile,
          icon: const Icon(Icons.account_circle_outlined),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Center(child: ManadasBalanceChip(balance: widget.manadas)),
        ),
      ],
      bottomNavigationBar: const MainBottomNavBar(
        current: MainSection.dashboard,
      ),
      body: ListView(
        children: [
          Text(
            'Que a paz esteja contigo,',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 2),
          Text(
            widget.userName,
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 22),
          _SectionLabel(title: 'Jornada Anual', trailing: 'Dia $readingDay'),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              color: AppColors.secondary,
              backgroundColor: AppColors.border,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.bookmark,
                size: 14,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Hoje: ${widget.dailyReference}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              TextButton(
                onPressed: widget.onOpenStudy,
                child: const Text('Ler agora'),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Container(
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: AppColors.secondary, width: 1.4),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.18),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.auto_awesome,
                        size: 18,
                        color: AppColors.accent,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Palavra do dia',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppColors.accent,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  FutureBuilder<String>(
                    future: _verseFuture,
                    builder: (context, snapshot) {
                      final verse = snapshot.data?.trim();
                      if (snapshot.connectionState == ConnectionState.waiting &&
                          (verse == null || verse.isEmpty)) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final text = verse?.isNotEmpty == true
                          ? verse!
                          : 'Versículo não disponível.';
                      return Text(
                        '"$text"',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontStyle: FontStyle.italic,
                              height: 1.45,
                            ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.dailyReference.toUpperCase(),
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: AppColors.accent,
                                letterSpacing: 1.0,
                              ),
                        ),
                      ),
                      IconButton(
                        onPressed: widget.onOpenFlashcards,
                        color: Colors.white,
                        icon: const Icon(Icons.bookmark_border),
                      ),
                      IconButton(
                        onPressed: widget.onOpenQuiz,
                        color: Colors.white,
                        icon: const Icon(Icons.share_outlined),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 26),
          Text(
            'Disciplinas Espirituais',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _DisciplineCard(
                  icon: Icons.self_improvement_outlined,
                  title: 'Oração',
                  subtitle: '${widget.prayerStreak} dias de consistência',
                  value: '${widget.prayerStreak}d',
                  onTap: widget.onOpenPrayer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DisciplineCard(
                  icon: Icons.restaurant_outlined,
                  title: 'Jejum',
                  subtitle: '${widget.fastingStreak} dias acumulados',
                  value: '${widget.fastingStreak}d',
                  onTap: widget.onOpenFasting,
                ),
              ),
            ],
          ),
          const SizedBox(height: 26),
          Text('Ferramentas', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 10),
          _ToolTile(
            icon: Icons.auto_stories_outlined,
            title: 'Estudo Bíblico',
            subtitle: 'Comentários, explicação e chat contextual',
            onTap: widget.onOpenStudy,
          ),
          const SizedBox(height: 10),
          _ToolTile(
            icon: Icons.ondemand_video_outlined,
            title: 'Vídeos cristãos',
            subtitle: 'Canais recomendados com vídeos recentes para edificação',
            onTap: widget.onOpenVideos,
          ),
          const SizedBox(height: 10),
          _ToolTile(
            icon: Icons.style_outlined,
            title: 'Flashcards',
            subtitle: 'Memorização com revisão espaçada',
            onTap: widget.onOpenFlashcards,
          ),
          const SizedBox(height: 10),
          _ToolTile(
            icon: Icons.quiz_outlined,
            title: 'Quiz',
            subtitle: 'Teste de fixação do estudo do dia',
            onTap: widget.onOpenQuiz,
          ),
          const SizedBox(height: 26),
          Text(
            'Comunhão e Avanço',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 10),
          _ToolTile(
            icon: Icons.groups_2_outlined,
            title: 'Comunidade',
            subtitle: 'Compartilhe pedidos, testemunhos e versículos',
            onTap: widget.onOpenCommunity,
          ),
          const SizedBox(height: 10),
          _ToolTile(
            icon: Icons.leaderboard_outlined,
            title: 'Ranking',
            subtitle: 'Acompanhe sua constância e compare progresso',
            onTap: widget.onOpenRanking,
          ),
          const SizedBox(height: 10),
          _ToolTile(
            icon: Icons.workspace_premium_outlined,
            title: 'Recompensas',
            subtitle: 'Troque suas parnassas por novos conteúdos',
            onTap: widget.onOpenRewards,
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title, required this.trailing});

  final String title;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title.toUpperCase(),
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            letterSpacing: 1.8,
            color: AppColors.textSecondary,
          ),
        ),
        const Spacer(),
        Text(
          trailing,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(color: AppColors.secondary),
        ),
      ],
    );
  }
}

class _DisciplineCard extends StatelessWidget {
  const _DisciplineCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String value;
  final VoidCallback? onTap;

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
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surfaceTint,
                  border: Border.all(color: AppColors.border),
                ),
                child: Icon(icon, color: AppColors.secondary, size: 18),
              ),
              const SizedBox(height: 14),
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 2),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 14),
              Text(
                value,
                style: Theme.of(
                  context,
                ).textTheme.headlineSmall?.copyWith(color: AppColors.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToolTile extends StatelessWidget {
  const _ToolTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: ListTile(
          leading: Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surfaceTint,
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          title: Text(title, style: Theme.of(context).textTheme.titleMedium),
          subtitle: Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          trailing: const Icon(Icons.chevron_right),
        ),
      ),
    );
  }
}
