package com.cysvet.backend.repository;

import com.cysvet.backend.entity.Visita;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface VisitaRepository extends JpaRepository<Visita, Long> {

    List<Visita> findAllByOrderByDataVisitaDesc();

    List<Visita> findAllByPropriedadeIdOrderByDataVisitaDesc(Long idPropriedade);

    Optional<Visita> findByIdExterno(String idExterno);

    List<Visita> findAllByDataAtualizacaoAfterOrderByDataAtualizacaoAsc(Instant dataAtualizacao);
}
