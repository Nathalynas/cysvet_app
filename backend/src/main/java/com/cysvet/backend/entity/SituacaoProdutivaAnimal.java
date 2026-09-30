package com.cysvet.backend.entity;

import com.cysvet.backend.util.Textos;
import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonValue;
import java.util.Arrays;
import java.util.Locale;

/**
 * Situacao produtiva do animal (coluna "Sit. Produtiva" das planilhas de campo).
 * E independente da situacao reprodutiva: uma vaca seca normalmente continua prenha.
 */
public enum SituacaoProdutivaAnimal {
    LACTANTE("lactante", "lactacao", "em lactacao"),
    SECA("seca", "dry"),
    NOVILHA("novilha", "bezerra"),
    PRE_PARTO("pre parto", "pre-parto", "preparto");

    private final String value;
    private final String[] aliases;

    SituacaoProdutivaAnimal(String value, String... aliases) {
        this.value = value;
        this.aliases = aliases;
    }

    @JsonValue
    public String getValue() {
        return value;
    }

    @JsonCreator
    public static SituacaoProdutivaAnimal fromValue(String value) {
        if (value == null || value.isBlank()) {
            return null;
        }

        return Arrays.stream(values())
                .filter(item -> item.matches(value.trim()))
                .findFirst()
                .orElseThrow(() -> new IllegalArgumentException("Situacao produtiva invalida: " + value));
    }

    /** Como {@link #fromValue}, mas devolve null para texto fora da lista. */
    public static SituacaoProdutivaAnimal fromValueOrNull(String value) {
        try {
            return fromValue(value);
        } catch (IllegalArgumentException exception) {
            return null;
        }
    }

    private boolean matches(String candidate) {
        String normalizedCandidate = normalize(candidate);
        if (normalize(value).equals(normalizedCandidate)) {
            return true;
        }

        return Arrays.stream(aliases)
                .map(SituacaoProdutivaAnimal::normalize)
                .anyMatch(alias -> alias.equals(normalizedCandidate));
    }

    private static String normalize(String value) {
        return Textos.semAcentos(value).toLowerCase(Locale.ROOT).trim();
    }
}
