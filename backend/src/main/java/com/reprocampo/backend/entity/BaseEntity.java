package com.reprocampo.backend.entity;

import jakarta.persistence.Column;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.MappedSuperclass;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Version;
import java.time.Instant;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
@MappedSuperclass
public abstract class BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "data_criacao", nullable = false, updatable = false)
    private Instant dataCriacao;

    @Column(name = "data_atualizacao", nullable = false)
    private Instant dataAtualizacao;

    @Version
    @Column(name = "versao", nullable = false)
    private Long versao = 0L;

    @PrePersist
    public void prePersist() {
        Instant now = Instant.now();
        dataCriacao = now;
        dataAtualizacao = now;
    }

    @PreUpdate
    public void preUpdate() {
        dataAtualizacao = Instant.now();
    }
}
