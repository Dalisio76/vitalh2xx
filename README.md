# VitalH2X - Sistema de Gestão de Leituras de Água

![Flutter](https://img.shields.io/badge/Flutter-3.7.2+-02569B?style=flat&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.0+-0175C2?style=flat&logo=dart&logoColor=white)
![SQLite](https://img.shields.io/badge/SQLite-3.0+-003B57?style=flat&logo=sqlite&logoColor=white)
![Status](https://img.shields.io/badge/Status-Em_Desenvolvimento-yellow)

## 📋 Sobre o Projeto

**VitalH2X** é um sistema completo para gestão de leituras de água desenvolvido em Flutter. O sistema permite o cadastro de clientes, registro de leituras mensais, controle de pagamentos e geração de relatórios para empresas de distribuição de água.

### 🎯 Finalidade

O projeto foi desenvolvido para automatizar e digitalizar o processo de:
- **Cadastro de clientes** com referências e números de contadores
- **Registro de leituras mensais** de consumo de água
- **Controle de pagamentos** com múltiplos métodos
- **Geração de relatórios** mensais e de inadimplência
- **Gestão de débitos** e histórico de consumo

---

## 🏗️ Arquitetura do Projeto

### Estrutura de Pastas
```
lib/
├── bidings/          # Dependency Injection (GetX)
├── controlers/       # Controladores de negócio
├── models/           # Modelos de dados
├── repository/       # Camada de dados (Repository Pattern)
├── services/         # Serviços (Database, Auth, HTTP)
├── views/            # Interfaces de usuário
├── widgets/          # Componentes reutilizáveis
├── routs/            # Configuração de rotas
└── theme/            # Configurações de tema
```

### Padrões Arquiteturais Utilizados
- **MVVM** (Model-View-ViewModel) com GetX
- **Repository Pattern** para abstração de dados
- **Dependency Injection** com GetX Bindings
- **Observer Pattern** para reatividade de estado

---

## 🔧 Tecnologias e Dependências

### Framework e Linguagem
- **Flutter** 3.7.2+ (Multiplataforma)
- **Dart** 3.0+

### Principais Dependências
```yaml
dependencies:
  # Estado e Navegação
  get: ^4.7.2                    # Gerenciamento de estado e rotas
  
  # Interface
  flutter_screenutil: ^5.9.3    # Responsividade
  flutter_form_builder: ^10.0.1 # Formulários
  
  # Banco de Dados
  sqflite: ^2.4.2               # SQLite para dados locais
  path_provider: ^2.1.1         # Caminhos do sistema
  
  # HTTP e Conectividade
  dio: ^5.3.2                   # Cliente HTTP
  http: ^1.1.0                  # HTTP básico
  connectivity_plus: ^6.1.4    # Status de conectividade
  
  # Utilitários
  intl: ^0.20.2                 # Internacionalização
  uuid: ^4.5.1                  # Geração de IDs únicos
  shared_preferences: ^2.5.3   # Preferências locais
  
  # Relatórios e PDF
  pdf: ^3.11.3                  # Geração de PDF
  printing: ^5.14.2             # Impressão
```

---

## 📊 Banco de Dados

### SQLite - Estrutura das Tabelas

#### 1. Usuários (`users`)
```sql
CREATE TABLE users (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  email TEXT UNIQUE NOT NULL,
  phone TEXT,
  role INTEGER NOT NULL DEFAULT 2,  -- 0: Admin, 1: Cashier, 2: Field
  password_hash TEXT NOT NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT,
  last_login TEXT,
  is_active INTEGER NOT NULL DEFAULT 1,
  is_synced INTEGER NOT NULL DEFAULT 0
)
```

#### 2. Clientes (`clients`)
```sql
CREATE TABLE clients (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  contact TEXT NOT NULL,
  reference TEXT UNIQUE NOT NULL,      -- Referência única do cliente
  counter_number TEXT UNIQUE NOT NULL, -- Número do contador
  created_at TEXT NOT NULL,
  updated_at TEXT,
  is_active INTEGER NOT NULL DEFAULT 1,
  last_reading REAL DEFAULT 0.0,      -- Última leitura registrada
  total_debt REAL NOT NULL DEFAULT 0.0 -- Dívida total acumulada
)
```

#### 3. Leituras (`readings`)
```sql
CREATE TABLE readings (
  id TEXT PRIMARY KEY,
  reading_number INTEGER UNIQUE,      -- Número sequencial da leitura
  client_id TEXT NOT NULL,
  month INTEGER NOT NULL,              -- Mês da leitura
  year INTEGER NOT NULL,               -- Ano da leitura
  previous_reading REAL NOT NULL DEFAULT 0.0,
  current_reading REAL NOT NULL DEFAULT 0.0,
  consumption REAL NOT NULL DEFAULT 0.0,    -- m³ consumidos
  bill_amount REAL NOT NULL DEFAULT 0.0,    -- Valor da conta
  reading_date TEXT NOT NULL,
  payment_status INTEGER NOT NULL DEFAULT 0, -- 0: Pendente, 1: Pago, 2: Atraso, 3: Parcial
  payment_date TEXT,
  notes TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT,
  FOREIGN KEY (client_id) REFERENCES clients (id),
  UNIQUE(client_id, month, year)       -- Apenas uma leitura por cliente/mês
)
```

#### 4. Pagamentos (`payments`)
```sql
CREATE TABLE payments (
  id TEXT PRIMARY KEY,
  payment_number INTEGER UNIQUE,      -- Número sequencial do pagamento
  client_id TEXT NOT NULL,
  reading_id TEXT NOT NULL,
  amount_paid REAL NOT NULL,
  payment_method INTEGER NOT NULL DEFAULT 0, -- 0: Dinheiro, 1: Transferência, etc.
  payment_date TEXT NOT NULL,
  receipt_number TEXT UNIQUE NOT NULL,
  transaction_reference TEXT,
  notes TEXT,
  user_id TEXT NOT NULL,              -- Quem registrou o pagamento
  created_at TEXT NOT NULL,
  updated_at TEXT,
  FOREIGN KEY (client_id) REFERENCES clients (id),
  FOREIGN KEY (reading_id) REFERENCES readings (id),
  FOREIGN KEY (user_id) REFERENCES users (id)
)
```

---

## 🎯 Funcionalidades Implementadas

### ✅ Módulo de Autenticação
- [x] Login com email e senha
- [x] Controle de permissões por tipo de usuário
- [x] Middleware de autenticação em rotas
- [x] Usuário administrador padrão (admin@waterSystem.local / admin123)

### ✅ Gestão de Clientes
- [x] Cadastro completo de clientes
- [x] Validação de referências únicas
- [x] Listagem com busca e filtros
- [x] Visualização de detalhes e histórico
- [x] Desativação de clientes
- [x] Controle de dívidas acumuladas

### ✅ Sistema de Leituras
- [x] Registro de leituras mensais por referência
- [x] Cálculo automático de consumo
- [x] Prevenção de leituras duplicadas (cliente/mês)
- [x] Edição de leituras existentes
- [x] Validação de leituras (não pode ser menor que anterior)
- [x] Histórico completo por cliente

### ✅ Controle de Pagamentos
- [x] Processamento de pagamentos
- [x] Múltiplos métodos de pagamento
- [x] Geração automática de números de recibo
- [x] Controle de pagamentos parciais
- [x] Atualização automática de status das contas
- [x] Histórico de pagamentos

### ✅ Sistema de Relatórios Simplificado
- [x] **Relatório de Pagamentos** - Com checkbox e numeração sequencial
- [x] **Relatório de Leituras** - Com checkbox e numeração sequencial
- [x] **Contas Pendentes** - Com ações em lote (pagar/cancelar)
- [x] **Relatório de Dívidas** - Contas em atraso após dia 5 do mês
- [x] **Contas Pagas** - Histórico com filtros de período
- [x] Dashboard com métricas essenciais
- [x] Relatórios por período

### ✅ Infraestrutura
- [x] Banco SQLite local robusto
- [x] Sistema de migrações automáticas
- [x] Controle de integridade de dados
- [x] Backup e restauração
- [x] Otimização de performance com índices

---

## 🔄 Funcionalidades Pendentes

### ⏳ Integração com API REST (PHP)
- [ ] Sincronização de dados com servidor
- [ ] Upload/download de dados em lote
- [ ] Controle de conflitos de sincronização
- [ ] Modo offline/online

### ⏳ Geração de Relatórios PDF
- [ ] Recibos de pagamento em PDF
- [ ] Relatórios mensais formatados
- [ ] Contas de água individuais
- [ ] Relatórios consolidados

### ⏳ Melhorias na Interface
- [ ] Modo escuro/claro
- [ ] Personalização de tema
- [ ] Melhor experiência mobile
- [ ] Feedback visual aprimorado

### ⏳ Funcionalidades Avançadas
- [ ] Notificações de vencimento
- [ ] Gráficos avançados de consumo
- [ ] Exportação para Excel
- [ ] Sistema de backup automático
- [ ] Configurações por empresa

### ⏳ Segurança e Performance
- [ ] Criptografia de dados sensíveis
- [ ] Logs de auditoria
- [ ] Cache inteligente
- [ ] Compressão de dados

---

## 🚀 Como Executar

### Pré-requisitos
- Flutter SDK 3.7.2 ou superior
- Dart SDK 3.0 ou superior
- Android Studio / VS Code
- Git

### Passos para Execução
1. **Clonar o repositório**
   ```bash
   git clone [URL_DO_REPOSITORIO]
   cd vitalh2x
   ```

2. **Instalar dependências**
   ```bash
   flutter pub get
   ```

3. **Executar o projeto**
   ```bash
   flutter run
   ```

### Login Padrão
- **Email:** admin@waterSystem.local
- **Senha:** admin123

---

## 📱 Capturas de Tela

### Principais Telas do Sistema
- **Login:** Autenticação segura
- **Dashboard:** Visão geral com métricas
- **Clientes:** Gestão completa de clientes
- **Leituras:** Registro mensal de consumo
- **Pagamentos:** Controle financeiro
- **Relatórios:** Análises e estatísticas

---

## 🤝 Contribuição

### Como Contribuir
1. Faça um Fork do projeto
2. Crie uma branch para sua feature (`git checkout -b feature/NovaFuncionalidade`)
3. Commit suas mudanças (`git commit -m 'Adiciona nova funcionalidade'`)
4. Push para a branch (`git push origin feature/NovaFuncionalidade`)
5. Abra um Pull Request

### Padrões de Código
- Utilize nomes descritivos para variáveis e métodos
- Mantenha consistência com o padrão GetX
- Adicione comentários em funcionalidades complexas
- Teste todas as funcionalidades antes do commit

---

## 📄 Licença

Este projeto está sob a licença MIT. Veja o arquivo [LICENSE](LICENSE) para mais detalhes.

---

## 📞 Suporte

Para dúvidas, sugestões ou reportar problemas:
- **Issues:** Use o sistema de Issues do GitHub
- **Email:** [seu-email@dominio.com]
- **Documentação:** Consulte os comentários no código

---

## 📈 Status do Projeto

**Versão Atual:** 1.0.0+1  
**Status:** Em Desenvolvimento Ativo  
**Última Atualização:** Janeiro 2025

### Próximos Marcos
- [ ] Versão 1.1.0 - Integração com API PHP
- [ ] Versão 1.2.0 - Geração de PDF
- [ ] Versão 2.0.0 - Interface redesenhada

---

**Desenvolvido com ❤️ usando Flutter**