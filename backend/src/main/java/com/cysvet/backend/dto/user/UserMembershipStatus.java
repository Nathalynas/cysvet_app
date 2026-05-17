package com.cysvet.backend.dto.user;

import io.swagger.v3.oas.annotations.media.Schema;

@Schema(description = "Status do vinculo do usuario com a empresa ativa.")
public enum UserMembershipStatus {
    ATIVO,
    INATIVO;

    public boolean isActive() {
        return this == ATIVO;
    }

    public static UserMembershipStatus from(boolean active) {
        return active ? ATIVO : INATIVO;
    }
}
