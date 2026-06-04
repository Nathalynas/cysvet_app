package com.cysvet.backend.dto.sync;

import java.util.Locale;

public final class SyncEntityNames {

    public static final String PROPERTY = "property";
    public static final String LOT = "lot";
    public static final String ANIMAL = "animal";
    public static final String VISIT = "visit";
    public static final String EVENT = "event";

    private SyncEntityNames() {
    }

    public static String normalize(String value) {
        if (value == null || value.isBlank()) {
            throw new IllegalArgumentException("Entidade de sincronizacao nao informada");
        }

        String normalized = value.trim().toLowerCase(Locale.ROOT);
        return switch (normalized) {
            case PROPERTY, LOT, ANIMAL, VISIT, EVENT -> normalized;
            default -> throw new IllegalArgumentException("Entidade de sincronizacao nao suportada: " + value);
        };
    }
}
