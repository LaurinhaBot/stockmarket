# 📊 BovespaTrade - Plataforma de Compra e Venda de Ações

Aplicação web para diagnóstico de sistema de trading de ações na Bovespa (Brasil).

---

## 🚀 Iniciando o Projeto

### Requisitos

- Docker e Docker Compose
- Node.js 18+ (opcional, para desenvolvimento local)
- PostgreSQL 15+

### Instalação

```bash
# Clonar e entrar no diretório do projeto
cd PROJETO-BOVESPA

# Criar arquivo .env (opcional, já vem com valores padrão)
# Para personalizar, edite o arquivo backend/.env

# Rodar containers
docker-compose up -d

# Verificar status
docker-compose ps

# Acessar aplicação
# Frontend: http://localhost:3000
# Backend API: http://localhost:3001
```

### Containers

O projeto utiliza 3 containers:

1. **database** - PostgreSQL 15
2. **backend** - Node.js com Express
3. **frontend** - TypeScript com Vite

---

## 📁 Estrutura do Projeto

```
PROJETO-BOVESPA/
├── docker-compose.yml          # Configuração dos containers
├── README.md                   # Este arquivo
├── backend/                    # Servidor backend (JavaScript)
│   ├── Dockerfile             # Imagem do backend
│   ├── package.json           # Dependências do backend
│   ├── tsconfig.json          # Config TypeScript
│   ├── .env                   # Variáveis de ambiente
│   └── src/
│       ├── index.js           # Entry point do backend
│       └── routes/
│           ├── auth.js        # Rotas de autenticação
│           └── actions.js     # Rotas CRUD de ações
└── frontend/                   # Interface frontend (TypeScript)
    ├── Dockerfile             # Imagem do frontend
    ├── package.json           # Dependências do frontend
    ├── tsconfig.json          # Config TypeScript
    └── src/
        ├── components/        # Componentes React
        └── pages/             # Páginas (Login, Home, etc)
```

---

## 🔐 Acesso Inicial

Após iniciar os containers pela primeira vez, você terá um usuário administrador:

- **Username**: `admin`
- **Password**: `admin123`

> ⚠️ **Importante**: Altere a senha após o primeiro login!

---

## 📡 API Endpoints

### Autenticação

- `POST /api/auth/login` - Login de usuário
- `POST /api/auth/logout` - Logout
- `GET /api/auth/me` - Informações do usuário atual

### Ações (CRUD)

- `GET /api/actions` - Listar todas as ações
- `GET /api/actions/:id` - Buscar ação por ID
- `POST /api/actions` - Criar nova ação
- `PUT /api/actions/:id` - Atualizar ação
- `DELETE /api/actions/:id` - Deletar ação
- `POST /api/actions/example` - Adicionar ações de exemplo

---

## 🎯 Próximos Passos

A aplicação está configurada com a estrutura básica (Fase 1).

### Fase 1: Estrutura Básica ✅ (Em andamento)
- [x] Docker Compose com 3 containers
- [x] Backend configurado
- [x] Database PostgreSQL
- [x] Autenticação (login/logout)
- [x] CRUD de ações
- [x] Frontend setup

### Fase 2: CRUD Completo (Próximo)
- Lista de ações
- Criar nova ação
- Editar ação
- Deletar ação

### Fase 3: Interface de Trading
- Dashboard de ações
- Interface de compra/venda
- Histórico de operações

### Fase 4: Dados Reais da Bovespa
- Integração com API de dados de mercado
- Display de preços em tempo real
- Gráficos de performance

---

## 🔧 Desenvolvimento

### Backend (Local)

```bash
cd backend
npm install
npm run dev
```

### Frontend (Local)

```bash
cd frontend
npm install
npm run dev
```

---

## 🛠️ Comandos Úteis

```bash
# Parar containers
docker-compose down

# Verificar logs
docker-compose logs -f

# Resetar banco de dados
docker-compose down -v
docker-compose up -d

# Executar migrations (se necessário)
docker-compose exec backend npm run migrate

# Executar testes
docker-compose exec backend npm test
```

---

## 📝 Notas de Implementação

### Segurança
- Senhas hashadas com bcrypt
- Tokens JWT com expiração
- CORS configurado
- Helmet para segurança HTTP

### Performance
- Pool de conexões PostgreSQL
- Cache de tokens
- Lazy loading no frontend

---

## 🤝 Contribuição

Este é um projeto de demonstração para diagnóstico de sistema de trading.

---

## 📞 Contato

- **Arthur**: Lead do projeto
- **Laura**: Assistente IA

---

*Projeto iniciado em: 2026-04-14*
*Status: Fase 1 - Estrutura Básica*
*Versão: 1.0.0-alpha*