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
@Table(name = "animal")
public class Animal extends BaseEntity {

    @Column(name = "id_externo", nullable = false, unique = true, length = 64)
    private String idExterno;

    @Column(name = "codigo", nullable = false)
    private String codigo;

    @Column(name = "categoria", nullable = false)
    private String categoria;

    @Column(name = "data_nascimento")
    private LocalDate dataNascimento;

    @Column(name = "numero_lactacao", nullable = false)
    private Integer numeroLactacao = 0;

    @Column(name = "data_ultimo_parto")
    private LocalDate dataUltimoParto;

    @Column(name = "historico_reprodutivo", length = 2000)
    private String historicoReprodutivo;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "id_propriedade", nullable = false)
    private Propriedade propriedade;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "id_usuario", nullable = false)
    private Usuario usuario;
}
