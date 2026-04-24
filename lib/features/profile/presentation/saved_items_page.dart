import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/pv_scaffold.dart';
import '../../auth/application/auth_controller.dart';
import '../application/profile_controller.dart';

class SavedItemsPage extends ConsumerWidget {
  const SavedItemsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(savedItemsProvider);
    final user = ref.watch(currentUserProvider);

    return PvScaffold(
      title: 'Itens salvos',
      showBackButton: true,
      body: itemsAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'Você ainda não salvou nenhuma palavra. Quando tocar em salvar na dashboard ou no estudo, seus itens aparecem aqui.',
                  ),
                ),
              ),
            );
          }

          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = items[index];
              return Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceTint,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.bookmark_rounded,
                      color: AppColors.secondary,
                    ),
                  ),
                  title: Text(item.title),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (item.reference.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          item.reference,
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(color: AppColors.secondary),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(item.excerpt),
                      const SizedBox(height: 8),
                      Text(
                        'Salvo em ${DateFormat('dd/MM/yyyy').format(item.createdAt)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline_rounded),
                    onPressed: user == null
                        ? null
                        : () async {
                            await ref
                                .read(savedItemsRepositoryProvider)
                                .removeItem(
                                  userId: user.id,
                                  itemId: item.id,
                                );
                          },
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text('Não foi possível carregar seus itens salvos: $error'),
            ),
          ),
        ),
      ),
    );
  }
}
