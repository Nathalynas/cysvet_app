package com.cysvet.backend.support;

import com.cysvet.backend.dto.auth.AuthResponse;
import com.cysvet.backend.dto.auth.LoginRequest;
import com.cysvet.backend.entity.Empresa;
import com.cysvet.backend.entity.Perfil;
import com.cysvet.backend.entity.Usuario;
import com.cysvet.backend.entity.UsuarioEmpresa;
import com.cysvet.backend.repository.EmpresaRepository;
import com.cysvet.backend.repository.UsuarioEmpresaRepository;
import com.cysvet.backend.repository.UsuarioRepository;
import com.cysvet.backend.service.AuthService;
import java.util.UUID;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

@Component
public class TestAccounts {

    private final EmpresaRepository empresaRepository;
    private final UsuarioRepository usuarioRepository;
    private final UsuarioEmpresaRepository usuarioEmpresaRepository;
    private final PasswordEncoder passwordEncoder;
    private final AuthService authService;

    public TestAccounts(
            EmpresaRepository empresaRepository,
            UsuarioRepository usuarioRepository,
            UsuarioEmpresaRepository usuarioEmpresaRepository,
            PasswordEncoder passwordEncoder,
            AuthService authService
    ) {
        this.empresaRepository = empresaRepository;
        this.usuarioRepository = usuarioRepository;
        this.usuarioEmpresaRepository = usuarioEmpresaRepository;
        this.passwordEncoder = passwordEncoder;
        this.authService = authService;
    }

    @Transactional
    public AuthResponse createAdmin(String name, String email, String password) {
        Usuario user = new Usuario();
        user.setNome(name);
        user.setEmail(email);
        user.setSenha(passwordEncoder.encode(password));
        user.setPerfil(Perfil.ADMIN);
        Usuario savedUser = usuarioRepository.saveAndFlush(user);

        Empresa empresa = new Empresa();
        empresa.setEmpresaId(UUID.randomUUID().toString());
        empresa.setNome("Empresa de " + name);
        empresa.setEmail(email);
        empresa.setAtivo(true);
        Empresa savedEmpresa = empresaRepository.saveAndFlush(empresa);

        UsuarioEmpresa membership = new UsuarioEmpresa();
        membership.setUsuario(savedUser);
        membership.setEmpresa(savedEmpresa);
        membership.setAtivo(true);
        usuarioEmpresaRepository.saveAndFlush(membership);

        return authService.login(new LoginRequest(email, password));
    }

    @Transactional(readOnly = true)
    public Empresa companyOf(String email) {
        Usuario user = usuarioRepository.findByEmail(email).orElseThrow();
        return usuarioEmpresaRepository.findAllByUsuarioIdAndAtivoTrueOrderByEmpresaNomeAsc(user.getId())
                .get(0).getEmpresa();
    }
}
