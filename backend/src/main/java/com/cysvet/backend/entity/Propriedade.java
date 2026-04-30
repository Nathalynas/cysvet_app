package com.cysvet.backend.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
@Entity
@Table(name = "propriedade")
public class Propriedade extends BaseEntity {

    @Column(name = "id_externo", nullable = false, unique = true, length = 64)
    private String idExterno;

    @Column(name = "nome", nullable = false)
    private String nome;

    @Column(name = "nome_proprietario", nullable = false)
    private String nomeProprietario;

    @Column(name = "cidade")
    private String cidade;

    @Column(name = "estado")
    private String estado;

    @Column(name = "observacoes", length = 2000)
    private String observacoes;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "id_usuario", nullable = false)
    private Usuario usuario;
}
