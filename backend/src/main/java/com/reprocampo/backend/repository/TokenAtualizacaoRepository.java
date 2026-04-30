package com.reprocampo.backend.repository;

import com.reprocampo.backend.entity.TokenAtualizacao;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface TokenAtualizacaoRepository extends JpaRepository<TokenAtualizacao, Long> {

    Optional<TokenAtualizacao> findByTokenAndRevogadoFalse(String token);

    void deleteAllByUsuarioId(Long idUsuario);
}
