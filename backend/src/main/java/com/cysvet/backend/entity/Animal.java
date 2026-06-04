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
@Table(name = "animal")
public class Animal extends TenantAwareEntity {

    @Column(name = "id_externo", nullable = false, length = 64)
    private String idExterno;

    @Column(name = "codigo", nullable = false)
    private String codigo;

    @Column(name = "categoria", nullable = false)
    private String categoria;

    @Column(name = "sexo")
    private String sexo;

    @Column(name = "data_nascimento")
    private LocalDate dataNascimento;

    @Column(name = "numero_lactacao", nullable = false)
    private Integer numeroLactacao = 0;

    @Column(name = "data_ultimo_parto")
    private LocalDate dataUltimoParto;

    @Column(name = "historico_reprodutivo", length = 2000)
    private String historicoReprodutivo;

    @Enumerated(EnumType.STRING)
    @Column(name = "status_reprodutivo", length = 32)
    private StatusReprodutivoAnimal statusReprodutivo;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 32)
    private StatusAnimal status = StatusAnimal.ATIVO;

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
