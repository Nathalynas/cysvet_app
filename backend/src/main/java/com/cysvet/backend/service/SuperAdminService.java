package com.cysvet.backend.service;

import com.cysvet.backend.dto.superadmin.ClientCompanyResponse;
import com.cysvet.backend.dto.superadmin.ClientCompanyStatus;
import com.cysvet.backend.dto.superadmin.CreateClientCompanyRequest;
import com.cysvet.backend.dto.superadmin.CreateClientCompanyResponse;
import com.cysvet.backend.dto.superadmin.ResendAccessResponse;
import com.cysvet.backend.entity.Empresa;
import com.cysvet.backend.entity.Perfil;
import com.cysvet.backend.entity.Usuario;
import com.cysvet.backend.entity.UsuarioEmpresa;
import com.cysvet.backend.exception.ResourceNotFoundException;
import com.cysvet.backend.repository.EmpresaRepository;
import com.cysvet.backend.repository.TokenAtualizacaoRepository;
import com.cysvet.backend.repository.UsuarioEmpresaRepository;
import com.cysvet.backend.repository.UsuarioRepository;
import com.cysvet.backend.tenant.BypassTenant;
import java.util.List;
import java.util.Locale;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.support.TransactionTemplate;

@Service
@BypassTenant
@RequiredArgsConstructor
public class SuperAdminService {

    private final EmpresaRepository empresaRepository;
    private final UsuarioRepository usuarioRepository;
    private final UsuarioEmpresaRepository usuarioEmpresaRepository;
    private final TokenAtualizacaoRepository tokenAtualizacaoRepository;
    private final PasswordEncoder passwordEncoder;
    private final TemporaryPasswordGenerator temporaryPasswordGenerator;
    private final AccessEmailSender accessEmailSender;
    private final TransactionTemplate transactionTemplate;

    @Transactional(readOnly = true)
    public List<ClientCompanyResponse> list() {
        return empresaRepository.findAllWithResponsavelOrderByNome().stream()
                .map(this::toResponse)
                .toList();
    }

    // Os metodos create e resendAccess nao sao transacionais: a persistencia confirma primeiro e o e-mail
    // so e enviado depois do commit, para nao enviar credenciais que nao existem e para nao manter
    // conexao e locks do banco presos a uma chamada SMTP.
    public CreateClientCompanyResponse create(CreateClientCompanyRequest request) {
        String email = request.responsibleEmail().trim().toLowerCase(Locale.ROOT);
        String companyName = request.companyName().trim();
        String responsibleName = request.responsibleName().trim();
        String temporaryPassword = temporaryPasswordGenerator.generate();

        ClientCompanyResponse company = transactionTemplate.execute(status ->
                persistCompany(email, companyName, responsibleName, temporaryPassword));

        boolean emailSent = accessEmailSender.sendTemporaryPassword(
                email, responsibleName, companyName, temporaryPassword);
        return new CreateClientCompanyResponse(company, emailSent);
    }

    private ClientCompanyResponse persistCompany(
            String email, String companyName, String responsibleName, String temporaryPassword) {
        if (usuarioRepository.existsByEmailIgnoreCase(email)) {
            throw new IllegalArgumentException("E-mail ja cadastrado");
        }

        Usuario responsible = new Usuario();
        responsible.setNome(responsibleName);
        responsible.setEmail(email);
        responsible.setSenha(passwordEncoder.encode(temporaryPassword));
        responsible.setPerfil(Perfil.ADMIN);
        responsible.setTrocarSenha(true);
        responsible = usuarioRepository.saveAndFlush(responsible);

        Empresa empresa = new Empresa();
        empresa.setEmpresaId(UUID.randomUUID().toString());
        empresa.setNome(companyName);
        empresa.setEmail(email);
        empresa.setAtivo(true);
        empresa.setResponsavel(responsible);
        empresa = empresaRepository.saveAndFlush(empresa);

        UsuarioEmpresa membership = new UsuarioEmpresa();
        membership.setUsuario(responsible);
        membership.setEmpresa(empresa);
        membership.setAtivo(true);
        usuarioEmpresaRepository.saveAndFlush(membership);

        return toResponse(empresa);
    }

    @Transactional
    public ClientCompanyResponse updateStatus(Long id, boolean active) {
        Empresa empresa = findEmpresa(id);
        empresa.setAtivo(active);
        empresa = empresaRepository.saveAndFlush(empresa);

        if (!active) {
            List<Long> userIds = usuarioEmpresaRepository.findAllByEmpresaIdOrderByUsuarioNomeAsc(id).stream()
                    .map(link -> link.getUsuario().getId())
                    .toList();
            if (!userIds.isEmpty()) {
                tokenAtualizacaoRepository.revokeAllActiveForUsers(userIds);
            }
        }
        return toResponse(empresa);
    }

    public ResendAccessResponse resendAccess(Long id) {
        String temporaryPassword = temporaryPasswordGenerator.generate();
        String[] recipient = transactionTemplate.execute(status ->
                persistNewPassword(id, temporaryPassword));

        boolean emailSent = accessEmailSender.sendTemporaryPassword(
                recipient[0], recipient[1], recipient[2], temporaryPassword);
        return new ResendAccessResponse(emailSent);
    }

    // Retorna {e-mail, nome do responsavel, nome da empresa}.
    private String[] persistNewPassword(Long id, String temporaryPassword) {
        Empresa empresa = findEmpresa(id);
        Usuario responsible = empresa.getResponsavel();
        if (responsible == null) {
            throw new IllegalArgumentException("Empresa sem responsavel");
        }

        responsible.setSenha(passwordEncoder.encode(temporaryPassword));
        responsible.setTrocarSenha(true);
        usuarioRepository.saveAndFlush(responsible);
        tokenAtualizacaoRepository.revokeAllActiveForUsers(List.of(responsible.getId()));
        return new String[] {responsible.getEmail(), responsible.getNome(), empresa.getNome()};
    }

    private Empresa findEmpresa(Long id) {
        return empresaRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Empresa nao encontrada"));
    }

    private ClientCompanyResponse toResponse(Empresa empresa) {
        Usuario responsible = empresa.getResponsavel();
        return new ClientCompanyResponse(
                empresa.getId(),
                empresa.getNome(),
                responsible != null ? responsible.getNome() : null,
                responsible != null ? responsible.getEmail() : null,
                statusOf(empresa),
                empresa.getDataCriacao()
        );
    }

    private ClientCompanyStatus statusOf(Empresa empresa) {
        if (!empresa.isAtivo()) {
            return ClientCompanyStatus.DESATIVADA;
        }
        Usuario responsible = empresa.getResponsavel();
        if (responsible != null && responsible.isTrocarSenha()) {
            return ClientCompanyStatus.AGUARDANDO_PRIMEIRO_ACESSO;
        }
        return ClientCompanyStatus.ATIVA;
    }
}
