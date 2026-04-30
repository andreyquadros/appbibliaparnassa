import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_strings.dart';
import 'core/services/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/application/auth_controller.dart';
import 'features/study/application/study_controller.dart';

class PalavraVivaApp extends ConsumerStatefulWidget {
  const PalavraVivaApp({super.key});

  @override
  ConsumerState<PalavraVivaApp> createState() => _PalavraVivaAppState();
}

class _PalavraVivaAppState extends ConsumerState<PalavraVivaApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshDailyContentIfAuthenticated();
    }
  }

  void _refreshDailyContentIfAuthenticated() {
    if (ref.read(currentUserProvider) == null) return;
    ref.read(studyControllerProvider.notifier).refreshIfNeeded();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      routerConfig: router,
    );
  }
}
