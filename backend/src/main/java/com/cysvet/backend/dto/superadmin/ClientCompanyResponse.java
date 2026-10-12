package com.cysvet.backend.dto.superadmin;

import io.swagger.v3.oas.annotations.media.Schema;
import java.time.Instant;

@Schema(description = "Empresa cliente com dados do responsavel e situacao de acesso.")
public record ClientCompanyResponse(
        Long id,
        String name,
        String responsibleName,
        String responsibleEmail,
        ClientCompanyStatus status,
        Instant createdAt
) {
}
