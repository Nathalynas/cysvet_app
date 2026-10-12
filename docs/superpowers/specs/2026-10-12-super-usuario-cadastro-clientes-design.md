# Super usuário e cadastro de clientes — design

Data: 2026-10-12

## Intenção

Hoje qualquer pessoa que abre o app pode tocar em "Criar conta" na tela de login,
virar ADMIN e ganhar uma empresa própria (`AuthService.register`). Com o backend
publicado na Oracle Cloud, isso deixa o sistema aberto a qualquer um.

O Luan quer controlar quem entra: **só ele**, como super usuário, cadastra
clientes (empresas) novos. O cliente recebe por e-mail uma senha provisória e é
obrigado a trocá-la no primeiro login.

## Objetivos

1. Remover o cadastro público (botão no login, rota `/register` do app e o
   endpoint `POST /api/auth/register`).
2. Criar o perfil `SUPER_ADMIN`, com uma única conta, que é do Luan.
3. Criar o painel do super usuário (layout "tabela única", opção A do esboço), onde ele:
   - lista as empresas, com busca por nome da empresa ou e-mail do responsável;
   - cria uma empresa nova junto com o usuário ADMIN responsável;
   - desativa e reativa uma empresa;
   - reenvia a senha provisória do responsável.
4. Enviar e-mail com a senha provisória.
5. Obrigar a troca de senha no primeiro login (e depois de cada reenvio).

## Fora do escopo

- O super usuário **não** vê dados das clínicas: animais, visitas, propriedades,
  dashboard e relatórios. Ele só administra contas (decisão do Luan).
- Não haverá "entrar como cliente" (impersonation).
- O "Esqueci minha senha" da tela de login continua como está. Ele pode
  reaproveitar o envio de e-mail no futuro, mas não faz parte desta entrega.
- Não haverá cobrança, planos nem limites por empresa.
- Não haverá cadastro de vários super usuários pela interface.
- O fluxo da tela Equipe não muda: o ADMIN continua escolhendo a senha do
  veterinário, sem e-mail e sem troca obrigatória.
- As contas que já existem não são mexidas. Hoje existe só uma em produção; ela
  continua ativa, sem `trocarSenha` e sem receber e-mail.

## Anti-objetivos (seria falha mesmo funcionando)

- Continuar existindo qualquer caminho público que crie conta ou empresa.
- O super usuário conseguir ler ou alterar dados de uma clínica.
- A senha provisória ficar visível em log, resposta da API ou tela do super usuário.
- Usuário de empresa desativada continuar conseguindo usar o app online
  (login ou refresh de token).

## Como foi decidido

### Conta do super usuário (decisão minha, aprovada pelo Luan na conversa)
- Ele entra pela mesma tela de login, com e-mail e senha.
- A conta é criada pelo backend na inicialização, se ainda não existir, a partir
  de variáveis de ambiente (`SUPERADMIN_EMAIL`, `SUPERADMIN_PASSWORD`, opcional
  `SUPERADMIN_NAME`). Elas ficam no `.env` do deploy na Oracle (`deploy/`). Se as
  variáveis não estiverem definidas, nada é criado.
- Se a conta já existir, a inicialização não muda a senha. A senha do super
  usuário não é provisória.
- O super usuário não tem vínculo em `usuario_empresa`. Hoje `buildAuthResponse`
  lança `AccessDeniedException` quando o usuário não tem empresa. Para
  `SUPER_ADMIN`, a resposta sai sem empresa (`empresaAtivaId` nulo e lista vazia).
- No app, depois do login com `perfil == SUPER_ADMIN`, ele vai direto para o
  painel (`/super`) e não consegue acessar as outras rotas.
- No backend, as rotas novas ficam em `/api/super/**` e exigem
  `ROLE_SUPER_ADMIN`. Todas as rotas de dados de clínica negam acesso ao
  `SUPER_ADMIN`; como ele não tem empresa, o `TenantAccessService` já deve
  bloquear, mas isso precisa ser verificado com teste.

### Criar empresa
Formulário (janela por cima da tabela):
- nome da empresa (obrigatório)
- nome do responsável (obrigatório)
- e-mail do responsável (obrigatório e único)

Ao salvar, o sistema:
1. cria a `Empresa` (`ativo = true`, `email` = e-mail do responsável);
2. cria o `Usuario` com perfil ADMIN e uma senha provisória aleatória (com
   gerador seguro, pelo menos 10 caracteres e sem caracteres ambíguos);
3. marca o usuário com `trocarSenha = true`;
4. cria o vínculo `UsuarioEmpresa`;
5. envia o e-mail com a senha provisória.

Se o e-mail já existir, a API devolve 400 ("E-mail já cadastrado") e nada é criado.

Se o envio do e-mail falhar, a empresa e o usuário **continuam criados**, e a
tela avisa: "Empresa criada, mas o e-mail não foi enviado. Use Reenviar senha."
(decisão minha, para não perder o cadastro por causa de um SMTP instável).

### Quem é o responsável *(decisão minha)*
- Coluna nova `empresa.responsavel_usuario_id` (FK para `usuario`), preenchida
  quando o super usuário cria a empresa. A lista, a busca, a situação e o
  "Reenviar senha" usam esse usuário, e não `empresa.email`, que o ADMIN pode
  editar pela tela da empresa.
- Para empresas antigas, a migration preenche essa coluna com o ADMIN mais
  antigo vinculado à empresa, se houver um.

### Situação na lista
Cada linha mostra empresa, e-mail do responsável e uma situação:
- **Aguardando 1º acesso**: o responsável ainda está com `trocarSenha = true`;
- **Ativa**: empresa ativa e senha já trocada;
- **Desativada**: `empresa.ativo = false`.

Ações por linha: "Reenviar senha" e "Desativar" quando a empresa está ativa;
"Reativar" quando está desativada (o "Reativar" foi ideia minha).

### Desativar e reativar
- Desativar muda `empresa.ativo` para false e revoga todos os refresh tokens dos
  usuários daquela empresa.
- Hoje `findActiveMemberships` e `TenantAccessService.userHasAccessToTenant`
  (chamado pelo `JwtAuthenticationFilter` a cada requisição) só olham
  `usuario_empresa.ativo` e ignoram `empresa.ativo`. Os dois passam a
  considerar `empresa.ativo`. Assim o bloqueio vale **na hora**: login, refresh,
  rotas de dados e sync recusam com a mensagem "Empresa desativada". Se o
  usuário tiver outra empresa ativa, ele continua usando essa normalmente.
  *(decisão minha)*
- No app, ao receber "Empresa desativada", ele mostra a mensagem e volta para o
  login, mas **não apaga** os dados locais nem as alterações pendentes de sync.
  Se a empresa for reativada, o que estava pendente sobe normalmente.
  *(decisão minha)*
- Os dados da empresa não são apagados. Reativar volta `ativo = true`.
- Pede confirmação antes de desativar, usando um diálogo do próprio app.

### Reenviar senha
- Gera uma nova senha provisória, grava o hash, marca `trocarSenha = true`,
  revoga os refresh tokens do responsável e envia o e-mail de novo.
- Serve tanto para quem nunca entrou quanto para quem esqueceu a senha.

### Troca obrigatória de senha
- Coluna nova `usuario.trocar_senha` (boolean, padrão false), via migration
  Flyway `V18__super_admin.sql` (a última hoje é a V17; `perfil` é VARCHAR,
  então o perfil novo não exige mudança de restrição).
- `UsuarioAutenticadoResponse` passa a incluir `trocarSenha`.
- No app, se `trocarSenha` for true depois do login, o roteador manda para uma
  tela "Defina sua senha" (nova senha + confirmação, mínimo 6 caracteres, igual
  à regra atual), e as outras rotas ficam bloqueadas até a troca.
- Endpoint novo `POST /api/account/password` (autenticado; fora de
  `/api/auth/**`, que o filtro e o app tratam como rota sem token). Quando o
  usuário está com `trocarSenha = true`, recebe só a nova senha, porque o login
  com a provisória já provou quem ele é e o app pode ter reiniciado nesse meio
  tempo. Depois grava a nova senha e marca `trocarSenha = false`. Neste escopo
  ele serve só para a troca obrigatória; uma tela "Alterar senha" nas
  configurações fica para depois. *(decisão minha)*
- O backend também recusa as rotas de dados com 403 enquanto `trocarSenha` for
  true, para que a regra não dependa só do app.

### E-mail
- Uso `spring-boot-starter-mail` (`JavaMailSender`) com SMTP configurado só
  por variáveis de ambiente (`SPRING_MAIL_HOST`, `SPRING_MAIL_PORT`,
  `SPRING_MAIL_USERNAME`, `SPRING_MAIL_PASSWORD`, `APP_MAIL_FROM`).
- Provedor sugerido: **Brevo**, no plano grátis, por SMTP na porta 587. O Luan
  ainda não tem conta; criar a conta e verificar o remetente é passo manual dele.
  Trocar de provedor depois exige só mudar o `.env`.
- O texto do e-mail é simples, em português: nome da empresa, e-mail de login,
  senha provisória e o aviso de que a senha deverá ser trocada no primeiro acesso.
- Em dev ou teste sem SMTP configurado, o envio é substituído por um log que
  **não** mostra a senha, só "e-mail de acesso enviado para X".

### Remover o cadastro público
- Apagar `register_page.dart`, a rota `/register` no `router.dart`, o botão
  "Criar conta" do `login_page.dart` e `AuthApi.register`.
- Apagar `POST /api/auth/register`, `RegisterRequest` e
  `AuthService.register`/`createDefaultCompanyForUser`. Isso também elimina o
  bug do `password` sem `@NotBlank`.

### Ajustes técnicos já identificados
- O `JwtAuthenticationFilter` pula toda rota `/api/auth/**` e exige o header
  `empresaid` + vínculo com a empresa nas outras. Ele precisa de exceções:
  `/api/account/password` não exige empresa, e `/api/super/**` tem que
  aceitar `SUPER_ADMIN` sem empresa.
- Atualizar o `AGENTS.md`, que ainda diz "a próxima é a V17".

## Fica a cargo de quem for construir

- Nomes exatos de classes, DTOs e providers, seguindo o padrão atual
  (`CompanyService`, `TeamService` etc.).
- Visual do painel, seguindo o tema existente (`frontend/lib/app/theme.dart`) e o
  esboço da opção A.
- Paginação da lista (com poucos clientes, pode ser uma lista simples).
- Testes: seguir o padrão de testes do backend em `backend/src/test`.
