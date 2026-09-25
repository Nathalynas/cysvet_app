enum SyncStatusEnum {
  /// Salvo apenas no aparelho (ex.: rascunho), ainda sem mutação na fila.
  localOnly,
  synced,
  pending,
  syncing,
  error;

  String get label {
    switch (this) {
      case SyncStatusEnum.localOnly:
        return 'Salvo localmente';
      case SyncStatusEnum.synced:
        return 'Sincronizado';
      case SyncStatusEnum.pending:
        return 'Pendente';
      case SyncStatusEnum.syncing:
        return 'Sincronizando';
      case SyncStatusEnum.error:
        return 'Erro ao sincronizar';
    }
  }

  static SyncStatusEnum fromName(String? value) {
    for (final status in SyncStatusEnum.values) {
      if (status.name == value) return status;
    }
    return SyncStatusEnum.pending;
  }
}
