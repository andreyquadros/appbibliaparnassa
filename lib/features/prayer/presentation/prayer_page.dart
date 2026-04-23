import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../features/fasting/application/fasting_controller.dart';
import '../../../models/fast_entry.dart';
import '../../../models/prayer_entry.dart';
import '../../../shared/widgets/main_bottom_nav_bar.dart';
import '../../../shared/widgets/pv_scaffold.dart';
import '../application/prayer_controller.dart';

class PrayerPage extends ConsumerStatefulWidget {
  const PrayerPage({super.key});

  @override
  ConsumerState<PrayerPage> createState() => _PrayerPageState();
}

class _PrayerPageState extends ConsumerState<PrayerPage> {
  bool _submitting = false;

  Future<void> _openAddDialog() async {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    final verseController = TextEditingController(text: 'Filipenses 4:6');
    final dialogTheme = Theme.of(context).copyWith(
      dialogTheme: const DialogThemeData(backgroundColor: Color(0xFF262C39)),
      inputDecorationTheme: const InputDecorationTheme(
        filled: false,
        labelStyle: TextStyle(color: Colors.white70),
        hintStyle: TextStyle(color: Colors.white54),
        floatingLabelStyle: TextStyle(color: AppColors.accent),
        prefixIconColor: Colors.white70,
        suffixIconColor: Colors.white70,
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white38),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.accent, width: 1.8),
        ),
      ),
      textTheme: Theme.of(
        context,
      ).textTheme.apply(bodyColor: Colors.white, displayColor: Colors.white),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: const Color(0xFFAEC5FF)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFFAEC5FF),
          foregroundColor: AppColors.primary,
        ),
      ),
    );

    await showDialog<void>(
      context: context,
      builder: (context) => Theme(
        data: dialogTheme,
        child: AlertDialog(
          title: const Text(
            'Novo pedido de oração',
            style: TextStyle(color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: titleController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Título'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: verseController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Versículo'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: contentController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Pedido'),
                  minLines: 2,
                  maxLines: 4,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () async {
                final navigator = Navigator.of(context);
                final title = titleController.text.trim();
                final verse = verseController.text.trim();
                final content = contentController.text.trim();
                if (title.isEmpty || verse.isEmpty || content.isEmpty) {
                  return;
                }

                setState(() => _submitting = true);
                try {
                  await ref
                      .read(prayerActionsProvider)
                      .addPrayer(title: title, content: content, verse: verse);
                  if (!mounted) return;
                  navigator.pop();
                } finally {
                  if (mounted) {
                    setState(() => _submitting = false);
                  }
                }
              },
              child: Text(_submitting ? 'Salvando...' : 'Salvar'),
            ),
          ],
        ),
      ),
    );

    titleController.dispose();
    verseController.dispose();
    contentController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prayersAsync = ref.watch(prayerEntriesProvider);
    final fastsAsync = ref.watch(fastingEntriesProvider);
    final showBack = Navigator.of(context).canPop();

    return PvScaffold(
      title: 'Diário Espiritual',
      showBackButton: showBack,
      bottomNavigationBar: const MainBottomNavBar(current: MainSection.diary),
      body: ListView(
        children: [
          Text(
            '"Consagrem um jejum, convoquem uma assembleia solene..."',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(fontStyle: FontStyle.italic),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Text(
                'Jejum Atual',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => context.push(AppRoutes.fasting),
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('Editar'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          fastsAsync.when(
            data: (entries) {
              if (entries.isEmpty) {
                return const Card(
                  child: ListTile(
                    title: Text('Nenhum jejum em andamento'),
                    subtitle: Text(
                      'Abra a seção Jejum para iniciar um novo ciclo.',
                    ),
                  ),
                );
              }
              final active = entries.firstWhere(
                (item) => !item.isCompleted,
                orElse: () => entries.first,
              );
              return _FastingSummaryCard(entry: active);
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
                child: Text('Falha ao carregar jejum: $error'),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Text(
                'Pedidos de Oração',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const Spacer(),
              FilledButton.tonalIcon(
                onPressed: _submitting ? null : _openAddDialog,
                icon: const Icon(Icons.add),
                label: const Text('Nova Oração'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          prayersAsync.when(
            data: (entries) {
              if (entries.isEmpty) {
                return const Card(
                  child: ListTile(
                    title: Text('Sem pedidos ainda'),
                    subtitle: Text('Adicione seu primeiro pedido de oração.'),
                  ),
                );
              }

              final believing = entries
                  .where((entry) => entry.status == PrayerStatus.believing)
                  .toList(growable: false);
              final answered = entries
                  .where((entry) => entry.status == PrayerStatus.answered)
                  .toList(growable: false);

              return Column(
                children: [
                  ...believing.map((entry) => _PrayerTile(entry: entry)),
                  ...answered.map((entry) => _PrayerTile(entry: entry)),
                ],
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
                child: Text('Falha ao carregar pedidos: $error'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FastingSummaryCard extends StatelessWidget {
  const _FastingSummaryCard({required this.entry});

  final FastEntry entry;

  @override
  Widget build(BuildContext context) {
    final elapsed = DateTime.now().difference(entry.startedAt);
    final elapsedHours = elapsed.inHours.clamp(0, entry.durationHours);
    final ratio = entry.durationHours <= 0
        ? 0.0
        : (elapsedHours / entry.durationHours).clamp(0.0, 1.0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Propósito',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                letterSpacing: 1.1,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Jejum ${entry.type.name[0].toUpperCase()}${entry.type.name.substring(1)}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 6),
            Text(entry.purpose, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  'Dia ${elapsed.inDays + 1}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                Text(
                  '${entry.durationHours}h totais',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 4,
                color: AppColors.secondary,
                backgroundColor: AppColors.border,
              ),
            ),
            const SizedBox(height: 10),
            Text(entry.verse, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _PrayerTile extends ConsumerWidget {
  const _PrayerTile({required this.entry});

  final PrayerEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final answered = entry.status == PrayerStatus.answered;
    final dateText = DateFormat('dd MMM yyyy').format(entry.createdAt);

    return Card(
      color: answered ? AppColors.surfaceTint : AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: answered
                        ? AppColors.accent.withValues(alpha: 0.3)
                        : AppColors.surfaceTint,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    answered ? 'Respondida' : 'Em oração',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
                const SizedBox(width: 10),
                Text(dateText, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 10),
            Text(entry.title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 6),
            Text(entry.content, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 8),
            Text(entry.verse, style: Theme.of(context).textTheme.bodySmall),
            if (!answered) ...[
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () =>
                    ref.read(prayerActionsProvider).markAnswered(entry.id),
                icon: const Icon(Icons.check),
                label: const Text('Marcar como respondida'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
