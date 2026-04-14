# Projeto BovespaTrade - Plataforma de Compra e Venda de Ações

## 📋 Visão Geral

Aplicação web para diagnóstico de sistema de trading de ações na Bovespa (Brasil), utilizando arquitetura de 3 containers:
- **Backend**: JavaScript (Node.js)
- **Frontend**: TypeScript
- **Database**: PostgreSQL

---

## 🎯 Fase 1: Estrutura Básica (CRUD + Autenticação)

### Objetivos
- Validar a estrutura básica de conexão entre containers
- Implementar CRUD para ações (securities)
- Sistema de autenticação (login/logout)
- Frontpage inicial

### Etapas de Implementação

#### Etapa 1.1: Preparação do Ambiente
- [ ] Criar estrutura de diretórios (backend/, frontend/, database/)
- [ ] Configurar Docker Compose com 3 containers
- [ ] Definir porta de comunicação entre containers
- [ ] Configurar variáveis de ambiente

#### Etapa 1.2: Backend - Setup Básico
- [ ] Inicializar projeto Node.js
- [ ] Instalar dependências básicas (express, pg, bcryptjs, jsonwebtoken, cors)
- [ ] Criar arquivo de conexão com PostgreSQL
- [ ] Implementar rotas de autenticação (/api/auth/login, /api/auth/logout)
- [ ] Criar estrutura de controllers, routes, middleware

#### Etapa 1.3: Frontend - Setup Básico
- [ ] Inicializar projeto TypeScript (Vite recommended)
- [ ] Configurar build tools
- [ ] Criar layout básico com autenticação
- [ ] Implementar página de login
- [ ] Criar frontpage (home)

#### Etapa 1.4: Database - Setup
- [ ] Criar schema PostgreSQL inicial
- [ ] Tabela: users (id, username, password_hash, created_at)
- [ ] Tabela: actions (id, symbol, name, price, quantity, created_at, updated_at)
- [ ] Criar migrations folder

#### Etapa 1.5: Integração e Testes
- [ ] Testar conexão backend-database
- [ ] Implementar CRUD básico para actions (CR)
- [ ] Testar sistema de autenticação
- [ ] Validar comunicação frontend-backend

---

## 🔧 Stack Tecnológico

### Backend (JavaScript)
```
- Express.js (framework web)
- PostgreSQL (driver pg)
- bcryptjs (hashing de senhas)
- jsonwebtoken (tokens JWT)
- cors (cross-origin)
```

### Frontend (TypeScript)
```
- Vite (build tool)
- React (framework)
- TypeScript (linguagem)
- Tailwind CSS (estilização)
- Axios (HTTP client)
```

### Database
```
- PostgreSQL 15+
- Docker container
- Migrations com Knex.js
```

---

## 📁 Estrutura de Arquivos

```
PROJETO-BOVESPA/
├── docker-compose.yml
├── backend/
│   ├── src/
│   │   ├── controllers/
│   │   ├── routes/
│   │   ├── middleware/
│   │   ├── config/
│   │   └── index.js
│   ├── package.json
│   └── .env
├── frontend/
│   ├── src/
│   │   ├── components/
│   │   ├── pages/
│   │   │   ├── Login.tsx
│   │   │   └── Home.tsx
│   │   └── App.tsx
│   ├── package.json
│   └── tsconfig.json
└── README.md
```

---

## 🚀 Roadmap de Implementação

### Sprint 1 (Atual) - Fase 1: Estrutura Básica
- **Dia 1**: Ambiente Docker + Database schema
- **Dia 2**: Backend setup + autenticação
- **Dia 3**: Frontend setup + páginas
- **Dia 4**: Integração e testes

### Sprint 2 - Fase 2: CRUD Completo
- Lista de ações
- Criar nova ação
- Editar ação
- Deletar ação

### Sprint 3 - Fase 3: Interface de Trading
- Dashboard de ações
- Interface de compra/venda
- Histórico de operações

### Sprint 4 - Fase 4: Dados Reais da Bovespa
- Integração com API de dados de mercado
- Display de preços em tempo real
- Gráficos de performance

---

## ✅ Critérios de Aceite (Fase 1)

- [ ] Containers rodando sem erros
- [ ] Login/logout funcionando
- [ ] CRUD de ações implementado
- [ ] Frontpage acessível
- [ ] Comunicação containers validada
- [ ] Código testado e documentado

---

## 📝 Notas de Implementação

### Segurança
- Senhas hashadas com bcrypt
- Tokens JWT com expiração
- CORS configurado para produção
- Validação de input

### Performance
- Conexões com pool de PostgreSQL
- Cache de tokens
- Lazy loading no frontend

---

## 🔄 Workflow de Desenvolvimento

1. **Desenvolvimento**: Trabalhar em branches separadas
2. **Revisão**: Pull requests com revisão
3. **Testes**: Testes unitários e de integração
4. **Deploy**: Docker containers imutáveis

---

## 📞 Contato e Suporte

- **Arthur**: Lead do projeto
- **Laura**: Assistente IA

---

*Documento criado em: 2026-04-14*
*Status: Fase 1 - Em andamento*