package com.cysvet.backend.entity;

public enum TipoEventoReprodutivo {
    INSEMINATION,
    PREGNANCY_DIAGNOSIS,
    CALVING,
    DRY_OFF,
    GESTATIONAL_LOSS,
    POST_PARTUM_COMPLICATION,
    HEALTH_TREATMENT,
    MILK_CONTROL,
    LOT_MOVEMENT,
    DISCARD,
    DEATH,
    // Situacao reprodutiva observada pelo veterinario (ex.: na visita), com o
    // valor em detalhes.status. Cobre situacoes sem evento proprio, como PEV,
    // liberada ou aguardando DG.
    REPRODUCTIVE_STATUS_CHECK
}
