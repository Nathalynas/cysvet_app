package com.cysvet.backend.repository;

import com.cysvet.backend.entity.TokenAtualizacao;
import java.util.Collection;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface TokenAtualizacaoRepository extends JpaRepository<TokenAtualizacao, Long> {

    Optional<TokenAtualizacao> findByTokenAndRevogadoFalse(String token);

    void deleteAllByUsuarioId(Long idUsuario);

    @Modifying(flushAutomatically = true)
    @Query("update TokenAtualizacao t set t.revogado = true where t.usuario.id in :userIds and t.revogado = false")
    int revokeAllActiveForUsers(@Param("userIds") Collection<Long> userIds);
}
