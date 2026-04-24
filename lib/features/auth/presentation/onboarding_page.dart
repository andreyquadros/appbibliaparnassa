import 'package:flutter/material.dart';

import 'package:palavra_viva/core/constants/app_colors.dart';
import 'package:palavra_viva/shared/branding/palavra_viva_logo.dart';

class OnboardingStepData {
  const OnboardingStepData({
    required this.title,
    required this.description,
    required this.icon,
    required this.imagePath,
    required this.footer,
    this.imageAlignment = Alignment.center,
  });

  final String title;
  final String description;
  final IconData icon;
  final String imagePath;
  final String footer;
  final Alignment imageAlignment;
}

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({
    super.key,
    this.steps = const [
      OnboardingStepData(
        title: 'Uma jornada viva',
        description:
            'Construa hábitos espirituais consistentes com leitura, meditação e revisão.',
        icon: Icons.waving_hand_outlined,
        imagePath: 'assets/branding/onboard1.png',
        footer:
            'O Parnassá foi pensado para uma vida devocional prática, bonita e perseverante.',
        imageAlignment: Alignment.topCenter,
      ),
      OnboardingStepData(
        title: 'Estudo com profundidade',
        description:
            'Leia a Bíblia, receba contexto, explicações e converse com o texto.',
        icon: Icons.menu_book_outlined,
        imagePath: 'assets/branding/onboard2.png',
        footer:
            'Receba contexto bíblico com clareza para estudar além da superfície.',
        imageAlignment: Alignment.center,
      ),
      OnboardingStepData(
        title: 'Memória espiritual',
        description:
            'Guarde versículos com flashcards e revisões para lembrar no tempo certo.',
        icon: Icons.style_outlined,
        imagePath: 'assets/branding/onboard3.png',
        footer:
            'Revise no ritmo certo e transforme leitura em lembrança duradoura.',
        imageAlignment: Alignment.centerRight,
      ),
      OnboardingStepData(
        title: 'Disciplina diária',
        description:
            'Acompanhe oração, jejum e pequenas metas que fortalecem a constância.',
        icon: Icons.self_improvement_outlined,
        imagePath: 'assets/branding/onboard4.png',
        footer:
            'Pequenos compromissos diários constroem profundidade e perseverança.',
        imageAlignment: Alignment.centerRight,
      ),
      OnboardingStepData(
        title: 'Comunhão e progresso',
        description:
            'Partilhe com a comunidade, avance em ritmo saudável e celebre sua evolução.',
        icon: Icons.groups_outlined,
        imagePath: 'assets/branding/onboard5.png',
        footer:
            'Cresça com companhia, encorajamento e passos reais de maturidade.',
        imageAlignment: Alignment.center,
      ),
    ],
    this.onFinish,
  });

  final List<OnboardingStepData> steps;
  final VoidCallback? onFinish;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  late final PageController _controller;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_index == widget.steps.length - 1) {
      widget.onFinish?.call();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const PalavraVivaLogo(size: 48, compact: true),
                  const Spacer(),
                  TextButton(
                    onPressed: widget.onFinish,
                    child: const Text('Pular'),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                'Comece com intenção',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Cada passo foi desenhado para caber na rotina e aprofundar sua caminhada.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Text(
                    '${_index + 1}/${widget.steps.length}',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.secondary,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: (_index + 1) / widget.steps.length,
                        minHeight: 5,
                        color: AppColors.secondary,
                        backgroundColor: AppColors.border,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 26),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: widget.steps.length,
                  onPageChanged: (value) => setState(() => _index = value),
                  itemBuilder: (context, index) {
                    final item = widget.steps[index];
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeOutCubic,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(34),
                        border: Border.all(color: AppColors.secondary),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            blurRadius: 26,
                            offset: const Offset(0, 14),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(34),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.asset(
                                  item.imagePath,
                                  fit: BoxFit.cover,
                                  alignment: item.imageAlignment,
                                ),
                                DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.black.withValues(alpha: 0.08),
                                        Colors.black.withValues(alpha: 0.28),
                                        Colors.black.withValues(alpha: 0.72),
                                      ],
                                      stops: const [0, 0.45, 1],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            top: 18,
                            left: 18,
                            child: Container(
                              width: 68,
                              height: 68,
                              decoration: BoxDecoration(
                                color: const Color(0xCC0F2346),
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(color: AppColors.secondary),
                              ),
                              child: Icon(
                                item.icon,
                                size: 34,
                                color: AppColors.accent,
                              ),
                            ),
                          ),
                          Positioned(
                            left: 18,
                            right: 18,
                            bottom: 18,
                            child: Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: const Color(0xAA091833),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.12),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Passo ${index + 1}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelLarge
                                        ?.copyWith(
                                          color: AppColors.accent,
                                          letterSpacing: 0.9,
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    item.title,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(color: Colors.white),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    item.description,
                                    style: Theme.of(context).textTheme.bodyLarge
                                        ?.copyWith(
                                          color: Colors.white.withValues(
                                            alpha: 0.9,
                                          ),
                                          height: 1.65,
                                        ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    item.footer,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: AppColors.accent,
                                          letterSpacing: 0.25,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  if (_index > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          _controller.previousPage(
                            duration: const Duration(milliseconds: 280),
                            curve: Curves.easeOutCubic,
                          );
                        },
                        child: const Text('Voltar'),
                      ),
                    ),
                  if (_index > 0) const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _next,
                      child: Text(
                        _index == widget.steps.length - 1
                            ? 'Começar'
                            : 'Próximo',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
