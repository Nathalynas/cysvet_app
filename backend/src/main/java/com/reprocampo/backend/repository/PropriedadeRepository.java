package com.reprocampo.backend.repository;

import com.reprocampo.backend.entity.Propriedade;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface PropriedadeRepository extends JpaRepository<Propriedade, Long> {

    List<Propriedade> findAllByUsuarioIdOrderByNomeAsc(Long idUsuario);

    Optional<Propriedade> findByIdAndUsuarioId(Long id, Long idUsuario);

    Optional<Propriedade> findByIdExternoAndUsuarioId(String idExterno, Long idUsuario);

    List<Propriedade> findAllByUsuarioIdAndDataAtualizacaoAfterOrderByDataAtualizacaoAsc(Long idUsuario, Instant dataAtualizacao);
}
