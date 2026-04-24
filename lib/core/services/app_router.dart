import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../features/activities/presentation/quiz_page.dart';
import '../../features/auth/application/auth_controller.dart';
import '../../features/auth/presentation/login_page.dart';
import '../../features/auth/presentation/onboarding_page.dart';
import '../../features/bible/presentation/bible_page.dart';
import '../../features/community/presentation/community_page.dart';
import '../../features/dashboard/presentation/dashboard_page.dart';
import '../../features/fasting/presentation/fasting_page.dart';
import '../../features/flashcards/presentation/flashcards_page.dart';
import '../../features/notifications/presentation/notifications_page.dart';
import '../../features/prayer/presentation/prayer_page.dart';
import '../../features/profile/application/profile_controller.dart';
import '../../features/profile/presentation/profile_page.dart';
import '../../features/profile/presentation/saved_items_page.dart';
import '../../features/ranking/presentation/ranking_page.dart';
import '../../features/rewards/presentation/rewards_page.dart';
import '../../features/study/application/study_controller.dart';
import '../../features/study/presentation/study_page.dart';
import '../../features/videos/presentation/videos_page.dart';
import '../constants/gamification.dart';
import '../constants/app_routes.dart';
import '../widgets/splash_gate_page.dart';

int _nextLevelTarget(int currentXp) {
  for (final level in GamificationTable.levels) {
    if (currentXp < level.maxXp) {
      return level.maxXp;
    }
  }
  return currentXp + 1;
}

CustomTransitionPage<void> _buildTransitionPage(
  GoRouterState state,
  Widget child,
) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 320),
    reverseTransitionDuration: const Duration(milliseconds: 240),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );

      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.03, 0),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final authForRedirect = ref.watch(
    authControllerProvider.select(
      (state) => (
        isAuthenticated: state.isAuthenticated,
        onboardingCompleted: state.onboardingCompleted,
      ),
    ),
  );

  return GoRouter(
    initialLocation: AppRoutes.splash,
    redirect: (context, state) {
      final location = state.uri.path;
      final isSplash = location == AppRoutes.splash;
      final isOnboarding = location == AppRoutes.onboarding;
      final isLogin = location == AppRoutes.login;

      if (authForRedirect.isAuthenticated) {
        if (isSplash || isLogin || isOnboarding) {
          return AppRoutes.dashboard;
        }
        return null;
      }

      if (isSplash) {
        return authForRedirect.onboardingCompleted
            ? AppRoutes.login
            : AppRoutes.onboarding;
      }

      if (!authForRedirect.onboardingCompleted && !isOnboarding) {
        return AppRoutes.onboarding;
      }

      if (authForRedirect.onboardingCompleted && !isLogin && !isOnboarding) {
        return AppRoutes.login;
      }

      return null;
    },
    routes: <GoRoute>[
      GoRoute(
        path: AppRoutes.splash,
        pageBuilder: (context, state) =>
            _buildTransitionPage(state, const SplashGatePage()),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        pageBuilder: (context, state) => _buildTransitionPage(
          state,
          OnboardingPage(
            onFinish: () async {
              await ref
                  .read(authControllerProvider.notifier)
                  .completeOnboarding();
              if (context.mounted) {
                context.go(AppRoutes.login);
              }
            },
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.login,
        pageBuilder: (context, state) => _buildTransitionPage(
          state,
          LoginPage(
            onLogin: (email, password) async {
              await ref
                  .read(authControllerProvider.notifier)
                  .loginWithEmail(email: email, password: password);
              if (context.mounted) {
                context.go(AppRoutes.dashboard);
              }
            },
            onCreateAccount: (email, password) async {
              await ref
                  .read(authControllerProvider.notifier)
                  .registerWithEmail(email: email, password: password);
              if (context.mounted) {
                context.go(AppRoutes.dashboard);
              }
            },
            onGoogleSignIn: () async {
              final success = await ref
                  .read(authControllerProvider.notifier)
                  .signInWithGoogle();
              if (success && context.mounted) {
                context.go(AppRoutes.dashboard);
              }
            },
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.dashboard,
        pageBuilder: (context, state) => _buildTransitionPage(
          state,
          Consumer(
            builder: (context, routeRef, _) {
              final auth = routeRef.watch(authControllerProvider);
              final studyAsync = routeRef.watch(studyControllerProvider);
              final todayStudy = studyAsync.asData?.value;

              final verseFallback = studyAsync.isLoading
                  ? 'Carregando versículo...'
                  : 'Versículo não disponível.';

              return DashboardPage(
                userName: auth.user?.name ?? 'Discípulo',
                dailyVerse: todayStudy?.memoryVerse ?? verseFallback,
                dailyReference: todayStudy?.passage ?? 'Salmos 119:105',
                manadas: auth.user?.manadas ?? 0,
                level: auth.user?.level ?? 1,
                currentXp: auth.user?.xp ?? 0,
                nextLevelXp: _nextLevelTarget(auth.user?.xp ?? 0),
                studyStreak: auth.user?.streak.studyStreak ?? 0,
                prayerStreak: auth.user?.streak.prayerStreak ?? 0,
                fastingStreak: auth.user?.streak.fastingStreak ?? 0,
                onOpenStudy: () => context.push(AppRoutes.study),
                onOpenVideos: () => context.push(AppRoutes.videos),
                onOpenFlashcards: () => context.push(AppRoutes.flashcards),
                onOpenQuiz: () => context.push(AppRoutes.quiz),
                onOpenPrayer: () => context.push(AppRoutes.prayer),
                onOpenFasting: () => context.push(AppRoutes.fasting),
                onOpenCommunity: () => context.push(AppRoutes.community),
                onOpenRanking: () => context.push(AppRoutes.ranking),
                onOpenRewards: () => context.push(AppRoutes.rewards),
                onOpenNotifications: () =>
                    context.push(AppRoutes.notifications),
                onOpenProfile: () => context.push(AppRoutes.profile),
                onSaveDailyWord: todayStudy == null
                    ? null
                    : () async {
                        final user = routeRef.read(currentUserProvider);
                        if (user == null) {
                          return 'Entre na sua conta para salvar palavras.';
                        }
                        final added = await routeRef
                            .read(savedItemsRepositoryProvider)
                            .saveItem(
                              userId: user.id,
                              title: 'Palavra do dia',
                              reference: todayStudy.passage,
                              excerpt: todayStudy.memoryVerse,
                              category: 'palavra_do_dia',
                            );
                        return added
                            ? 'Palavra do dia salva no perfil.'
                            : 'Essa palavra já estava salva no perfil.';
                      },
                onShareDailyWord: todayStudy == null
                    ? null
                    : () {
                        Share.share(
                          '${todayStudy.passage}\n\n${todayStudy.memoryVerse}',
                          subject: 'Palavra do dia',
                        );
                      },
              );
            },
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.bible,
        pageBuilder: (context, state) =>
            _buildTransitionPage(state, const BiblePage()),
      ),
      GoRoute(
        path: AppRoutes.videos,
        pageBuilder: (context, state) =>
            _buildTransitionPage(state, const VideosPage()),
      ),
      GoRoute(
        path: AppRoutes.flashcards,
        pageBuilder: (context, state) =>
            _buildTransitionPage(state, const FlashcardsPage()),
      ),
      GoRoute(
        path: AppRoutes.study,
        pageBuilder: (context, state) => _buildTransitionPage(
          state,
          StudyPage(
            onCompleteStudy: () {
              ref.read(studyControllerProvider.notifier).completeTodayStudy();
              context.go(AppRoutes.dashboard);
            },
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.quiz,
        pageBuilder: (context, state) =>
            _buildTransitionPage(state, const QuizPage()),
      ),
      GoRoute(
        path: AppRoutes.prayer,
        pageBuilder: (context, state) =>
            _buildTransitionPage(state, const PrayerPage()),
      ),
      GoRoute(
        path: AppRoutes.fasting,
        pageBuilder: (context, state) =>
            _buildTransitionPage(state, const FastingPage()),
      ),
      GoRoute(
        path: AppRoutes.ranking,
        pageBuilder: (context, state) =>
            _buildTransitionPage(state, const RankingPage()),
      ),
      GoRoute(
        path: AppRoutes.rewards,
        pageBuilder: (context, state) {
          final auth = ref.watch(authControllerProvider);
          return _buildTransitionPage(
            state,
            RewardsPage(balance: auth.user?.manadas ?? 0),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.profile,
        pageBuilder: (context, state) {
          final auth = ref.watch(authControllerProvider);
          return _buildTransitionPage(
            state,
            ProfilePage(
              name: auth.user?.name ?? 'Discípulo',
              email: FirebaseAuth.instance.currentUser?.email ?? '-',
              balance: auth.user?.manadas ?? 0,
              level: auth.user?.level ?? 1,
              currentXp: auth.user?.xp ?? 0,
              nextLevelXp: _nextLevelTarget(auth.user?.xp ?? 0),
              studyStreak: auth.user?.streak.studyStreak ?? 0,
              prayerStreak: auth.user?.streak.prayerStreak ?? 0,
              fastingStreak: auth.user?.streak.fastingStreak ?? 0,
              onOpenSavedItems: () => context.push(AppRoutes.savedItems),
              onLogout: () {
                ref.read(authControllerProvider.notifier).logout().then((_) {
                  if (context.mounted) {
                    context.go(AppRoutes.login);
                  }
                });
              },
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.savedItems,
        pageBuilder: (context, state) =>
            _buildTransitionPage(state, const SavedItemsPage()),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        pageBuilder: (context, state) =>
            _buildTransitionPage(state, const NotificationsPage()),
      ),
      GoRoute(
        path: AppRoutes.community,
        pageBuilder: (context, state) =>
            _buildTransitionPage(state, const CommunityPage()),
      ),
    ],
  );
});
