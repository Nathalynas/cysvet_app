package com.cysvet.backend.entity;

import com.fasterxml.jackson.annotation.JsonCreator;
import java.text.Normalizer;
import java.util.Locale;

public enum StatusLote {
    ATIVO,
    INATIVO;

    @JsonCreator
    public static StatusLote fromValue(String value) {
        if (value == null) {
            return null;
        }

        String normalized = Normalizer.normalize(value, Normalizer.Form.NFD)
                .replaceAll("\\p{M}", "")
                .trim()
                .toUpperCase(Locale.ROOT);

        return switch (normalized) {
            case "ATIVO" -> ATIVO;
            case "INATIVO", "ARQUIVADO" -> INATIVO;
            default -> throw new IllegalArgumentException("Status de lote invalido: " + value);
        };
    }
}
