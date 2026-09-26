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

git clone https://github.com/<usuario>/cysvet_app.git   # repositório privado: use um token de acesso pessoal
cd cysvet_app/deploy/oracle
cp .env.example .env
openssl rand -base64 24   # senhas do MySQL
openssl rand -base64 48   # JWT_SECRET
nano .env                  # DOMAIN, senhas, JWT_SECRET, APP_CORS_ALLOWED_ORIGINS
```

## 6. Subir

```bash
docker compose up -d --build      # o primeiro build na VM ARM leva alguns minutos
docker compose logs -f backend    # espere "Started CysvetApplication"
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

Para distribuir à equipe, use o **Firebase App Distribution** (grátis): crie um projeto no Firebase, adicione
um app Android com o pacote `com.cysvet.app`, envie o APK em *App Distribution* e convide os testadores por
e-mail. Para uso próprio, basta copiar o APK para o celular e instalar.

A primeira pessoa usa **Criar conta** no app (isso cria a empresa); os veterinários são adicionados depois
pela tela de equipe.

## 8. Atualizar

```bash
cd cysvet_app && git pull
cd deploy/oracle && docker compose up -d --build
```

As migrations novas rodam sozinhas na subida do backend.

## 9. Backup

```bash
crontab -e
# 0 3 * * * sh /home/ubuntu/cysvet_app/deploy/oracle/backup.sh >> /home/ubuntu/cysvet-backup.log 2>&1
```

Os dumps ficam em `deploy/oracle/backups/` (14 dias). Copie de tempos em tempos para fora da VM
(`scp ubuntu@IP:cysvet_app/deploy/oracle/backups/*.gz .`). Restaurar:

```bash
gunzip -c backups/ARQUIVO.sql.gz | docker compose exec -T mysql sh -c 'mysql -uroot -p"$MYSQL_ROOT_PASSWORD" cysvet'
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

- O cadastro (`/api/auth/register`) é público: quem tiver o endereço pode criar uma conta com empresa própria
  (os dados ficam isolados, mas a conta existe).
- O `.env` e os backups ficam só na VM (estão no `.gitignore`).
