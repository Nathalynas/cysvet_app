package com.cysvet.backend.repository;

import com.cysvet.backend.entity.EventoReprodutivo;
import com.cysvet.backend.entity.TipoEventoReprodutivo;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface EventoReprodutivoRepository extends JpaRepository<EventoReprodutivo, Long> {

    List<EventoReprodutivo> findAllByOrderByDataEventoDesc();

    List<EventoReprodutivo> findAllByPropriedadeIdOrderByDataEventoDesc(Long idPropriedade);

    List<EventoReprodutivo> findAllByPropriedadeIdAndDataEventoBetweenOrderByDataEventoDesc(
            Long idPropriedade,
            LocalDate dataInicio,
            LocalDate dataFim
    );

    List<EventoReprodutivo> findAllByAnimalIdOrderByDataEventoDesc(Long idAnimal);

    List<EventoReprodutivo> findAllByAnimalId(Long idAnimal);

    List<EventoReprodutivo> findAllByVisitaId(Long idVisita);

    boolean existsByAnimalIdAndTipoAndDataEvento(Long idAnimal, TipoEventoReprodutivo tipo, LocalDate dataEvento);

    Optional<EventoReprodutivo> findByIdExterno(String idExterno);

    List<EventoReprodutivo> findAllByDataAtualizacaoAfterOrderByDataAtualizacaoAsc(Instant dataAtualizacao);
}
