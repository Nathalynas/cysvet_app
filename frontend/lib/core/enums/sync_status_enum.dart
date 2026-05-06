enum SyncStatusEnum {
  synced,
  pending,
  syncing,
  error;

  String get label {
    switch (this) {
      case SyncStatusEnum.synced:
        return 'Sincronizado';
      case SyncStatusEnum.pending:
        return 'Pendente';
      case SyncStatusEnum.syncing:
        return 'Sincronizando';
      case SyncStatusEnum.error:
        return 'Erro';
    }
  }
}
