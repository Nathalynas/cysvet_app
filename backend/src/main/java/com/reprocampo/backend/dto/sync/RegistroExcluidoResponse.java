package com.reprocampo.backend.dto.sync;

import java.time.Instant;

public record RegistroExcluidoResponse(
        String nomeEntidade,
        String idExterno,
        Instant dataExclusao
) {
}
