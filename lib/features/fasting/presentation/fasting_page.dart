import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:palavra_viva/core/constants/app_colors.dart';
import 'package:palavra_viva/models/fast_entry.dart';
import 'package:palavra_viva/shared/widgets/pv_scaffold.dart';

import '../application/fasting_controller.dart';

class FastingPage extends ConsumerStatefulWidget {
  const FastingPage({super.key});

  @override
  ConsumerState<FastingPage> createState() => _FastingPageState();
}

class _FastingPageState extends ConsumerState<FastingPage> {
  FastType _type = FastType.parcial;
  final _hoursController = TextEditingController(text: '12');
  final _purposeController = TextEditingController();
  final _verseController = TextEditingController(text: 'Mateus 6:17-18');
  bool _submitting = false;

  @override
  void dispose() {
    _hoursController.dispose();
    _purposeController.dispose();
    _verseController.dispose();
    super.dispose();
  }

  Future<void> _startFast() async {
    final hours = int.tryParse(_hoursController.text.trim()) ?? 0;
    final purpose = _purposeController.text.trim();
    final verse = _verseController.text.trim();
    if (hours <= 0 || purpose.isEmpty || verse.isEmpty) return;

    setState(() => _submitting = true);
    try {
      await ref
          .read(fastingActionsProvider)
          .startFast(
            type: _type,
            durationHours: hours,
            purpose: purpose,
            verse: verse,
          );
      if (!mounted) return;
      _purposeController.clear();
      _hoursController.text = '12';
      _verseController.text = 'Mateus 6:17-18';
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jejum registrado com sucesso.')),
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final entriesAsync = ref.watch(fastingEntriesProvider);
    final darkFormTheme = Theme.of(context).copyWith(
      inputDecorationTheme: const InputDecorationTheme(
        filled: false,
        labelStyle: TextStyle(color: Colors.white70),
        hintStyle: TextStyle(color: Colors.white54),
        floatingLabelStyle: TextStyle(color: AppColors.accent),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white38),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.accent, width: 1.8),
        ),
      ),
    );

    return PvScaffold(
      title: 'Jejum',
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
                  'Diário de consagração',
                  style: Theme.of(
                    context,
                  ).textTheme.headlineSmall?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 10),
                Text(
                  'Organize seus propósitos, acompanhe jejuns ativos e registre testemunhos ao concluir cada período.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.88),
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          entriesAsync.when(
            data: (entries) {
              FastEntry? activeEntry;
              for (final entry in entries) {
                if (!entry.isCompleted) {
                  activeEntry = entry;
                  break;
                }
              }

              if (activeEntry == null) {
                return Card(
                  child: ListTile(
                    leading: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceTint,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.local_fire_department_outlined),
                    ),
                    title: const Text('Nenhum jejum ativo'),
                    subtitle: const Text(
                      'Registre um propósito abaixo para começar sua próxima jornada.',
                    ),
                  ),
                );
              }

              return _ActiveFastCard(entry: activeEntry);
            },
            loading: () => const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
            error: (error, _) => Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Falha ao carregar jejuns: $error'),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            color: AppColors.primary,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Theme(
                data: darkFormTheme,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Novo propósito',
                      style: Theme.of(
                        context,
                      ).textTheme.titleLarge?.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<FastType>(
                      initialValue: _type,
                      dropdownColor: const Color(0xFF262C39),
                      style: const TextStyle(color: Colors.white),
                      iconEnabledColor: Colors.white70,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de jejum',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: FastType.parcial,
                          child: Text(
                            'Parcial',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        DropdownMenuItem(
                          value: FastType.total,
                          child: Text(
                            'Total',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        DropdownMenuItem(
                          value: FastType.daniel,
                          child: Text(
                            'Daniel',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _type = value);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _hoursController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Duração (horas)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _verseController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Versículo base',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _purposeController,
                      style: const TextStyle(color: Colors.white),
                      minLines: 3,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'Propósito',
                        hintText:
                            'Ex: clareza, consagração, intercessão pela família...',
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _submitting ? null : _startFast,
                        icon: const Icon(Icons.bolt_outlined),
                        label: Text(
                          _submitting ? 'Salvando...' : 'Registrar jejum',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Histórico', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 10),
          entriesAsync.when(
            data: (entries) {
              if (entries.isEmpty) {
                return const Card(
                  child: ListTile(
                    title: Text('Nenhum jejum registrado'),
                    subtitle: Text('Seus registros aparecerão aqui.'),
                  ),
                );
              }
              return Column(
                children: entries
                    .map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _FastTile(entry: entry),
                      ),
                    )
                    .toList(growable: false),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (error, _) => Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Falha ao carregar jejuns: $error'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveFastCard extends StatelessWidget {
  const _ActiveFastCard({required this.entry});

  final FastEntry entry;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Jejum atual', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            Text(
              entry.purpose,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _SummaryPill(label: _typeLabel(entry.type)),
                const SizedBox(width: 8),
                _SummaryPill(label: '${entry.durationHours}h'),
                const SizedBox(width: 8),
                _SummaryPill(
                  label: DateFormat('dd MMM').format(entry.startedAt),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              entry.verse,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.secondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FastTile extends ConsumerWidget {
  const _FastTile({required this.entry});

  final FastEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _SummaryPill(
                  label: entry.isCompleted ? 'Concluído' : 'Em andamento',
                  active: !entry.isCompleted,
                ),
                const Spacer(),
                Text(
                  DateFormat('dd/MM/yyyy').format(entry.startedAt),
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(entry.purpose, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              '${_typeLabel(entry.type)} • ${entry.durationHours} horas • ${entry.verse}',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
            if (entry.testimony != null &&
                entry.testimony!.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(entry.testimony!),
            ],
            if (!entry.isCompleted) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton(
                  onPressed: () {
                    ref
                        .read(fastingActionsProvider)
                        .completeFast(
                          id: entry.id,
                          testimony: 'Jejum concluído com gratidão.',
                        );
                  },
                  child: const Text('Concluir'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({required this.label, this.active = false});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: active ? AppColors.primary : AppColors.surfaceTint,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: active ? Colors.white : AppColors.secondary,
        ),
      ),
    );
  }
}

String _typeLabel(FastType type) {
  switch (type) {
    case FastType.parcial:
      return 'Parcial';
    case FastType.total:
      return 'Total';
    case FastType.daniel:
      return 'Daniel';
  }
}
