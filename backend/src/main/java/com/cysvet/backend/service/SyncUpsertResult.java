package com.cysvet.backend.service;

public record SyncUpsertResult<T>(
        T entity,
        boolean applied
) {
    public static <T> SyncUpsertResult<T> applied(T entity) {
        return new SyncUpsertResult<>(entity, true);
    }

    public static <T> SyncUpsertResult<T> conflicted(T entity) {
        return new SyncUpsertResult<>(entity, false);
    }
}
