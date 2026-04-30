package com.reprocampo.backend.repository;

import com.reprocampo.backend.entity.Visita;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface VisitaRepository extends JpaRepository<Visita, Long> {

    List<Visita> findAllByUsuarioIdOrderByDataVisitaDesc(Long idUsuario);

    List<Visita> findAllByUsuarioIdAndPropriedadeIdOrderByDataVisitaDesc(Long idUsuario, Long idPropriedade);

    Optional<Visita> findByIdAndUsuarioId(Long id, Long idUsuario);

    Optional<Visita> findByIdExternoAndUsuarioId(String idExterno, Long idUsuario);

    List<Visita> findAllByUsuarioIdAndDataAtualizacaoAfterOrderByDataAtualizacaoAsc(Long idUsuario, Instant dataAtualizacao);
}
