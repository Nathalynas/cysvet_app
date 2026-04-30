package com.reprocampo.backend.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import java.time.LocalDate;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
@Entity
@Table(name = "visita")
public class Visita extends BaseEntity {

    @Column(name = "id_externo", nullable = false, unique = true, length = 64)
    private String idExterno;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "id_propriedade", nullable = false)
    private Propriedade propriedade;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "id_usuario", nullable = false)
    private Usuario usuario;

    @Column(name = "data_visita", nullable = false)
    private LocalDate dataVisita;

    @Column(name = "observacoes", length = 2000)
    private String observacoes;
}
