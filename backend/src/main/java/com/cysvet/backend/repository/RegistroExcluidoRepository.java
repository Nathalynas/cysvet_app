package com.cysvet.backend.repository;

import com.cysvet.backend.entity.RegistroExcluido;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface RegistroExcluidoRepository extends JpaRepository<RegistroExcluido, Long> {

    List<RegistroExcluido> findAllByDataAtualizacaoAfterOrderByDataAtualizacaoAsc(Instant dataAtualizacao);

    Optional<RegistroExcluido> findByIdUsuarioAndNomeEntidadeAndIdExterno(Long idUsuario, String nomeEntidade, String idExterno);
}
