package com.cysvet.backend.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
@Entity
@Table(name = "empresa")
public class Empresa extends BaseEntity {

    @Column(name = "empresa_id", nullable = false, unique = true, updatable = false, length = 36)
    private String empresaId;

    @Column(name = "nome", nullable = false)
    private String nome;

    @Column(name = "email", length = 255)
    private String email;

    @Column(name = "ativo", nullable = false)
    private boolean ativo = true;
}
