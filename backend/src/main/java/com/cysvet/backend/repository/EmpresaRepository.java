package com.cysvet.backend.repository;

import com.cysvet.backend.entity.Empresa;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

public interface EmpresaRepository extends JpaRepository<Empresa, Long> {

    Optional<Empresa> findByEmpresaId(String empresaId);

    @Query("""
            select e
            from Empresa e
            left join fetch e.responsavel
            order by e.nome asc
            """)
    List<Empresa> findAllWithResponsavelOrderByNome();
}
