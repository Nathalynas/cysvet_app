package com.cysvet.backend.repository;

import com.cysvet.backend.entity.RegistroExcluido;
import java.time.Instant;
import java.util.Collection;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface RegistroExcluidoRepository extends JpaRepository<RegistroExcluido, Long> {

    List<RegistroExcluido> findAllByDataAtualizacaoAfterOrderByDataAtualizacaoAsc(Instant dataAtualizacao);

    Optional<RegistroExcluido> findByNomeEntidadeAndIdExterno(String nomeEntidade, String idExterno);

    List<RegistroExcluido> findAllByNomeEntidadeAndIdExternoIn(String nomeEntidade, Collection<String> idsExternos);

    void deleteAllByNomeEntidadeAndIdExternoIn(String nomeEntidade, Collection<String> idsExternos);
}
