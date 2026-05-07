import 'package:cysvet_app/core/widgets/search_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

final usersSearchQueryProvider = StateProvider.autoDispose<String>(
  (ref) => '',
);

class UsuariosPage extends ConsumerWidget {
  const UsuariosPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchQuery = ref.watch(usersSearchQueryProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SearchCard(
              value: searchQuery,
              labelText: 'Pesquisar usuários',
              onChanged: (value) {
                ref.read(usersSearchQueryProvider.notifier).state = value;
              },
            ),
            const SizedBox(height: 16),

            // Aqui entra a lista de usuarios quando tiver o provider/model.
            // A filtragem deve usar o valor de searchQuery.
          ],
        ),
      ),
    );
  }
}