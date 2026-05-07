package com.cysvet.backend.repository;

import com.cysvet.backend.entity.Empresa;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface EmpresaRepository extends JpaRepository<Empresa, Long> {

    Optional<Empresa> findByEmpresaId(String empresaId);
}
