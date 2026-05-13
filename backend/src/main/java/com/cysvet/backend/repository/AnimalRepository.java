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

    @Query("""
            select a
            from Animal a
            join a.propriedade p
            where (:idPropriedade is null or p.id = :idPropriedade)
              and (:status is null or a.status = :status)
              and (
                  :search is null
                  or lower(a.idExterno) like lower(concat('%', :search, '%'))
                  or lower(a.codigo) like lower(concat('%', :search, '%'))
                  or lower(a.categoria) like lower(concat('%', :search, '%'))
                  or lower(coalesce(a.sexo, '')) like lower(concat('%', :search, '%'))
                  or lower(p.idExterno) like lower(concat('%', :search, '%'))
                  or lower(p.nome) like lower(concat('%', :search, '%'))
              )
            order by a.codigo asc
            """)
    List<Animal> search(
            @Param("idPropriedade") Long idPropriedade,
            @Param("search") String search,
            @Param("status") StatusAnimal status
    );

    List<Animal> findAllByDataAtualizacaoAfterOrderByDataAtualizacaoAsc(Instant dataAtualizacao);
}
