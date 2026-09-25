package com.cysvet.backend.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import java.time.Instant;
import java.time.LocalDate;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
@Entity
@Table(name = "animal")
public class Animal extends TenantAwareEntity {

    @Column(name = "id_externo", nullable = false, length = 64)
    private String idExterno;

    @Column(name = "codigo", nullable = false)
    private String codigo;

    @Column(name = "data_nascimento")
    private LocalDate dataNascimento;

    @Column(name = "numero_lactacao", nullable = false)
    private Integer numeroLactacao = 0;

    @Column(name = "data_ultimo_parto")
    private LocalDate dataUltimoParto;

    @Column(name = "data_inseminacao")
    private LocalDate dataInseminacao;

    @Column(name = "touro_ia")
    private String touroIa;

    @Column(name = "historico_reprodutivo", length = 2000)
    private String historicoReprodutivo;

    @Enumerated(EnumType.STRING)
    @Column(name = "status_reprodutivo", length = 32)
    private StatusReprodutivoAnimal statusReprodutivo;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 32)
    private StatusAnimal status = StatusAnimal.ATIVO;

    // Base do resumo reprodutivo (cadastro, importacao ou correcao manual).
    // Os campos de resumo acima sao recalculados a partir dela e dos eventos.
    @Column(name = "base_numero_lactacao", nullable = false)
    private Integer baseNumeroLactacao = 0;

    @Column(name = "base_data_ultimo_parto")
    private LocalDate baseDataUltimoParto;

    @Column(name = "base_data_inseminacao")
    private LocalDate baseDataInseminacao;

    @Column(name = "base_touro_ia")
    private String baseTouroIa;

    @Enumerated(EnumType.STRING)
    @Column(name = "base_status_reprodutivo", length = 32)
    private StatusReprodutivoAnimal baseStatusReprodutivo;

    @Column(name = "base_status_reprodutivo_em")
    private Instant baseStatusReprodutivoEm;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "id_propriedade", nullable = false)
    private Propriedade propriedade;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "id_lote")
    private Lote lote;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "id_usuario", nullable = false)
    private Usuario usuario;
}
