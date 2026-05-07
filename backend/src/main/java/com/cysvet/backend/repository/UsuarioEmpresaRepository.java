package com.cysvet.backend.repository;

import com.cysvet.backend.entity.UsuarioEmpresa;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;

public interface UsuarioEmpresaRepository extends JpaRepository<UsuarioEmpresa, Long> {

    boolean existsByUsuarioIdAndEmpresaIdAndAtivoTrue(Long usuarioId, Long empresaId);

    List<UsuarioEmpresa> findAllByUsuarioIdAndAtivoTrueOrderByEmpresaNomeAsc(Long usuarioId);
}
