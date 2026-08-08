package com.cysvet.backend.entity;

import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonValue;
import java.text.Normalizer;
import java.util.Arrays;
import java.util.Locale;

public enum StatusReprodutivoAnimal {
    PROTOCOL("em protocolo"),
    EMPTY("vazia", "empty"),
    RELEASED("liberada"),
    DELAYED("atrasada"),
    WAITING_DIAGNOSIS("aguardando dg"),
    INSEMINATED_ST("inseminada st"),
    PREGNANT("prenha", "pregnant"),
    INDUCTION("inducao", "indução"),
    DISCARD("descarte"),
    PEV("pev"),
    NO_AGE("sem idade"),
    CALF("bezerra"),
    INSEMINATED("inseminada", "inseminated"),
    DRY("dry", "seca"),
    PENDING("pending");

    private final String value;
    private final String[] aliases;

    StatusReprodutivoAnimal(String value, String... aliases) {
        this.value = value;
        this.aliases = aliases;
    }

    @JsonValue
    public String getValue() {
        return value;
    }

    @JsonCreator
    public static StatusReprodutivoAnimal fromValue(String value) {
        if (value == null || value.isBlank()) {
            return null;
        }

        return Arrays.stream(values())
                .filter(item -> item.matches(value.trim()))
                .findFirst()
                .orElseThrow(() -> new IllegalArgumentException("Status reprodutivo invalido: " + value));
    }

    private boolean matches(String candidate) {
        String normalizedCandidate = normalize(candidate);
        if (normalize(value).equals(normalizedCandidate)) {
            return true;
        }

        return Arrays.stream(aliases)
                .map(StatusReprodutivoAnimal::normalize)
                .anyMatch(alias -> alias.equals(normalizedCandidate));
    }

    private static String normalize(String value) {
        return Normalizer.normalize(value, Normalizer.Form.NFD)
                .replaceAll("\\p{M}+", "")
                .toLowerCase(Locale.ROOT)
                .trim();
    }
}
