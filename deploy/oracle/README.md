# Deploy na Oracle Cloud (Always Free)

Backend, MySQL e Caddy (HTTPS) rodando com Docker numa VM gratuita da Oracle em São Paulo; o app Android
aponta para o domínio dessa VM.

```text
Celular (APK) ──HTTPS──> Caddy :443 ──> backend :8080 ──> MySQL :3306
                          (VM Ampere A1, Ubuntu, Docker Compose)
```

Validado localmente em 26/09/2026: a pilha sobe no perfil `prod`, aplica as 16 migrations, responde via HTTPS
pelo Caddy, importa a planilha real e mantém os dados após `down`/`up`; o backup gera o dump completo.

## 1. Conta

1. Crie a conta em <https://www.oracle.com/cloud/free/>. Na **home region** escolha **Brazil East (Sao Paulo)**:
   os recursos gratuitos só podem ser criados nela e ela não pode ser trocada depois.
2. **Recomendado:** em *Billing › Upgrade and Manage Payment*, converta para **Pay As You Go**. A Oracle
   recupera VMs gratuitas ociosas (CPU, rede e memória abaixo de 20% por 7 dias), o que acontece com um sistema de
   pouco uso; em conta paga isso não ocorre e os recursos Always Free continuam sem custo.
3. Crie um alerta de orçamento (*Billing › Budgets*) de US$ 1 para ser avisado de qualquer cobrança.

## 2. Máquina virtual

*Compute › Instances › Create instance*:

- **Image:** Canonical Ubuntu 24.04 (aarch64).
- **Shape:** Ampere `VM.Standard.A1.Flex` — 2 OCPU e 12 GB (limite gratuito atual).
- **Networking:** criar VCN nova com sub-rede pública e **IPv4 público**.
- **SSH:** gere ou envie sua chave pública e guarde a privada.

Se aparecer *Out of capacity*, tente outro *availability domain*, menos OCPU ou outro horário.

## 3. Portas 80 e 443

São duas camadas de firewall:

1. **Na Oracle:** *Networking › Virtual cloud networks › (sua VCN) › Security Lists › Default* → *Add Ingress
   Rules*: origem `0.0.0.0/0`, TCP, portas `80` e `443`.
2. **Na VM** (as imagens Ubuntu da Oracle bloqueiam no iptables):

```bash
ssh ubuntu@IP_PUBLICO
sudo iptables -I INPUT 6 -m state --state NEW -p tcp --dport 80 -j ACCEPT
sudo iptables -I INPUT 6 -m state --state NEW -p tcp --dport 443 -j ACCEPT
sudo netfilter-persistent save
```

## 4. Domínio

O Android exige HTTPS, e o certificado precisa de um nome. Opção gratuita: <https://www.duckdns.org> — entre,
crie um subdomínio (ex.: `cysvet`) e aponte para o IP público da VM. Um domínio próprio também serve (registro `A`).

## 5. Docker e código

```bash
curl -fsSL https://get.docker.com | sudo sh
sudo usermod -aG docker ubuntu
exit    # entre de novo por SSH para o grupo valer

```

A VM não acessa o GitHub (o repositório é privado), então o código vai do PC para ela em um pacote. No PC,
na pasta do repositório e na branch que vai para produção:

```bash
git archive --format=tar.gz -o cysvet_app.tar.gz HEAD
scp cysvet_app.tar.gz ubuntu@IP_PUBLICO:/tmp/
```

Na VM:

```bash
mkdir ~/cysvet_app && tar -xzf /tmp/cysvet_app.tar.gz -C ~/cysvet_app
cd ~/cysvet_app/deploy/oracle
cp .env.example .env
openssl rand -base64 24   # senhas do MySQL
openssl rand -base64 48   # JWT_SECRET
nano .env                  # DOMAIN, senhas, JWT_SECRET, APP_CORS_ALLOWED_ORIGINS, super usuário e e-mail
```

O super usuário e o envio de e-mail estão explicados no README da raiz ("Super usuário e e-mail").

## 6. Subir

```bash
sudo docker compose up -d --build      # o primeiro build na VM ARM leva alguns minutos
sudo docker compose logs -f backend    # espere "Started CysvetApplication"
curl https://SEU_DOMINIO/actuator/readiness   # {"status":"UP",...}
```

O Caddy emite o certificado sozinho na primeira requisição. Se falhar, confira as portas (passo 3) e se o
domínio já resolve para o IP da VM.

## 7. App no celular

```bash
cd frontend
flutter build apk --release --dart-define=API_BASE_URL=https://SEU_DOMINIO
# build/app/outputs/flutter-apk/app-release.apk
```

A primeira instalação é manual (copiar o APK para o celular). Depois disso o próprio app se atualiza: ao abrir,
ele lê `https://SEU_DOMINIO/app/versao.json` e, se houver versão mais nova, oferece baixar e abre o instalador
do Android. Para publicar uma versão, aumente o número depois do `+` em `version:` no `frontend/pubspec.yaml` e
rode no PC (Git Bash):

```bash
deploy/oracle/publicar-apk.sh "o que mudou"                 # atualização opcional
deploy/oracle/publicar-apk.sh --obrigatoria "o que mudou"   # versões antigas não continuam sem atualizar
```

O script gera o APK, envia para `deploy/oracle/app/` na VM (servido pelo Caddy em `/app/`) e guarda uma cópia
em `Desktop/CYSVET-APK`. Use `--obrigatoria` quando a versão nova muda a sincronização ou o banco.

Não há cadastro público no app. O super usuário entra pela tela de login, cai no painel e cadastra cada
cliente (empresa + responsável); o responsável recebe a senha provisória por e-mail e troca no primeiro
acesso. Os veterinários são adicionados depois pelo responsável, na tela de equipe.

## 8. Atualizar

No PC, na branch que vai para produção:

```bash
git archive --format=tar.gz -o cysvet_app.tar.gz HEAD
scp cysvet_app.tar.gz ubuntu@IP_PUBLICO:/tmp/
```

Na VM, extraia numa pasta nova (o `tar` por cima não apaga arquivos removidos do repositório) e leve o
`.env`, os backups e os APKs publicados:

```bash
cd ~/cysvet_app/deploy/oracle && sudo sh backup.sh
cd ~ && rm -rf cysvet_app_antigo cysvet_app_novo
mkdir cysvet_app_novo && tar -xzf /tmp/cysvet_app.tar.gz -C cysvet_app_novo
cp cysvet_app/deploy/oracle/.env cysvet_app_novo/deploy/oracle/
sudo cp -a cysvet_app/deploy/oracle/backups cysvet_app_novo/deploy/oracle/
cp -a cysvet_app/deploy/oracle/app cysvet_app_novo/deploy/oracle/
mv cysvet_app cysvet_app_antigo && mv cysvet_app_novo cysvet_app
cd ~/cysvet_app/deploy/oracle && sudo docker compose up -d --build
sudo docker compose logs -f backend    # espere "Started CysvetApplication"
```

O caminho `~/cysvet_app/deploy/oracle` não muda, então o Docker reaproveita os volumes do banco e do
certificado. As migrations novas rodam sozinhas na subida do backend. Para voltar à versão anterior, troque
as pastas de volta e rode `sudo docker compose up -d --build` de novo (migrations já aplicadas continuam no
banco).

Mudou só o `.env`? Basta `sudo docker compose up -d` na pasta `deploy/oracle`.

## 9. Backup

```bash
crontab -e
# 0 3 * * * sh /home/ubuntu/cysvet_app/deploy/oracle/backup.sh >> /home/ubuntu/cysvet-backup.log 2>&1
```

Os dumps ficam em `deploy/oracle/backups/` (14 dias). Copie de tempos em tempos para fora da VM
(`scp ubuntu@IP:cysvet_app/deploy/oracle/backups/*.gz .`). Restaurar:

```bash
gunzip -c backups/ARQUIVO.sql.gz | sudo docker compose exec -T mysql sh -c 'mysql -uroot -p"$MYSQL_ROOT_PASSWORD" cysvet'
```

## 10. Chave de assinatura do Android

Sem ela, o APK sai assinado com a chave de debug — serve para testes, não para a Play Store.

```bash
keytool -genkey -v -keystore cysvet-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias cysvet
```

Crie `frontend/android/key.properties` (fora do Git):

```properties
storePassword=...
keyPassword=...
keyAlias=cysvet
storeFile=C:/caminho/para/cysvet-release.jks
```

Guarde o `.jks` e as senhas em lugar seguro: sem eles não é possível publicar atualizações do app na Play Store.

## Atenção

- Só o super usuário cria contas; sem `SPRING_MAIL_PASSWORD` válido o painel avisa que o e-mail com a senha
  provisória não foi enviado (use "Reenviar senha" depois de configurar).
- O `.env` e os backups ficam só na VM (estão no `.gitignore`).
