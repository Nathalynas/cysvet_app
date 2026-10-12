import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cysvet_app/api/super_admin_api.dart';
import 'package:cysvet_app/models/client_company_model.dart';

final superAdminCompaniesProvider =
    AsyncNotifierProvider<
      SuperAdminCompaniesNotifier,
      List<ClientCompanyModel>
    >(SuperAdminCompaniesNotifier.new);

class SuperAdminCompaniesNotifier
    extends AsyncNotifier<List<ClientCompanyModel>> {
  @override
  Future<List<ClientCompanyModel>> build() => _load();

  Future<List<ClientCompanyModel>> _load() async {
    final items = await ref.read(superAdminRepositoryProvider).list();
    return [...items]
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }

  /// Devolve se o e-mail com a senha provisória foi enviado.
  Future<bool> create({
    required String companyName,
    required String responsibleName,
    required String responsibleEmail,
  }) async {
    final result = await ref
        .read(superAdminRepositoryProvider)
        .create(
          companyName: companyName,
          responsibleName: responsibleName,
          responsibleEmail: responsibleEmail,
        );
    await _reload();
    return result.emailSent;
  }

  Future<void> setActive(int id, bool active) async {
    await ref.read(superAdminRepositoryProvider).setActive(id, active);
    await _reload();
  }

  Future<bool> resendAccess(int id) {
    return ref.read(superAdminRepositoryProvider).resendAccess(id);
  }

  // Recarrega sem voltar a tabela para o estado de carregamento.
  Future<void> _reload() async {
    state = await AsyncValue.guard(_load);
  }
}
