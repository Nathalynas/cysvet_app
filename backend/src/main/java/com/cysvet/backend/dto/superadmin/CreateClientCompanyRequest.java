package com.cysvet.backend.dto.superadmin;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

@Schema(description = "Payload para cadastrar uma empresa cliente e seu responsavel.")
public record CreateClientCompanyRequest(
        @Schema(description = "Nome da empresa cliente.", example = "Fazenda Boa Vista")
        @NotBlank(message = "companyName e obrigatorio")
        @Size(max = 255, message = "companyName deve ter no maximo 255 caracteres")
        String companyName,

        @Schema(description = "Nome do responsavel pela empresa.", example = "Maria Silva")
        @NotBlank(message = "responsibleName e obrigatorio")
        @Size(max = 255, message = "responsibleName deve ter no maximo 255 caracteres")
        String responsibleName,

        @Schema(description = "E-mail do responsavel, usado no login.", example = "maria@fazenda.com")
        @NotBlank(message = "responsibleEmail e obrigatorio")
        @Email(message = "responsibleEmail deve ser valido")
        @Size(max = 255, message = "responsibleEmail deve ter no maximo 255 caracteres")
        String responsibleEmail
) {

    // O e-mail e aparado antes da validacao para que espacos nas bordas nao causem erro de formato.
    public CreateClientCompanyRequest {
        companyName = companyName == null ? null : companyName.trim();
        responsibleName = responsibleName == null ? null : responsibleName.trim();
        responsibleEmail = responsibleEmail == null ? null : responsibleEmail.trim();
    }
}
