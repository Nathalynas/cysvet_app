package com.cysvet.backend.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
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
@Table(name = "evento_reprodutivo")
public class EventoReprodutivo extends BaseEntity {

    @Column(name = "id_externo", nullable = false, unique = true, length = 64)
    private String idExterno;

    @Enumerated(EnumType.STRING)
    @Column(name = "tipo", nullable = false)
    private TipoEventoReprodutivo tipo;

    @Column(name = "data_evento", nullable = false)
    private LocalDate dataEvento;

    @Column(name = "data_prevista_parto")
    private LocalDate dataPrevistaParto;

    @Column(name = "prenhez_confirmada")
    private Boolean prenhezConfirmada;

    @Column(name = "observacoes", length = 2000)
    private String observacoes;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "id_animal", nullable = false)
    private Animal animal;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "id_propriedade", nullable = false)
    private Propriedade propriedade;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "id_usuario", nullable = false)
    private Usuario usuario;
}
