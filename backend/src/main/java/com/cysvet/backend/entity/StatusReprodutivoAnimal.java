package com.cysvet.backend.entity;

import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonValue;
import java.util.Arrays;

public enum StatusReprodutivoAnimal {
    PREGNANT("pregnant"),
    EMPTY("empty"),
    INSEMINATED("inseminated"),
    DRY("dry"),
    PENDING("pending");

    private final String value;

    StatusReprodutivoAnimal(String value) {
        this.value = value;
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
                .filter(item -> item.value.equalsIgnoreCase(value.trim()))
                .findFirst()
                .orElseThrow(() -> new IllegalArgumentException("Status reprodutivo invalido: " + value));
    }
}
