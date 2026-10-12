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

  /// Devolve se o e-mail foi enviado e se a lista deixou de ser atualizada.
  Future<({bool emailSent, bool reloadFailed})> create({
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
    final reloaded = await _reload();
    return (emailSent: result.emailSent, reloadFailed: !reloaded);
  }

  /// Devolve false se a mudança foi feita mas a lista não pôde ser recarregada.
  Future<bool> setActive(int id, bool active) async {
    await ref.read(superAdminRepositoryProvider).setActive(id, active);
    return _reload();
  }

  Future<bool> resendAccess(int id) {
    return ref.read(superAdminRepositoryProvider).resendAccess(id);
  }

  // A mutação já foi feita no servidor; se só o recarregamento falhar,
  // mantém a lista anterior em vez de trocar a tela por erro.
  Future<bool> _reload() async {
    try {
      state = AsyncData(await _load());
      return true;
    } catch (_) {
      return false;
    }
  }
}
