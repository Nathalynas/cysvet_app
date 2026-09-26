# CYSVET

Sistema de gestão reprodutiva de rebanhos leiteiros, desenvolvido como Trabalho de Conclusão de Curso (UNOESC).
Apoia médicos veterinários e produtores no acompanhamento de propriedades, lotes, animais, visitas técnicas,
eventos reprodutivos, indicadores e relatórios, inclusive **sem internet** no campo (offline-first, com
sincronização posterior).

## Estrutura

```text
backend/    API REST — Java 17, Spring Boot 3.5, Spring Security (JWT), JPA/Hibernate, Flyway, MySQL 8
frontend/   App Flutter (web e mobile) — Riverpod, GoRouter, Dio, SQLite no mobile para o modo offline
dicionario_de_dados.md          Tabelas e colunas do banco
*.puml                          Diagramas (caso de uso, fluxo da visita, sequência do sync)
```

Pontos centrais da arquitetura:

- **Multiempresa:** cada requisição informa a empresa no header `empresaid`; o backend valida o vínculo do
  usuário e isola os dados por `tenant_id`.
- **Orientado a eventos:** a visita gera eventos reprodutivos, e o resumo de cada animal (lactações, último parto,
  última IA, situação) é recalculado a partir de uma base e dos eventos em ordem cronológica — o resultado não
  depende da ordem em que as visitas offline chegam.
- **Sincronização:** `POST /api/sync` aplica a fila do aparelho item a item (idempotente por `chaveMutacao`,
  conflito "servidor vence") e `GET /api/sync/pull?since=` devolve o que mudou desde o último checkpoint.

## Como rodar

### Backend

Pré-requisitos: Java 17, Maven e um MySQL 8 com o banco `cysvet` (as tabelas são criadas pelo Flyway).

```bash
cd backend
mvn spring-boot:run
```

O perfil padrão é `dev` (porta 8080, MySQL em `localhost:3306`, usuário `root`). Para outro banco, use as
variáveis `SPRING_DATASOURCE_URL`, `SPRING_DATASOURCE_USERNAME` e `SPRING_DATASOURCE_PASSWORD`.
Documentação da API em `http://localhost:8080/swagger-ui.html`.

Produção: perfil `prod`, com `JWT_SECRET`, `APP_CORS_ALLOWED_ORIGINS` e o datasource obrigatórios (a aplicação
não sobe sem eles). O jar é gerado com `mvn package`.

### Frontend

Pré-requisitos: Flutter (canal stable).

```bash
cd frontend
flutter pub get
flutter run -d chrome                                   # web, API em http://localhost:8080
flutter run --dart-define=API_BASE_URL=http://IP:8080   # aparelho físico
```

No emulador Android o endereço padrão da API é `http://10.0.2.2:8080`.

## Testes

```bash
cd backend && mvn test                         # integração com H2 em memória
cd frontend && flutter analyze && flutter test
```

## Banco de dados

O schema é definido **somente** pelas migrations em `backend/src/main/resources/db/migration`
(Hibernate em modo `validate`). Toda mudança de tabela entra como uma nova migration `V<n>__descricao.sql`;
migrations já aplicadas não são editadas. `backend/sql/mysql/cysvet_schema.sql` é uma cópia de referência do
schema final — **apaga as tabelas existentes**, não use sobre um banco com dados.
