package com.cysvet.backend.dto.sync;

import com.fasterxml.jackson.annotation.JsonAlias;
import jakarta.validation.constraints.NotBlank;

public record DeleteRequest(@JsonAlias("id_externo") @NotBlank String idExterno) {
}
