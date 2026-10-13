package com.cysvet.backend.service;

import com.cysvet.backend.entity.UsuarioEmpresa;
import com.cysvet.backend.repository.UsuarioEmpresaRepository;
import com.cysvet.backend.tenant.BypassTenant;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

@Service
@BypassTenant
@RequiredArgsConstructor
public class TenantAccessService {

    private final UsuarioEmpresaRepository usuarioEmpresaRepository;

    public boolean userHasAccessToTenant(Long userId, Long tenantId) {
        return usuarioEmpresaRepository.existsByUsuarioIdAndEmpresaIdAndAtivoTrueAndEmpresaAtivoTrue(userId, tenantId);
    }

    public List<UsuarioEmpresa> findActiveMemberships(Long userId) {
        return usuarioEmpresaRepository.findAllByUsuarioIdAndAtivoTrueAndEmpresaAtivoTrueOrderByEmpresaNomeAsc(userId);
    }

    // Vinculo ativo com a empresa informada, mas a empresa foi desativada.
    public boolean isCompanyInactiveForUser(Long userId, Long tenantId) {
        return usuarioEmpresaRepository.existsByUsuarioIdAndEmpresaIdAndAtivoTrue(userId, tenantId)
                && !usuarioEmpresaRepository.existsByUsuarioIdAndEmpresaIdAndAtivoTrueAndEmpresaAtivoTrue(userId, tenantId);
    }

    // Tem vinculo ativo, mas todas as empresas estao desativadas.
    public boolean hasOnlyInactiveCompanies(Long userId) {
        return usuarioEmpresaRepository.existsByUsuarioIdAndAtivoTrue(userId)
                && findActiveMemberships(userId).isEmpty();
    }
}
