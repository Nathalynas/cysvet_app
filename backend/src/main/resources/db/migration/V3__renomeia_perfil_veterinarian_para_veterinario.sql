UPDATE usuario
SET perfil = 'VETERINARIO',
    data_atualizacao = CURRENT_TIMESTAMP(6)
WHERE perfil = 'VETERINARIAN';
