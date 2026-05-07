package com.cysvet.backend.repository;

import com.cysvet.backend.entity.Animal;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface AnimalRepository extends JpaRepository<Animal, Long> {

    List<Animal> findAllByOrderByCodigoAsc();

    List<Animal> findAllByPropriedadeIdOrderByCodigoAsc(Long idPropriedade);

    Optional<Animal> findByIdExterno(String idExterno);

    List<Animal> findAllByDataAtualizacaoAfterOrderByDataAtualizacaoAsc(Instant dataAtualizacao);
}
