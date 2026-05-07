package com.cysvet.backend.repository;

import com.cysvet.backend.entity.Propriedade;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface PropriedadeRepository extends JpaRepository<Propriedade, Long> {

    List<Propriedade> findAllByOrderByNomeAsc();

    Optional<Propriedade> findByIdExterno(String idExterno);

    List<Propriedade> findAllByDataAtualizacaoAfterOrderByDataAtualizacaoAsc(Instant dataAtualizacao);
}
