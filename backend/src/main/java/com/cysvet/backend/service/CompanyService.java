package com.cysvet.backend.service;

import com.cysvet.backend.dto.auth.EmpresaPermitidaResponse;
import com.cysvet.backend.dto.company.UpdateCompanyRequest;
import com.cysvet.backend.entity.Empresa;
import com.cysvet.backend.entity.Perfil;
import com.cysvet.backend.entity.Usuario;
import com.cysvet.backend.exception.ResourceNotFoundException;
import com.cysvet.backend.repository.EmpresaRepository;
import com.cysvet.backend.tenant.TenantContext;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class CompanyService {

    private final EmpresaRepository empresaRepository;
    private final UsuarioAutenticadoProvider usuarioAutenticadoProvider;

    @Transactional
    public EmpresaPermitidaResponse updateActiveCompany(UpdateCompanyRequest request) {
        Usuario usuario = usuarioAutenticadoProvider.getCurrentUser();
        if (usuario.getPerfil() != Perfil.ADMIN) {
            throw new AccessDeniedException("Apenas administradores podem atualizar a empresa");
        }

        Long tenantId = TenantContext.getTenantId();
        if (tenantId == null) {
            throw new IllegalStateException("Tenant ativo nao encontrado na requisicao");
        }

        Empresa empresa = empresaRepository.findById(tenantId)
                .orElseThrow(() -> new ResourceNotFoundException("Empresa ativa nao encontrada"));

        empresa.setNome(request.name().trim());
        empresa.setEmail(request.email().trim());

        Empresa savedEmpresa = empresaRepository.saveAndFlush(empresa);
        return new EmpresaPermitidaResponse(
                savedEmpresa.getId(),
                savedEmpresa.getNome(),
                savedEmpresa.getEmail()
        );
    }
}
