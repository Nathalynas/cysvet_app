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
        return usuarioEmpresaRepository.existsByUsuarioIdAndEmpresaIdAndAtivoTrue(userId, tenantId);
    }

    public List<UsuarioEmpresa> findActiveMemberships(Long userId) {
        return usuarioEmpresaRepository.findAllByUsuarioIdAndAtivoTrueOrderByEmpresaNomeAsc(userId);
    }
}
