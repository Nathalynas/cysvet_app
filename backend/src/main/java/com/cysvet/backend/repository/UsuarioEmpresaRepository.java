package com.cysvet.backend.repository;

import com.cysvet.backend.entity.UsuarioEmpresa;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface UsuarioEmpresaRepository extends JpaRepository<UsuarioEmpresa, Long> {

    boolean existsByUsuarioIdAndEmpresaIdAndAtivoTrue(Long usuarioId, Long empresaId);

    boolean existsByUsuarioIdAndAtivoTrue(Long usuarioId);

    long countByUsuarioId(Long usuarioId);

    @EntityGraph(attributePaths = {"usuario", "empresa"})
    List<UsuarioEmpresa> findAllByUsuarioIdAndAtivoTrueOrderByEmpresaNomeAsc(Long usuarioId);

    @EntityGraph(attributePaths = {"usuario", "empresa"})
    Optional<UsuarioEmpresa> findByUsuarioIdAndEmpresaId(Long usuarioId, Long empresaId);

    @Query("""
            select ue
            from UsuarioEmpresa ue
            join fetch ue.usuario u
            join fetch ue.empresa e
            where e.id = :empresaId
            order by u.nome asc
            """)
    List<UsuarioEmpresa> findAllByEmpresaIdOrderByUsuarioNomeAsc(@Param("empresaId") Long empresaId);
}
