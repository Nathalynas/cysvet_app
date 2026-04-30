package com.reprocampo.backend.repository;

import com.reprocampo.backend.entity.Animal;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface AnimalRepository extends JpaRepository<Animal, Long> {

    List<Animal> findAllByUsuarioIdOrderByCodigoAsc(Long idUsuario);

    List<Animal> findAllByUsuarioIdAndPropriedadeIdOrderByCodigoAsc(Long idUsuario, Long idPropriedade);

    Optional<Animal> findByIdAndUsuarioId(Long id, Long idUsuario);

    Optional<Animal> findByIdExternoAndUsuarioId(String idExterno, Long idUsuario);

    long countByUsuarioId(Long idUsuario);

    void deleteAllByUsuarioIdAndPropriedadeId(Long idUsuario, Long idPropriedade);

    List<Animal> findAllByUsuarioIdAndDataAtualizacaoAfterOrderByDataAtualizacaoAsc(Long idUsuario, Instant dataAtualizacao);
}
