package com.cysvet.backend.repository;

import com.cysvet.backend.entity.EventoReprodutivo;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface EventoReprodutivoRepository extends JpaRepository<EventoReprodutivo, Long> {

    List<EventoReprodutivo> findAllByUsuarioIdOrderByDataEventoDesc(Long idUsuario);

    List<EventoReprodutivo> findAllByUsuarioIdAndPropriedadeIdOrderByDataEventoDesc(Long idUsuario, Long idPropriedade);

    List<EventoReprodutivo> findAllByUsuarioIdAndPropriedadeIdAndDataEventoBetweenOrderByDataEventoDesc(
            Long idUsuario,
            Long idPropriedade,
            LocalDate dataInicio,
            LocalDate dataFim
    );

    List<EventoReprodutivo> findAllByUsuarioIdAndAnimalIdOrderByDataEventoDesc(Long idUsuario, Long idAnimal);

    Optional<EventoReprodutivo> findByIdAndUsuarioId(Long id, Long idUsuario);

    Optional<EventoReprodutivo> findByIdExternoAndUsuarioId(String idExterno, Long idUsuario);

    void deleteAllByUsuarioIdAndPropriedadeId(Long idUsuario, Long idPropriedade);

    void deleteAllByUsuarioIdAndAnimalId(Long idUsuario, Long idAnimal);

    List<EventoReprodutivo> findAllByUsuarioIdAndDataAtualizacaoAfterOrderByDataAtualizacaoAsc(Long idUsuario, Instant dataAtualizacao);
}
