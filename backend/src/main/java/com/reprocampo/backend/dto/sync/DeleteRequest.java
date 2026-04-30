package com.reprocampo.backend.dto.sync;

import jakarta.validation.constraints.NotBlank;

public record DeleteRequest(@NotBlank String idExterno) {
}
