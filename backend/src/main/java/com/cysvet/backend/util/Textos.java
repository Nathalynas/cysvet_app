package com.cysvet.backend.util;

import java.text.Normalizer;

public final class Textos {

    private Textos() {
    }

    /** Remove acentos ("Óbito" -> "Obito"); caixa e espaços ficam com quem chama. */
    public static String semAcentos(String value) {
        return Normalizer.normalize(value, Normalizer.Form.NFD).replaceAll("\\p{M}+", "");
    }
}
