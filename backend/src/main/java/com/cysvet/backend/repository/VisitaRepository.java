package com.cysvet.backend.repository;

import com.cysvet.backend.entity.Visita;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;

public interface VisitaRepository extends JpaRepository<Visita, Long> {

    @EntityGraph(attributePaths = {"propriedade", "usuario"})
    List<Visita> findAllByOrderByDataVisitaDesc();

    @EntityGraph(attributePaths = {"propriedade", "usuario"})
    List<Visita> findAllByPropriedadeIdOrderByDataVisitaDesc(Long idPropriedade);

    Optional<Visita> findByIdExterno(String idExterno);

    @EntityGraph(attributePaths = {"propriedade", "usuario"})
    List<Visita> findAllByDataAtualizacaoAfterOrderByDataAtualizacaoAsc(Instant dataAtualizacao);
}
