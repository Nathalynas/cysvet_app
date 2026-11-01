package com.cysvet.backend.service;

import com.cysvet.backend.dto.account.AccountPreferences;
import com.cysvet.backend.entity.StatusReprodutivoAnimal;
import com.cysvet.backend.entity.Usuario;
import com.cysvet.backend.repository.UsuarioRepository;
import com.cysvet.backend.tenant.BypassTenant;
import java.util.Arrays;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Preferencias guardadas por usuario, para valerem em qualquer aparelho. O
 * usuario nao pertence a uma empresa, entao nao ha escopo de tenant (como no
 * AuthService); so o proprio usuario autenticado e lido e alterado.
 */
@Service
@BypassTenant
@RequiredArgsConstructor
public class PreferenciasUsuarioService {

    static final List<StatusReprodutivoAnimal> ATALHOS_PADRAO = List.of(
            StatusReprodutivoAnimal.PREGNANT,
            StatusReprodutivoAnimal.EMPTY,
            StatusReprodutivoAnimal.INSEMINATED,
            StatusReprodutivoAnimal.WAITING_DIAGNOSIS
    );
    static final int MAXIMO_ATALHOS = 8;

    private final UsuarioRepository usuarioRepository;

    @Transactional(readOnly = true)
    public AccountPreferences get(Usuario usuario) {
        return toResponse(usuario.getAtalhosSituacaoReprodutiva());
    }

    @Transactional
    public AccountPreferences update(Usuario usuario, AccountPreferences request) {
        List<String> atalhos = request == null ? null : request.atalhosSituacaoReprodutiva();
        String gravado = atalhos == null ? null : String.join(",", validar(atalhos));
        Usuario entity = usuarioRepository.findById(usuario.getId()).orElse(usuario);
        entity.setAtalhosSituacaoReprodutiva(gravado);
        usuarioRepository.save(entity);
        return toResponse(gravado);
    }

    private List<String> validar(List<String> atalhos) {
        Set<String> valores = new LinkedHashSet<>();
        for (String atalho : atalhos) {
            StatusReprodutivoAnimal status = StatusReprodutivoAnimal.fromValue(atalho);
            if (status == null) {
                throw new IllegalArgumentException("Situacao reprodutiva vazia nos atalhos");
            }
            // "Seca" e situacao produtiva, escolhida em outro campo da visita.
            if (status == StatusReprodutivoAnimal.DRY) {
                throw new IllegalArgumentException("Seca e situacao produtiva, nao pode ser atalho reprodutivo");
            }
            valores.add(status.getValue());
        }
        if (valores.isEmpty()) {
            throw new IllegalArgumentException("Escolha ao menos um atalho");
        }
        if (valores.size() > MAXIMO_ATALHOS) {
            throw new IllegalArgumentException("Escolha no maximo " + MAXIMO_ATALHOS + " atalhos");
        }
        return List.copyOf(valores);
    }

    private AccountPreferences toResponse(String gravado) {
        if (gravado == null || gravado.isBlank()) {
            return new AccountPreferences(
                    ATALHOS_PADRAO.stream().map(StatusReprodutivoAnimal::getValue).toList(), true);
        }
        return new AccountPreferences(Arrays.asList(gravado.split(",")), false);
    }
}
