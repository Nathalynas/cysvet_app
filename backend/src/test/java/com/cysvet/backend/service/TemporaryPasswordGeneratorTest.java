package com.cysvet.backend.service;

import static org.assertj.core.api.Assertions.assertThat;

import java.util.HashSet;
import java.util.Set;
import org.junit.jupiter.api.Test;

class TemporaryPasswordGeneratorTest {

    @Test
    void generatesTwelveCharsFromUnambiguousAlphabet() {
        TemporaryPasswordGenerator generator = new TemporaryPasswordGenerator();
        Set<String> distinct = new HashSet<>();

        for (int i = 0; i < 200; i++) {
            String password = generator.generate();
            assertThat(password).hasSize(12).matches("[A-HJ-NP-Za-km-z2-9]{12}");
            distinct.add(password);
        }

        assertThat(distinct.size()).isGreaterThanOrEqualTo(190);
    }
}
