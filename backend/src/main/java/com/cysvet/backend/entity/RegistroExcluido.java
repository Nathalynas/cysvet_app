package com.cysvet.backend.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;
import java.time.Instant;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
@Entity
@Table(name = "registro_excluido")
public class RegistroExcluido extends TenantAwareEntity {

    @Column(name = "nome_entidade", nullable = false, length = 64)
    private String nomeEntidade;

    @Column(name = "id_externo", nullable = false, length = 64)
    private String idExterno;

    @Column(name = "id_usuario", nullable = false)
    private Long idUsuario;

    @Column(name = "data_exclusao", nullable = false)
    private Instant dataExclusao;
}
