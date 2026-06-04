package com.cysvet.backend.repository;

import com.cysvet.backend.entity.Lote;
import com.cysvet.backend.entity.StatusLote;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface LoteRepository extends JpaRepository<Lote, Long> {

    Optional<Lote> findByIdExterno(String idExterno);

    boolean existsByPropriedadeId(Long idPropriedade);

    @Query("""
            select l
            from Lote l
            join l.propriedade p
            where (:idPropriedade is null or p.id = :idPropriedade)
              and (:status is null or l.status = :status)
              and (
                  :search is null
                  or lower(l.idExterno) like lower(concat('%', :search, '%'))
                  or lower(l.nome) like lower(concat('%', :search, '%'))
                  or lower(coalesce(l.descricao, '')) like lower(concat('%', :search, '%'))
                  or lower(p.idExterno) like lower(concat('%', :search, '%'))
                  or lower(p.nome) like lower(concat('%', :search, '%'))
              )
            order by l.nome asc
            """)
    List<Lote> search(
            @Param("idPropriedade") Long idPropriedade,
            @Param("search") String search,
            @Param("status") StatusLote status
    );

    List<Lote> findAllByDataAtualizacaoAfterOrderByDataAtualizacaoAsc(Instant dataAtualizacao);
}
