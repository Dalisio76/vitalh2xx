# 📚 Documentação Técnica - VitalH2X

## 🎯 Objetivo da Aplicação
Sistema completo de gestão de água para empresas de fornecimento, permitindo controle de clientes, leituras mensais, pagamentos e relatórios administrativos.

## 🏗️ Arquitetura do Sistema

### **Padrão Arquitetural: MVC + Repository**
- **Model:** Representa os dados (Cliente, Leitura, Pagamento, Usuário)
- **View:** Interfaces de usuário (telas Flutter)
- **Controller:** Lógica de negócio usando GetX
- **Repository:** Camada de acesso aos dados (SQLite + Supabase)

### **Estrutura de Pastas Detalhada**

```
lib/
├── bidings/              # Injeção de Dependência
│   ├── InitialBinding.dart        # Binding inicial
│   ├── client_binding.dart        # Binding para clientes
│   ├── payment_binding.dart       # Binding para pagamentos
│   ├── reading_binding.dart       # Binding para leituras
│   └── dependency_injection.dart  # Container DI principal
│
├── controlers/           # Controladores (GetX)
│   ├── auth_controller.dart       # Autenticação
│   ├── client_controller.dart     # Gestão de clientes
│   ├── payment_controller.dart    # Processamento de pagamentos
│   ├── reading_controller.dart    # Leituras dos contadores
│   └── report_controller.dart     # Relatórios e estatísticas
│
├── models/               # Modelos de Dados
│   ├── cliente_model.dart         # Cliente/Consumidor
│   ├── leitura_model.dart         # Leitura do contador
│   ├── pagamento_model.dart       # Pagamento
│   ├── usuario_model.dart         # Usuário do sistema
│   └── metodo_pagamento_model.dart # Enum para métodos
│
├── repository/           # Acesso aos Dados
│   ├── base_repository.dart       # Repositório base
│   ├── cliente_repository.dart    # Operações de cliente
│   ├── payment_repository.dart    # Operações de pagamento
│   └── reading_repository.dart    # Operações de leitura
│
├── services/             # Serviços do Sistema
│   ├── database_services.dart     # Gestão do banco de dados
│   ├── database_providers.dart    # Provedores de BD
│   └── app_config.dart           # Configurações globais
│
├── views/                # Interfaces de Usuário
│   ├── dashboard_view.dart        # Dashboard principal
│   ├── cliente_*.dart            # Telas de cliente
│   ├── reading_*.dart            # Telas de leitura
│   ├── payment_*.dart            # Telas de pagamento
│   └── reports_*.dart            # Telas de relatórios
│
└── widgets/              # Componentes Reutilizáveis
    ├── dashboard_card.dart        # Card do dashboard
    ├── client_card.dart          # Card de cliente
    └── simple_bar_chart.dart     # Gráfico de barras
```

## 📊 Modelos de Dados

### **ClientModel**
```dart
class ClientModel {
  final String? id;
  final String name;                // Nome do cliente
  final String contact;             // Contacto
  final String reference;           // Referência única
  final String counterNumber;       // Número do contador
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isActive;              // Status ativo/inativo
  final double? lastReading;        // Última leitura
  final double totalDebt;           // Dívida total
}
```

### **ReadingModel**
```dart
class ReadingModel {
  final String? id;
  final String clientId;            // ID do cliente
  final int month, year;            // Mês/Ano da leitura
  final double previousReading;     // Leitura anterior
  final double currentReading;      // Leitura atual
  final double consumption;         // Consumo calculado (m³)
  final double billAmount;          // Valor da fatura
  final DateTime readingDate;       // Data da leitura
  final PaymentStatus paymentStatus; // Status do pagamento
  final DateTime? paymentDate;      // Data do pagamento
  final String? notes;              // Observações
  final bool isSynced;              // Sincronizado?
}
```

### **PaymentModel** 
```dart
class PaymentModel {
  final String? id;
  final String clientId;            // ID do cliente
  final String? readingId;          // ID da leitura
  final double amount;              // Valor pago
  final PaymentMethod method;       // Método de pagamento
  final DateTime paymentDate;       // Data do pagamento
  final String? reference;          // Referência do pagamento
  final String? notes;              // Observações
  final bool isSynced;              // Sincronizado?
}
```

## 💻 Controllers Principais

### **ClientController**
**Responsabilidades:**
- Gestão completa de clientes
- Validação de formulários
- Busca e filtragem
- Paginação de dados
- Estatísticas de clientes

**Principais Métodos:**
- `loadClients()` - Carregar lista de clientes
- `createClient()` - Criar novo cliente
- `updateClient()` - Atualizar cliente existente
- `filterClients()` - Filtrar por termo de busca
- `deactivateClient()` - Desativar cliente

### **ReadingController**
**Responsabilidades:**
- Registro de leituras mensais
- Cálculo automático de consumo
- Validação de leituras
- Histórico por cliente

**Principais Métodos:**
- `createReading()` - Registrar nova leitura
- `getClientReadings()` - Histórico do cliente
- `getMonthlyStats()` - Estatísticas mensais
- `validateReading()` - Validar consistência

### **PaymentController**
**Responsabilidades:**
- Processamento de pagamentos
- Múltiplas formas de pagamento
- Controle de status
- Relatórios financeiros

**Principais Métodos:**
- `processPayment()` - Processar pagamento
- `getPaymentHistory()` - Histórico de pagamentos
- `updatePaymentStatus()` - Atualizar status
- `getPaymentStats()` - Estatísticas de pagamento

## 🗄️ Sistema de Base de Dados

### **Configuração Dual**
- **Local:** SQLite com sqflite_ffi
- **Remoto:** Supabase para sincronização

### **Tabelas Principais**
```sql
-- Clientes
CREATE TABLE clients (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  contact TEXT NOT NULL,
  reference TEXT UNIQUE NOT NULL,
  counter_number TEXT UNIQUE NOT NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT,
  is_active INTEGER DEFAULT 1,
  last_reading REAL,
  total_debt REAL DEFAULT 0.0
);

-- Leituras
CREATE TABLE readings (
  id TEXT PRIMARY KEY,
  client_id TEXT NOT NULL,
  month INTEGER NOT NULL,
  year INTEGER NOT NULL,
  previous_reading REAL NOT NULL,
  current_reading REAL NOT NULL,
  consumption REAL NOT NULL,
  bill_amount REAL NOT NULL,
  reading_date TEXT NOT NULL,
  payment_status INTEGER DEFAULT 0,
  payment_date TEXT,
  notes TEXT,
  is_synced INTEGER DEFAULT 0,
  FOREIGN KEY (client_id) REFERENCES clients (id)
);

-- Pagamentos
CREATE TABLE payments (
  id TEXT PRIMARY KEY,
  client_id TEXT NOT NULL,
  reading_id TEXT,
  amount REAL NOT NULL,
  payment_method INTEGER NOT NULL,
  payment_date TEXT NOT NULL,
  reference TEXT,
  notes TEXT,
  is_synced INTEGER DEFAULT 0,
  FOREIGN KEY (client_id) REFERENCES clients (id),
  FOREIGN KEY (reading_id) REFERENCES readings (id)
);
```

## 🔄 Fluxo de Dados

### **1. Cadastro de Cliente**
```
1. Usuário preenche formulário
2. ClientController valida dados
3. Verifica referência/contador únicos
4. ClientRepository salva no SQLite
5. Sincroniza com Supabase
6. Atualiza estatísticas
7. Notifica sucesso
```

### **2. Registro de Leitura**
```
1. Seleção do cliente
2. Input da leitura atual
3. Cálculo automático do consumo
4. Cálculo do valor (consumo × preço/m³)
5. Salvar leitura no BD
6. Atualizar última leitura do cliente
7. Sincronização
```

### **3. Processamento de Pagamento**
```
1. Seleção da conta pendente
2. Escolha do método de pagamento
3. Input do valor pago
4. Atualização do status
5. Registro do pagamento
6. Atualização da dívida do cliente
7. Geração de recibo (futuro)
```

## 🎨 Interface de Usuário

### **Dashboard Principal**
- **Métricas Resumidas:** Clientes totais, receita mensal, consumo total
- **Gráficos:** Análise por método de pagamento
- **Insights Rápidos:** Clientes com dívida, contas pendentes
- **Navegação:** Acesso rápido a funcionalidades

### **Gestão de Clientes**
- **Lista:** Cards com informações principais
- **Busca:** Por nome, referência ou contador
- **Filtros:** Ativos, com dívida
- **Formulário:** Cadastro/edição completa

### **Leituras**
- **Formulário:** Leitura atual, cálculo automático
- **Histórico:** Por cliente ou período
- **Validações:** Consistência com leitura anterior

### **Pagamentos**
- **Lista:** Contas pendentes por cliente
- **Formulário:** Processamento com múltiplos métodos
- **Histórico:** Pagamentos realizados

## 🔧 Configurações do Sistema

### **Preço por Metro Cúbico**
```dart
// app_config.dart
static const double pricePerCubicMeter = 50.0; // MT
```

### **Dia de Leitura**
```dart
// app_config.dart  
static const int readingDay = 20; // Dia 20 de cada mês
```

### **Conexão Supabase**
```dart
// app_config.dart
static const String supabaseUrl = 'https://vficleycgxwdhsigcatz.supabase.co';
static const String supabaseAnonKey = '[KEY]';
```

## 🚀 Funcionalidades Avançadas

### **Sincronização**
- Modo offline com SQLite
- Sincronização automática quando online
- Controle de conflitos
- Backup na nuvem

### **Validações**
- Referências e contadores únicos
- Leituras consistentes (atual > anterior)
- Formulários com validação em tempo real
- Tratamento de erros

### **Performance**
- Paginação de listas grandes
- Busca com debounce
- Cache de estatísticas
- Loading states

### **Segurança**
- Autenticação via Supabase
- Controle de acesso por roles
- Validação de dados
- Logs de auditoria (futuro)

## 🧪 Testes (Planejado)
- **Unit Tests:** Controllers e modelos
- **Widget Tests:** Interfaces
- **Integration Tests:** Fluxos completos
- **Database Tests:** Operações CRUD

## 📊 Métricas e Analytics
- **Clientes:** Total, ativos, com dívida
- **Receita:** Mensal, por método de pagamento
- **Consumo:** Total, médio por cliente
- **Eficiência:** Taxa de cobrança, inadimplência

---

Esta documentação técnica fornece uma visão completa da arquitetura e funcionamento do sistema VitalH2X. Para detalhes específicos de implementação, consulte os arquivos de código correspondentes.