package com.cysvet.backend.repository;

import com.cysvet.backend.entity.StatusPropriedade;
import com.cysvet.backend.entity.Propriedade;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface PropriedadeRepository extends JpaRepository<Propriedade, Long> {

    List<Propriedade> findAllByOrderByNomeAsc();

    @Query("""
            select p
            from Propriedade p
            where (:status is null or p.status = :status)
              and (
                  :search is null
                  or lower(p.idExterno) like lower(concat('%', :search, '%'))
                  or lower(p.nome) like lower(concat('%', :search, '%'))
                  or lower(p.nomeProprietario) like lower(concat('%', :search, '%'))
                  or lower(coalesce(p.contato, '')) like lower(concat('%', :search, '%'))
                  or lower(coalesce(p.cidade, '')) like lower(concat('%', :search, '%'))
                  or lower(coalesce(p.estado, '')) like lower(concat('%', :search, '%'))
              )
            order by p.nome asc
            """)
    List<Propriedade> search(
            @Param("search") String search,
            @Param("status") StatusPropriedade status
    );

    Optional<Propriedade> findByIdExterno(String idExterno);

    List<Propriedade> findAllByDataAtualizacaoAfterOrderByDataAtualizacaoAsc(Instant dataAtualizacao);
}
