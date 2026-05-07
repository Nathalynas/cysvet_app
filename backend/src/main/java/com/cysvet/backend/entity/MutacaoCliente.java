package com.cysvet.backend.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
@Entity
@Table(name = "mutacao_cliente")
public class MutacaoCliente extends TenantAwareEntity {

    @Column(name = "chave_mutacao", nullable = false, length = 128)
    private String chaveMutacao;

    @Column(name = "nome_entidade", nullable = false)
    private String nomeEntidade;

    @Column(name = "id_usuario", nullable = false)
    private Long idUsuario;

    @Column(name = "id_entidade", nullable = false)
    private Long idEntidade;
}
