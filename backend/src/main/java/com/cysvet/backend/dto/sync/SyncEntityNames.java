package com.cysvet.backend.dto.sync;

import java.util.Locale;
import java.util.List;

public final class SyncEntityNames {

    public static final String PROPERTY = "property";
    public static final String LOT = "lot";
    public static final String ANIMAL = "animal";
    public static final String VISIT = "visit";
    public static final String EVENT = "event";
    public static final String PROPERTIES_COLLECTION = "properties";
    public static final String LOTS_COLLECTION = "lots";
    public static final String ANIMALS_COLLECTION = "animals";
    public static final String VISITS_COLLECTION = "visits";
    public static final String EVENTS_COLLECTION = "events";
    public static final String DELETED_RECORDS_COLLECTION = "deletedRecords";

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

    public static List<String> createUpdateOrder() {
        return List.of(PROPERTY, LOT, ANIMAL, VISIT, EVENT);
    }

    public static List<String> deleteOrder() {
        return List.of(EVENT, VISIT, ANIMAL, LOT, PROPERTY);
    }

    public static List<String> snapshotCollections() {
        return List.of(
                PROPERTIES_COLLECTION,
                LOTS_COLLECTION,
                ANIMALS_COLLECTION,
                VISITS_COLLECTION,
                EVENTS_COLLECTION,
                DELETED_RECORDS_COLLECTION
        );
    }
}
