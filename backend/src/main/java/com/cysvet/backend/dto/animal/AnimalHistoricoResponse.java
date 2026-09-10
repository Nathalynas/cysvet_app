package com.cysvet.backend.dto.animal;

import com.cysvet.backend.entity.TipoHistoricoAnimal;
import java.time.Instant;

public record AnimalHistoricoResponse(
        TipoHistoricoAnimal tipo,
        String descricao,
        String nomeUsuario,
        Instant data
) {
}
