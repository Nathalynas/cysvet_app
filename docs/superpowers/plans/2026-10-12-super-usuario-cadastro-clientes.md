# Super usuário e cadastro de clientes — plano de implementação

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remover o cadastro público e criar o perfil `SUPER_ADMIN`, que cadastra empresas e responsáveis com senha provisória enviada por e-mail. Desativar uma empresa bloqueia os usuários dela na hora, e a troca de senha é obrigatória no primeiro acesso.

**Architecture:** No backend entram uma migration (V18), um perfil novo, uma conta de super usuário criada na inicialização a partir do `.env`, o `SuperAdminService`/`SuperAdminController` em `/api/super/**`, o `AccountController` em `/api/account/password` e o envio de e-mail por `JavaMailSender`. O `JwtAuthenticationFilter` passa a bloquear empresa desativada e senha pendente. No Flutter, o redirecionamento do roteador vira uma função pura testável, e entram duas páginas novas: o painel do super usuário e "Defina sua senha".

**Tech Stack:** Java 17, Spring Boot 3.5, Spring Security, Flyway, MySQL 8 / H2 nos testes, `spring-boot-starter-mail`; Flutter, Riverpod, GoRouter, Dio, dart_mappable.

**Spec:** `docs/superpowers/specs/2026-10-12-super-usuario-cadastro-clientes-design.md`

## Global Constraints

- Commits **sem** linha `Co-Authored-By`. Mensagens em português no padrão do repo (`feat:`, `fix:`, `test:`, `docs:`, `chore:`).
- Trabalhar no branch `homologacao`. Não fazer push.
- A senha provisória nunca aparece em log, em resposta da API ou na tela.
- Senha nova: mínimo 6 caracteres (regra atual).
- Senha provisória: gerador seguro (`SecureRandom`), 12 caracteres do alfabeto `ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789`.
- Mensagens de erro fixas, sem acento, no estilo atual do backend: `"Empresa desativada"`, `"Troca de senha obrigatoria"`, `"E-mail ja cadastrado"`.
- Variáveis de ambiente: `SUPERADMIN_EMAIL`, `SUPERADMIN_PASSWORD`, `SUPERADMIN_NAME` (padrão `Super usuario`), `SPRING_MAIL_HOST`, `SPRING_MAIL_PORT`, `SPRING_MAIL_USERNAME`, `SPRING_MAIL_PASSWORD`, `APP_MAIL_FROM`.
- Toda migration nova também atualiza `FlywayDatabaseReadinessTest` (contagem), `dicionario_de_dados.md` e `backend/sql/mysql/cysvet_schema.sql` (regra do `AGENTS.md`).
- Testes do backend: `cd backend && mvn test`, sem wrapper. Frontend: `cd frontend && flutter analyze && flutter test`.
- Não alterar o fluxo da tela Equipe (`TeamService`), a estratégia de sync nem o "Esqueci minha senha".

## Review Focus

1. **Usuário de empresa desativada com o app aberto e access token válido**: a próxima requisição de dados ou de sync recebe 403 `"Empresa desativada"`, o app volta ao login com essa mensagem e **não** apaga a fila local de sync. Os testes ficam nas Tasks 3 e 8.
2. **Usuário vinculado a duas empresas, uma delas desativada**: o login funciona e só a empresa ativa aparece em `empresas`. Teste na Task 3.
3. **Login com a senha provisória e o app reiniciado antes da troca**: a sessão restaurada continua presa em `/trocar-senha`, e as rotas de dados devolvem 403 no backend. Testes nas Tasks 3 e 8.
4. **Super usuário tentando rota de dados de clínica, com ou sem header `empresaid`**: recebe 403, nunca dados. Teste na Task 3.
5. **E-mail do responsável já existente (inclusive de um veterinário ou do próprio super usuário), com caixa e espaços diferentes**: 400 `"E-mail ja cadastrado"` e nada é criado. Teste na Task 5.

---

### Task 1: Fixture de contas para os testes (antes de remover o `register`)

Hoje 11 classes de teste criam contas com `authService.register(new RegisterRequest(...))`. Esta task troca todas por uma fixture, para que a Task 6 possa apagar o `register` sem quebrar nenhum teste.

**Files:**
- Create: `backend/src/test/java/com/cysvet/backend/support/TestAccounts.java`
- Modify (trocar as chamadas): `AnimalSpreadsheetImportIntegrationTest`, `DataReliabilityIntegrationTest`, `PropertyAnimalIntegrationTest`, `SyncIntegrationTest`, `UserTeamIntegrationTest`, `VisitaEventosIntegrationTest`, `SyncQueryCountBenchmarkTest`, `AuthenticationErrorsIntegrationTest`, `TenantIsolationByIdIntegrationTest`, `TenantRequestSecurityIntegrationTest`, `AuthServiceIntegrationTest`

**Interfaces:**
- Produces: `@Component class TestAccounts` com
  - `AuthResponse createAdmin(String name, String email, String password)`: persiste `Empresa` (`nome = "Empresa de " + name`, `email`, `ativo = true`, `empresaId = UUID`), `Usuario` ADMIN com a senha codificada e `UsuarioEmpresa` ativo, e devolve `authService.login(new LoginRequest(email, password))`.
  - `Empresa companyOf(String email)`: devolve a primeira empresa ativa do usuário.

A classe fica em `com.cysvet.backend.support`, dentro do pacote escaneado pelo `@SpringBootTest`.

- [ ] **Step 1:** Criar `TestAccounts`. Usar os repositórios `EmpresaRepository`, `UsuarioRepository`, `UsuarioEmpresaRepository` e o `PasswordEncoder`.
- [ ] **Step 2:** Em cada arquivo listado, trocar `authService.register(new RegisterRequest(a, b, c))` por `testAccounts.createAdmin(a, b, c)`, injetar `@Autowired TestAccounts testAccounts` e remover os imports de `RegisterRequest` que não forem mais usados. Teste que faz `POST /api/auth/register` por HTTP (se houver) passa a usar a fixture. O teste `registerShouldPersistUserWithGeneratedIdBeforeSavingRefreshToken` do `AuthServiceIntegrationTest` vira `loginShouldPersistRefreshTokenForUser`, com as mesmas asserções sobre token e `sessionPolicy`.
- [ ] **Step 3:** Rodar `cd backend && mvn test`. Esperado: BUILD SUCCESS, com o mesmo número de testes de antes, menos nenhum.
- [ ] **Step 4:** Commit: `test: fixture de contas substitui o cadastro público nos testes`

---

### Task 2: Schema — perfil `SUPER_ADMIN`, `trocar_senha` e responsável da empresa

**Files:**
- Create: `backend/src/main/resources/db/migration/V18__super_admin.sql`
- Modify: `entity/Perfil.java`, `entity/Usuario.java`, `entity/Empresa.java`
- Modify: `backend/src/test/java/com/cysvet/backend/config/FlywayDatabaseReadinessTest.java` (17 → 18, e `assertHistoryVersionExists(connection, "18")`)
- Modify: `dicionario_de_dados.md`, `backend/sql/mysql/cysvet_schema.sql`, `AGENTS.md` ("a última é a V18; a próxima é a V19")

**Interfaces:**
- Produces:
  - `Perfil.SUPER_ADMIN`
  - `Usuario.trocarSenha` (`boolean`, coluna `trocar_senha`, padrão false)
  - `Empresa.responsavel` (`@ManyToOne(fetch = LAZY) Usuario`, coluna `responsavel_usuario_id`, nullable)

Conteúdo da migration:

```sql
-- Troca obrigatoria de senha (senha provisoria enviada pelo super usuario).
ALTER TABLE usuario ADD COLUMN trocar_senha BOOLEAN NOT NULL DEFAULT FALSE;

-- Usuario responsavel pela empresa (criado pelo super usuario). Empresas
-- antigas recebem o ADMIN mais antigo vinculado, se houver.
ALTER TABLE empresa ADD COLUMN responsavel_usuario_id BIGINT NULL;
ALTER TABLE empresa ADD CONSTRAINT fk_empresa_responsavel
    FOREIGN KEY (responsavel_usuario_id) REFERENCES usuario (id);

UPDATE empresa
SET responsavel_usuario_id = (
    SELECT MIN(u.id)
    FROM usuario_empresa ue
    JOIN usuario u ON u.id = ue.id_usuario
    WHERE ue.id_empresa = empresa.id AND u.perfil = 'ADMIN'
);
```

- [ ] **Step 1:** Atualizar o `FlywayDatabaseReadinessTest` para 18 migrations. Rodar `mvn test -Dtest=FlywayDatabaseReadinessTest`. Esperado: FAIL (17 ≠ 18).
- [ ] **Step 2:** Criar a migration e os campos nas entidades. Conferir se a tabela de vínculo se chama mesmo `usuario_empresa`, olhando as migrations antigas; se o nome for outro, ajustar o SQL.
- [ ] **Step 3:** Rodar `mvn test`. Esperado: tudo passando. O `ddl-auto: validate` confirma que entidades e schema batem.
- [ ] **Step 4:** Atualizar o dicionário, o `cysvet_schema.sql` e o `AGENTS.md`.
- [ ] **Step 5:** Commit: `feat: perfil super admin, troca de senha e responsável da empresa no schema`

---

### Task 3: Bloqueios de acesso — empresa desativada, senha pendente e rotas do super usuário

**Files:**
- Modify: `repository/UsuarioEmpresaRepository.java`, `service/TenantAccessService.java`
- Modify: `security/AuthenticatedUserPrincipal.java`, `security/CustomUserDetailService.java`, `security/JwtAuthenticationFilter.java`, `security/SecurityConfig.java`
- Modify: `service/AuthService.java` (`buildAuthResponse`), `dto/auth/UsuarioAutenticadoResponse.java`
- Test: `backend/src/test/java/com/cysvet/backend/security/AccountAccessRulesIntegrationTest.java` (novo)

**Interfaces:**
- Consumes: Task 1 (`TestAccounts`), Task 2 (campos novos)
- Produces:
  - `UsuarioEmpresaRepository.findAllByUsuarioIdAndAtivoTrueAndEmpresaAtivoTrueOrderByEmpresaNomeAsc(Long)` e `existsByUsuarioIdAndEmpresaIdAndAtivoTrueAndEmpresaAtivoTrue(Long, Long)`. O `TenantAccessService.findActiveMemberships` e o `userHasAccessToTenant` passam a usar esses métodos.
  - `TenantAccessService.isCompanyInactiveForUser(Long userId, Long tenantId): boolean`: o vínculo existe e está ativo, mas `empresa.ativo = false`.
  - `TenantAccessService.hasOnlyInactiveCompanies(Long userId): boolean`: o usuário tem vínculo ativo, mas nenhuma empresa ativa.
  - `AuthenticatedUserPrincipal.passwordChangeRequired` (`boolean`, novo componente no construtor), preenchido a partir de `Usuario.trocarSenha`.
  - `UsuarioAutenticadoResponse` ganha o último componente `boolean trocarSenha`.
  - `AuthResponse` de `SUPER_ADMIN`: `empresaAtivaId = null`, `empresas = []`.

Regras do filtro, nesta ordem, depois de autenticar:
1. Se `passwordChangeRequired` for true e o caminho não começar com `/api/account/`: 403 `"Troca de senha obrigatoria"`.
2. Os caminhos `/api/super/` e `/api/account/` não passam pela validação de empresa (somar ao `requiresTenantValidation`).
3. Se `userHasAccessToTenant` for false e `isCompanyInactiveForUser` for true: 403 `"Empresa desativada"`. Senão continua o 403 atual, `"Usuario sem acesso a empresa informada"`.

`SecurityConfig`: `.requestMatchers("/api/super/**").hasRole("SUPER_ADMIN")` antes do `anyRequest()`.

`buildAuthResponse`:
- `SUPER_ADMIN` → resposta sem empresa.
- Usuário sem empresa ativa e com `hasOnlyInactiveCompanies` → `AccessDeniedException("Empresa desativada")`.
- Demais casos sem empresa → continua `"Usuario sem empresa vinculada ativa"`.

Isso vale para login e para refresh.

- [ ] **Step 1: Escrever os testes que falham** em `AccountAccessRulesIntegrationTest` (MockMvc, mesmo padrão do `TenantRequestSecurityIntegrationTest`). Para criar o super usuário, persistir um `Usuario` com `Perfil.SUPER_ADMIN` direto pelo repositório.
  - `deactivatedCompanyBlocksLoginWithEmpresaDesativada`: depois de `empresa.setAtivo(false)`, `POST /api/auth/login` → 403 e `$.message == "Empresa desativada"`.
  - `deactivatedCompanyBlocksExistingAccessTokenImmediately`: login, desativa a empresa, `GET /api/propriedades` (ou outra rota de dados existente) com o token antigo → 403 `"Empresa desativada"`.
  - `deactivatedCompanyBlocksRefresh`: `POST /api/auth/refresh` → 403 `"Empresa desativada"`.
  - `userWithAnotherActiveCompanyStillLogsIn`: usuário com vínculo em A (desativada) e B (ativa) → login 200, e `empresas` contém só B.
  - `passwordChangeRequiredBlocksDataRoutes`: com `trocarSenha = true`, a rota de dados → 403 `"Troca de senha obrigatoria"`, e `$.user.trocarSenha == true` na resposta do login.
  - `superAdminLoginReturnsNoCompany`: `$.user.perfil == "SUPER_ADMIN"`, `$.empresas` vazio e `$.empresaAtivaId` nulo.
  - `superAdminCannotReadClinicData`: com e sem o header `empresaid` de uma empresa existente → 403 (com o header) ou 400/403 (sem o header), e nunca 200.
  - `adminCannotCallSuperRoutes`: um ADMIN em `GET /api/super/companies` → 403.
- [ ] **Step 2:** Rodar `mvn test -Dtest=AccountAccessRulesIntegrationTest`. Esperado: FAIL.
- [ ] **Step 3:** Implementar as regras descritas acima.
- [ ] **Step 4:** Rodar `mvn test`. Esperado: tudo passando. O `adminCannotCallSuperRoutes` ainda pode dar 404 antes da Task 5: aceitar `isForbidden()` só depois de existir o controller, ou deixar esse teste para a Task 5.
- [ ] **Step 5:** Commit: `feat: bloqueio por empresa desativada e por troca de senha pendente`

---

### Task 4: Conta do super usuário a partir do `.env` e envio de e-mail

**Files:**
- Create: `service/SuperAdminBootstrap.java` (`ApplicationRunner`)
- Create: `service/TemporaryPasswordGenerator.java`
- Create: `service/AccessEmailSender.java`
- Modify: `backend/pom.xml` (`spring-boot-starter-mail`, sem versão: vem do parent)
- Modify: `application.yml` (`app.superadmin.email: ${SUPERADMIN_EMAIL:}`, `app.superadmin.password: ${SUPERADMIN_PASSWORD:}`, `app.superadmin.name: ${SUPERADMIN_NAME:Super usuario}`, `app.mail.from: ${APP_MAIL_FROM:}`)
- Modify: `application-prod.yml` (`spring.mail.properties.mail.smtp.auth: true`, `spring.mail.properties.mail.smtp.starttls.enable: true`)
- Modify: `config/ProductionSettingsValidator.java` (em prod, exigir `spring.mail.host` e `app.mail.from` preenchidos: `"SPRING_MAIL_HOST e APP_MAIL_FROM devem ser configurados em producao"`)
- Test: `service/SuperAdminBootstrapIntegrationTest.java`, `service/TemporaryPasswordGeneratorTest.java`, `service/AccessEmailSenderTest.java`

**Interfaces:**
- Produces:
  - `TemporaryPasswordGenerator.generate(): String`
  - `AccessEmailSender.sendTemporaryPassword(String toEmail, String userName, String companyName, String temporaryPassword): boolean`. Devolve false se o `JavaMailSender` lançar `MailException`; o log registra só o e-mail do destino e a causa. Recebe `ObjectProvider<JavaMailSender>`: sem SMTP configurado, registra `"SMTP nao configurado; e-mail de acesso para {} nao enviado"` e devolve true (comportamento de dev; em prod o validator impede subir sem SMTP).

Corpo do e-mail (texto puro), assunto `Seu acesso ao CYSVET`:

```
Olá, {userName}!

A empresa {companyName} foi cadastrada no CYSVET.

Login: {toEmail}
Senha provisória: {temporaryPassword}

No primeiro acesso você deverá definir uma nova senha.
```

Bootstrap:
- Se o e-mail ou a senha estiverem em branco, não faz nada.
- Se o usuário não existe, cria `SUPER_ADMIN` com `trocarSenha = false`.
- Se existe e já é `SUPER_ADMIN`, não altera nada (nem a senha).
- Se existe com outro perfil, registra um warn e **não** promove a conta.

- [ ] **Step 1: Testes que falham:**
  - `TemporaryPasswordGeneratorTest.generatesTwelveCharsFromUnambiguousAlphabet`: 200 gerações, todas com `length == 12`, `matches("[A-HJ-NP-Za-km-z2-9]{12}")` e pelo menos 190 distintas.
  - `SuperAdminBootstrapIntegrationTest` (`@SpringBootTest(properties = {"app.superadmin.email=root@cysvet.test", "app.superadmin.password=segredo123"})`):
    - `createsSuperAdminOnStartup`: o usuário existe, `perfil == SUPER_ADMIN`, `trocarSenha == false` e `passwordEncoder.matches("segredo123", senha)`.
    - `doesNotOverwriteExistingPassword`: troca o hash, roda `bootstrap.run(null)` de novo e o hash continua o mesmo.
    - `doesNotPromoteExistingAdmin`: com um ADMIN de mesmo e-mail criado antes, depois de `run` o perfil continua `ADMIN`.
  - `AccessEmailSenderTest` (unitário, com `JavaMailSender` mockado pelo Mockito): o `SimpleMailMessage` enviado tem `to == [email]`, `from == app.mail.from`, o assunto acima e o corpo contendo a senha. Quando o mock lança `MailSendException`, devolve false.
- [ ] **Step 2:** Rodar os três. Esperado: FAIL (as classes ainda não existem).
- [ ] **Step 3:** Implementar e adicionar a dependência.
- [ ] **Step 4:** Rodar `mvn test`. Esperado: tudo passando.
- [ ] **Step 5:** Commit: `feat: conta do super usuário pelo ambiente e envio de e-mail de acesso`

---

### Task 5: API do super usuário — listar, criar, desativar/reativar, reenviar

**Files:**
- Create: `controller/SuperAdminController.java` (`@RequestMapping("/api/super/companies")`, mesmo estilo do `CompanyController` com Swagger)
- Create: `service/SuperAdminService.java` (`@BypassTenant`, como o `CustomUserDetailService`)
- Create: `dto/superadmin/CreateClientCompanyRequest.java`, `ClientCompanyResponse.java`, `CreateClientCompanyResponse.java`, `UpdateClientCompanyStatusRequest.java`, `ResendAccessResponse.java`
- Modify: `repository/TokenAtualizacaoRepository.java`
- Test: `controller/SuperAdminIntegrationTest.java`

**Interfaces:**
- Consumes: Task 3 (regras), Task 4 (`TemporaryPasswordGenerator`, `AccessEmailSender`)
- Produces (contrato consumido pela Task 9):
  - `GET /api/super/companies` → `List<ClientCompanyResponse>`, ordenada por nome.
  - `POST /api/super/companies` com body `CreateClientCompanyRequest(companyName, responsibleName, responsibleEmail)`, todos `@NotBlank`, `@Size(max = 255)` e `@Email` no e-mail → **201** com `CreateClientCompanyResponse(ClientCompanyResponse company, boolean emailSent)`.
  - `PATCH /api/super/companies/{id}/status` com body `UpdateClientCompanyStatusRequest(@NotNull Boolean active)` → `ClientCompanyResponse`.
  - `POST /api/super/companies/{id}/resend-access` → `ResendAccessResponse(boolean emailSent)`.
  - `ClientCompanyResponse(Long id, String name, String responsibleName, String responsibleEmail, ClientCompanyStatus status, Instant createdAt)`.
  - `enum ClientCompanyStatus { ATIVA, AGUARDANDO_PRIMEIRO_ACESSO, DESATIVADA }`: `DESATIVADA` se `!empresa.ativo`; senão `AGUARDANDO_PRIMEIRO_ACESSO` se `responsavel != null && responsavel.trocarSenha`; senão `ATIVA`.
  - `TokenAtualizacaoRepository.revokeAllActiveForUsers(Collection<Long> userIds): int` (`@Modifying @Query("update TokenAtualizacao t set t.revogado = true where t.usuario.id in :userIds and t.revogado = false")`).

Regras:
- Na criação, o e-mail é normalizado com `trim().toLowerCase(Locale.ROOT)`. Se já existir algum `Usuario` com ele → `IllegalArgumentException("E-mail ja cadastrado")` (400). O e-mail é enviado **depois** de salvar; a falha no envio só muda `emailSent`.
- Desativar revoga os refresh tokens de todos os usuários com vínculo na empresa. Reativar não mexe em token.
- Reenviar: empresa sem responsável → 400 `"Empresa sem responsavel"`. Gera uma senha nova, `trocarSenha = true`, revoga os tokens do responsável e envia. Reenviar para empresa desativada é permitido.
- Id inexistente → `ResourceNotFoundException` (404, já tratado no `GlobalExceptionHandler`).
- A listagem precisa evitar N+1: usar `join fetch e.responsavel` (left).

- [ ] **Step 1: Testes que falham** em `SuperAdminIntegrationTest`. Usar `@MockitoBean AccessEmailSender` devolvendo true e capturar a senha pelo `ArgumentCaptor`. O super usuário é logado por um helper que cria `SUPER_ADMIN` e faz login.
  - `createsCompanyAndResponsibleAndSendsEmail`: 201; `company.status == "AGUARDANDO_PRIMEIRO_ACESSO"` e `emailSent == true`. Com a senha capturada, `POST /api/auth/login` → 200 e `user.trocarSenha == true`. O JSON de resposta **não contém** a senha capturada.
  - `createReturnsEmailSentFalseWhenSendingFails`: com o mock devolvendo false → 201, `emailSent == false`, e a empresa aparece no `GET`.
  - `rejectsDuplicateEmailIgnoringCaseAndSpaces`: já existe `ana@x.com`; criar com `"  ANA@x.com "` → 400 `"E-mail ja cadastrado"`, e a contagem de empresas não muda. Repetir com o e-mail do próprio super usuário.
  - `listsCompaniesWithStatus`: três empresas (ativa, aguardando e desativada) → os três status corretos.
  - `deactivateBlocksUsersAndRevokesRefreshTokens`: depois do `PATCH active=false`, o refresh antigo do responsável → 401/403 e o login → 403 `"Empresa desativada"`. Depois do `PATCH active=true`, o login → 200.
  - `resendAccessGeneratesNewPasswordAndRequiresChange`: a senha antiga deixa de logar, a nova loga com `trocarSenha == true`, e o refresh antigo é recusado.
  - `resendForCompanyWithoutResponsibleReturns400`.
  - `unknownCompanyReturns404`.
  - `adminCannotCallSuperRoutes` (vindo da Task 3, se ficou pendente): ADMIN → 403.
- [ ] **Step 2:** Rodar `mvn test -Dtest=SuperAdminIntegrationTest`. Esperado: FAIL.
- [ ] **Step 3:** Implementar.
- [ ] **Step 4:** Rodar `mvn test`. Esperado: tudo passando.
- [ ] **Step 5:** Commit: `feat: API do super usuário para cadastrar e gerenciar empresas`

---

### Task 6: Troca obrigatória de senha e remoção do cadastro público (backend)

**Files:**
- Create: `controller/AccountController.java` (`/api/account`), `dto/account/ChangePasswordRequest.java`
- Modify: `service/AuthService.java` (novo método; remover `register` e `createDefaultCompanyForUser`)
- Modify: `controller/AuthController.java` (remover `POST /register`)
- Delete: `dto/auth/RegisterRequest.java`
- Modify: comentário do `JwtAuthenticationFilter` ("Login, registro, refresh..." → "Login, refresh e logout...")
- Test: `security/AccountPasswordIntegrationTest.java`

**Interfaces:**
- Produces:
  - `POST /api/account/password` com body `ChangePasswordRequest(@NotBlank @Size(min = 6) String newPassword)` → 204.
  - `AuthService.changeRequiredPassword(Long userId, String newPassword): void`. Se `trocarSenha` for false → `IllegalArgumentException("Troca de senha nao solicitada")` (400). Senão grava o hash e marca `trocarSenha = false`. O userId vem do principal autenticado (`UsuarioAutenticadoProvider` ou o principal do `SecurityContext`, como os outros controllers fazem).

- [ ] **Step 1: Testes que falham:**
  - `changesRequiredPasswordAndUnblocksDataRoutes`: um usuário com `trocarSenha = true` faz `POST /api/account/password` com `{"newPassword":"novaSenha1"}` → 204. Em seguida, a rota de dados com o **mesmo** access token → 200; o login com `novaSenha1` → 200 e `trocarSenha == false`.
  - `rejectsShortPassword`: `"12345"` → 400.
  - `rejectsWhenChangeNotRequired`: 400 `"Troca de senha nao solicitada"`.
  - `requiresAuthentication`: sem token → 401.
  - `publicRegisterEndpointIsGone`: `POST /api/auth/register` → 404 (ou 405), nunca 200, e nenhum usuário criado.
- [ ] **Step 2:** Rodar e ver falhar.
- [ ] **Step 3:** Implementar e remover o cadastro público. Conferir com `grep -rn "RegisterRequest\|register(" backend/src` que não sobrou nenhuma referência.
- [ ] **Step 4:** Rodar `mvn test`. Esperado: tudo passando.
- [ ] **Step 5:** Commit: `feat: troca obrigatória de senha e fim do cadastro público`

---

### Task 7: App — modelo de sessão e redirecionamento por perfil

**Files:**
- Modify: `frontend/lib/models/auth_session_model.dart` (+ regenerar `auth_session_model.mapper.dart`)
- Create: `frontend/lib/app/auth_redirect.dart`
- Modify: `frontend/lib/app/router.dart`, `frontend/lib/providers/auth_state.dart`
- Test: `frontend/test/app/auth_redirect_test.dart`, `frontend/test/models/auth_session_model_test.dart`

**Interfaces:**
- Produces:
  - `AuthenticatedUserModel.trocarSenha` (`bool`, padrão false, chave `trocarSenha`).
  - Extensão: `bool get isSuperAdmin => perfil.toUpperCase() == 'SUPER_ADMIN'`. No `displayRole`, `'SUPER_ADMIN' => 'Super usuário'`.
  - `String? resolveAuthRedirect({required bool bootstrapComplete, required AuthSessionModel? session, required String location})`, que substitui o corpo do `redirect` do `router.dart`.
  - `AuthSessionNotifier.markPasswordChanged(): Future<void>`: salva a sessão atual com `user.trocarSenha = false`.
  - Rotas novas, registradas **fora** do `ShellRoute`: `/super` e `/trocar-senha`. As páginas vêm das Tasks 8 e 9; nesta task, usar um `Placeholder` temporário só se for preciso para compilar.

Regras do `resolveAuthRedirect`, em ordem:
1. Bootstrap incompleto → `/splash` (se não estiver lá); bootstrap completo e em `/splash` → destino padrão.
2. Sem sessão: qualquer rota diferente de `/login` → `/login`.
3. `trocarSenha` → tudo que não for `/trocar-senha` vai para `/trocar-senha`.
4. `isSuperAdmin` → tudo que não for `/super` vai para `/super`.
5. Usuário comum em `/login`, `/super` ou `/trocar-senha` → `/dashboard`.

Destino padrão: `/trocar-senha`, `/super` ou `/dashboard`, seguindo a mesma prioridade.

`_normalizeSession`: se `session.user.isSuperAdmin` e `accessToken` não estiver vazio, devolver a sessão como está, sem exigir empresa.

- [ ] **Step 1: Testes que falham:**
  - `auth_session_model_test.dart`: `AuthSessionModelMapper.fromMap({'accessToken':'a','refreshToken':'r','user':{'id':1,'name':'L','email':'l@x','perfil':'SUPER_ADMIN','trocarSenha':false},'empresaAtivaId':null,'empresas':[]})` → `activeCompanyId == 0`, `user.isSuperAdmin == true` e `companies` vazio. Se o mapper não aceitar `null` em `int`, tornar o parse tolerante (hook ou `int?` com getter) e manter o teste.
  - `auth_redirect_test.dart`, um teste por regra: sem sessão em `/dashboard` → `/login`; super usuário em `/dashboard` → `/super`; super usuário em `/super` → `null`; `trocarSenha` em `/super` e em `/dashboard` → `/trocar-senha`; admin em `/super` → `/dashboard`; admin em `/login` → `/dashboard`; sem sessão em `/register` → `/login`; splash com super usuário → `/super`.
- [ ] **Step 2:** Rodar `cd frontend && flutter test test/app test/models`. Esperado: FAIL.
- [ ] **Step 3:** Implementar e regenerar o mapper: `dart run build_runner build --delete-conflicting-outputs`.
- [ ] **Step 4:** Rodar `flutter analyze && flutter test`. Esperado: sem issues e tudo passando.
- [ ] **Step 5:** Commit: `feat: app reconhece super usuário e troca de senha pendente`

---

### Task 8: App — tela "Defina sua senha", aviso de empresa desativada e remoção do cadastro

**Files:**
- Create: `frontend/lib/pages/auth/change_password_page.dart` (usa o `AuthPageShell`, como o login)
- Create: `frontend/lib/api/account_api.dart`
- Modify: `frontend/lib/core/network/api_client.dart`
- Modify: `frontend/lib/pages/auth/login_page.dart` (remover o botão "Criar conta" e o texto em volta dele)
- Delete: `frontend/lib/pages/auth/register_page.dart`; remover `AuthRepository.register`, `AuthController.register` e a rota `/register`
- Test: `frontend/test/core/api_client_forbidden_test.dart` (ou o lugar equivalente em `test/core`)

**Interfaces:**
- Consumes: Task 6 (`POST /api/account/password`), Task 7 (`markPasswordChanged`, rota `/trocar-senha`)
- Produces:
  - `AccountRepository.changeRequiredPassword(String newPassword): Future<void>` (provider `accountRepositoryProvider`).
  - No `api_client.dart`, `onError`: com status 403 e `message` igual a `'Empresa desativada'` ou `'Troca de senha obrigatoria'`, tratar assim:
    - Empresa desativada: `showAppWarning('Sua empresa foi desativada. Fale com o suporte do CYSVET.')` e `clearSession()`.
    - Troca de senha obrigatória: não limpa a sessão; o roteador já leva para `/trocar-senha` quando `trocarSenha` for true.
    - O `clearSession()` atual só apaga a sessão (`authSessionStorageProvider`), **não** a fila de sync nem o banco local. Manter assim.

Tela "Defina sua senha":
- Título `Defina sua senha`, texto `Por segurança, troque a senha provisória antes de continuar.`
- Campos "Nova senha" e "Confirmar senha" (mínimo 6, iguais).
- Botão `Salvar senha`, que chama o repositório e depois `markPasswordChanged()`. O roteador leva ao destino.
- Link `Sair`, que faz `logout()`.

- [ ] **Step 1: Teste que falha:** extrair a decisão do `onError` para uma função pura `ForbiddenAction classifyForbidden(int? status, Object? data)` (`enum ForbiddenAction { none, companyDeactivated, passwordChangeRequired }`) e testar:
  - 403 com `{'message':'Empresa desativada'}` → `companyDeactivated`;
  - 403 com `{'message':'Troca de senha obrigatoria'}` → `passwordChangeRequired`;
  - 403 com outra mensagem → `none`;
  - 401 → `none`;
  - `data` nulo ou string → `none`.
- [ ] **Step 2:** Rodar e ver falhar.
- [ ] **Step 3:** Implementar a função, a tela e a remoção do cadastro. Conferir com `grep -rn "register" frontend/lib` que não sobrou nenhuma referência.
- [ ] **Step 4:** Rodar `flutter analyze && flutter test`. Esperado: sem issues e tudo passando.
- [ ] **Step 5:** Commit: `feat: tela de troca de senha obrigatória e fim do cadastro no app`

---

### Task 9: App — painel do super usuário (tabela única, opção A)

**Files:**
- Create: `frontend/lib/api/super_admin_api.dart`
- Create: `frontend/lib/models/client_company_model.dart`
- Create: `frontend/lib/providers/super_admin_provider.dart`
- Create: `frontend/lib/pages/super_admin/super_admin_page.dart`, `frontend/lib/pages/super_admin/client_company_dialog.dart`
- Modify: `frontend/lib/app/router.dart` (rota `/super` aponta para `SuperAdminPage`)
- Test: `frontend/test/pages/super_admin_page_test.dart`

**Interfaces:**
- Consumes: Task 5 (contrato `/api/super/companies`), Task 7 (rota)
- Produces:
  - `ClientCompanyModel { int id; String name; String responsibleName; String responsibleEmail; ClientCompanyStatus status; DateTime? createdAt }`, com `enum ClientCompanyStatus { ativa, aguardandoPrimeiroAcesso, desativada }` mapeado de `ATIVA`, `AGUARDANDO_PRIMEIRO_ACESSO` e `DESATIVADA`.
  - `SuperAdminRepository`:
    - `list()`
    - `create({companyName, responsibleName, responsibleEmail}) → ({ClientCompanyModel company, bool emailSent})`
    - `setActive(int id, bool active)`
    - `resendAccess(int id) → bool`
  - `superAdminCompaniesProvider` (AsyncNotifier) com `refresh()`.

Tela (seguindo o esboço A e o `theme.dart`):
- Barra superior escura com `CYSVET · Super usuário` e o botão `Sair`.
- Campo `Buscar empresa ou e-mail`, que filtra no cliente por nome da empresa e e-mail do responsável, sem diferenciar maiúsculas.
- Botão `+ Nova empresa`.
- Tabela com as colunas `Empresa`, `Responsável`, `Situação` e ações. Em telas estreitas (< 600 px), vira uma lista de cards com as mesmas informações e ações.
- Selos: `Ativa` (verde), `Aguardando 1º acesso` (âmbar), `Desativada` (cinza).
- Ações:
  - empresa ativa: `Reenviar senha` e `Desativar`;
  - empresa desativada: `Reenviar senha` e `Reativar`.
- `Desativar` abre um `AlertDialog` do Flutter: título `Desativar {empresa}?`, texto `Os usuários dessa empresa perdem o acesso na hora. Os dados não são apagados.`, botões `Cancelar` e `Desativar`.
- Diálogo "Nova empresa": campos `Nome da empresa`, `Nome do responsável` e `E-mail do responsável` (validação de vazio e de formato de e-mail).
  - Com `emailSent` true: `showAppSuccess('Empresa criada. A senha provisória foi enviada para {email}.')`.
  - Com `emailSent` false: `showAppWarning('Empresa criada, mas o e-mail não foi enviado. Use Reenviar senha.')`.
- Reenviar:
  - deu certo: `showAppSuccess('Nova senha provisória enviada para {email}.')`;
  - falhou: `showAppWarning('Não foi possível enviar o e-mail. Tente novamente.')`.
- Estados: carregando, vazio (`Nenhuma empresa cadastrada.`) e erro com botão `Tentar novamente`.

- [ ] **Step 1: Testes de widget que falham** (`ProviderScope` com um override do `superAdminRepositoryProvider` falso):
  - `showsCompaniesWithStatusBadges`: três empresas → aparecem os textos `Ativa`, `Aguardando 1º acesso` e `Desativada`, e o botão `Reativar` só na desativada.
  - `searchFiltersByCompanyOrEmail`: digitar `boa` deixa só `Clínica Boa Vista`; digitar `AGROVET` deixa só a de e-mail `carlos@agrovet.com`.
  - `deactivateAsksConfirmationBeforeCalling`: tocar em `Desativar` não chama `setActive` antes de confirmar; depois de `Desativar` no diálogo, chama `setActive(id, false)`.
  - `createShowsWarningWhenEmailNotSent`: o fake devolve `emailSent: false` → aparece o texto `Empresa criada, mas o e-mail não foi enviado. Use Reenviar senha.`
- [ ] **Step 2:** Rodar `flutter test test/pages/super_admin_page_test.dart`. Esperado: FAIL.
- [ ] **Step 3:** Implementar.
- [ ] **Step 4:** Rodar `flutter analyze && flutter test`. Esperado: sem issues e tudo passando.
- [ ] **Step 5:** Commit: `feat: painel do super usuário para cadastrar e gerenciar empresas`

---

### Task 10: Deploy e documentação

**Files:**
- Modify: `deploy/oracle/.env.example`, `deploy/oracle/docker-compose.yml` (repassar as variáveis novas ao serviço `backend`)
- Modify: `README.md` (seção curta "Super usuário e e-mail": como definir as variáveis, criar a conta no Brevo, verificar o remetente e usar `smtp-relay.brevo.com:587`)

Bloco que entra no `.env.example`:

```
# Super usuario (criado na primeira subida; a senha nao e alterada depois).
SUPERADMIN_EMAIL=
SUPERADMIN_PASSWORD=
SUPERADMIN_NAME=Super usuario

# E-mail de acesso dos clientes (Brevo: smtp-relay.brevo.com, porta 587).
SPRING_MAIL_HOST=smtp-relay.brevo.com
SPRING_MAIL_PORT=587
SPRING_MAIL_USERNAME=
SPRING_MAIL_PASSWORD=
APP_MAIL_FROM=
```

- [ ] **Step 1:** Atualizar os três arquivos.
- [ ] **Step 2:** Validar o compose: `cd deploy/oracle && docker compose --env-file .env.example config >/dev/null` (se o Docker estiver disponível; se não, informar que não foi validado).
- [ ] **Step 3:** Rodar a suíte completa uma última vez: `cd backend && mvn test` e `cd frontend && flutter analyze && flutter test`.
- [ ] **Step 4:** Commit: `chore: variáveis do super usuário e do e-mail no deploy`

Os passos manuais do Luan não fazem parte da execução: criar a conta no Brevo, preencher o `.env` na VM e subir de novo.
