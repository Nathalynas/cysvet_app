package com.cysvet.backend.repository;

import com.cysvet.backend.entity.Animal;
import com.cysvet.backend.entity.StatusAnimal;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface AnimalRepository extends JpaRepository<Animal, Long> {

    List<Animal> findAllByOrderByCodigoAsc();

    List<Animal> findAllByPropriedadeIdOrderByCodigoAsc(Long idPropriedade);

    Optional<Animal> findByIdExterno(String idExterno);

    Optional<Animal> findByPropriedadeIdAndCodigoIgnoreCase(Long idPropriedade, String codigo);

    @Query("""
            select a
            from Animal a
            join a.propriedade p
            left join a.lote l
            where (:idPropriedade is null or p.id = :idPropriedade)
              and (:idLote is null or l.id = :idLote)
              and (:status is null or a.status = :status)
              and (
                  :search is null
                  or lower(a.idExterno) like lower(concat('%', :search, '%'))
                  or lower(a.codigo) like lower(concat('%', :search, '%'))
                  or lower(coalesce(a.touroIa, '')) like lower(concat('%', :search, '%'))
                  or lower(coalesce(l.idExterno, '')) like lower(concat('%', :search, '%'))
                  or lower(coalesce(l.nome, '')) like lower(concat('%', :search, '%'))
                  or lower(p.idExterno) like lower(concat('%', :search, '%'))
                  or lower(p.nome) like lower(concat('%', :search, '%'))
              )
            order by a.codigo asc
            """)
    List<Animal> search(
            @Param("idPropriedade") Long idPropriedade,
            @Param("idLote") Long idLote,
            @Param("search") String search,
            @Param("status") StatusAnimal status
    );

    List<Animal> findAllByDataAtualizacaoAfterOrderByDataAtualizacaoAsc(Instant dataAtualizacao);
}
