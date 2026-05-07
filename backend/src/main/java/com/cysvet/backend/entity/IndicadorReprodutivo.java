package com.cysvet.backend.entity;

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
@Table(name = "indicador_reprodutivo")
public class IndicadorReprodutivo extends TenantAwareEntity {

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "id_usuario", nullable = false)
    private Usuario usuario;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "id_propriedade")
    private Propriedade propriedade;

    @Column(name = "data_referencia", nullable = false)
    private LocalDate dataReferencia;

    @Column(name = "data_inicio")
    private LocalDate dataInicio;

    @Column(name = "data_fim")
    private LocalDate dataFim;

    @Column(name = "total_propriedades", nullable = false)
    private long totalPropriedades;

    @Column(name = "total_animais", nullable = false)
    private long totalAnimais;

    @Column(name = "total_eventos", nullable = false)
    private long totalEventos;

    @Column(name = "taxa_prenhez", nullable = false)
    private double taxaPrenhez;

    @Column(name = "taxa_servico", nullable = false)
    private double taxaServico;

    @Column(name = "media_inseminacoes", nullable = false)
    private double mediaInseminacoes;

    @Column(name = "intervalo_medio_partos", nullable = false)
    private double intervaloMedioPartos;
}
