# 🔄 Migração VitalH2X: Supabase → MySQL + PHP

## 📋 Contexto da Migração

### **Situação Atual**
O projeto VitalH2X usa:
- **Local:** SQLite (sqflite_ffi)
- **Remoto:** Supabase (Backend-as-a-Service)
- **Sincronização:** Básica entre SQLite ↔ Supabase

### **Situação Desejada** 
- **Local:** SQLite (mantém)
- **Remoto:** MySQL + API REST PHP
- **Sincronização:** SQLite ↔ MySQL via API PHP

### **Vantagens da Migração**
- ✅ Controle total do backend
- ✅ Customização completa da API
- ✅ Menor custo operacional
- ✅ Performance otimizada
- ✅ Integração com sistemas existentes

## 🏗️ Estrutura Atual do Projeto (Flutter)

### **Modelos de Dados**
```dart
// ClientModel - Cliente/Consumidor
class ClientModel {
  final String? id;                 // UUID
  final String name;                // Nome completo
  final String contact;             // Telefone/Email
  final String reference;           // Referência única
  final String counterNumber;       // Número do contador
  final DateTime createdAt;         
  final DateTime? updatedAt;        
  final bool isActive;              // Ativo/Inativo
  final double? lastReading;        // Última leitura
  final double totalDebt;           // Dívida total
}

// ReadingModel - Leitura do Contador  
class ReadingModel {
  final String? id;                 // UUID
  final String clientId;            // FK para cliente
  final int month, year;            // Período da leitura
  final double previousReading;     // Leitura anterior
  final double currentReading;      // Leitura atual
  final double consumption;         // Consumo (m³)
  final double billAmount;          // Valor da conta
  final DateTime readingDate;       // Data da leitura
  final PaymentStatus paymentStatus; // Status pagamento
  final DateTime? paymentDate;      // Data do pagamento
  final String? notes;              // Observações
  final bool isSynced;              // Sincronizado?
}

// PaymentModel - Pagamento
class PaymentModel {
  final String? id;                 // UUID
  final String clientId;            // FK para cliente
  final String? readingId;          // FK para leitura
  final double amount;              // Valor pago
  final PaymentMethod method;       // Método pagamento
  final DateTime paymentDate;       // Data pagamento
  final String? reference;          // Referência
  final String? notes;              // Observações
  final bool isSynced;              // Sincronizado?
}

// UserModel - Usuário do Sistema
class UserModel {
  final String? id;                 // UUID
  final String email;               // Email login
  final String name;                // Nome completo
  final UserRole role;              // admin/cashier/field_operator
  final DateTime createdAt;
  final DateTime? lastLogin;
  final bool isActive;              // Ativo/Inativo
}
```

### **Enums Utilizados**
```dart
enum PaymentStatus {
  pending,    // Pendente
  paid,       // Pago
  overdue,    // Em atraso
  partial     // Parcial
}

enum PaymentMethod {
  cash,           // Dinheiro
  bankTransfer,   // Transferência
  mobileMoney,    // Mobile Money
  check,          // Cheque
  other           // Outros
}

enum UserRole {
  admin,          // Administrador
  cashier,        // Caixa
  fieldOperator   // Operador Campo
}
```

## 🗄️ Estrutura MySQL Necessária

### **Configurações do Sistema**
- **Charset:** utf8mb4_unicode_ci
- **Engine:** InnoDB
- **Timezone:** UTC
- **Conexões:** Pooling recomendado

### **Tabelas Principais**

```sql
-- Tabela de Clientes
CREATE TABLE clients (
    id CHAR(36) PRIMARY KEY,                    -- UUID
    name VARCHAR(255) NOT NULL,                 -- Nome
    contact VARCHAR(100) NOT NULL,              -- Contacto
    reference VARCHAR(50) NOT NULL UNIQUE,      -- Referência única
    counter_number VARCHAR(50) NOT NULL UNIQUE, -- Número contador
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE,             -- Ativo
    last_reading DECIMAL(10,3) DEFAULT NULL,    -- Última leitura
    total_debt DECIMAL(10,2) DEFAULT 0.00,     -- Dívida total
    
    INDEX idx_reference (reference),
    INDEX idx_counter (counter_number),
    INDEX idx_active (is_active),
    INDEX idx_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabela de Leituras
CREATE TABLE readings (
    id CHAR(36) PRIMARY KEY,                    -- UUID
    client_id CHAR(36) NOT NULL,                -- FK Cliente
    month TINYINT(2) NOT NULL,                  -- Mês (1-12)
    year SMALLINT(4) NOT NULL,                  -- Ano
    previous_reading DECIMAL(10,3) NOT NULL,    -- Leitura anterior
    current_reading DECIMAL(10,3) NOT NULL,     -- Leitura atual
    consumption DECIMAL(10,3) NOT NULL,         -- Consumo
    bill_amount DECIMAL(10,2) NOT NULL,         -- Valor conta
    reading_date TIMESTAMP NOT NULL,            -- Data leitura
    payment_status ENUM('pending','paid','overdue','partial') DEFAULT 'pending',
    payment_date TIMESTAMP NULL,                -- Data pagamento
    notes TEXT NULL,                           -- Observações
    is_synced BOOLEAN DEFAULT FALSE,           -- Sincronizado
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE CASCADE,
    UNIQUE KEY unique_client_month_year (client_id, month, year),
    INDEX idx_client (client_id),
    INDEX idx_period (year, month),
    INDEX idx_status (payment_status),
    INDEX idx_date (reading_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabela de Pagamentos
CREATE TABLE payments (
    id CHAR(36) PRIMARY KEY,                    -- UUID
    client_id CHAR(36) NOT NULL,                -- FK Cliente
    reading_id CHAR(36) NULL,                   -- FK Leitura
    amount DECIMAL(10,2) NOT NULL,              -- Valor
    payment_method ENUM('cash','bankTransfer','mobileMoney','check','other') NOT NULL,
    payment_date TIMESTAMP NOT NULL,            -- Data pagamento
    reference VARCHAR(100) NULL,                -- Referência
    notes TEXT NULL,                           -- Observações
    is_synced BOOLEAN DEFAULT FALSE,           -- Sincronizado
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE CASCADE,
    FOREIGN KEY (reading_id) REFERENCES readings(id) ON DELETE SET NULL,
    INDEX idx_client (client_id),
    INDEX idx_reading (reading_id),
    INDEX idx_date (payment_date),
    INDEX idx_method (payment_method)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabela de Usuários
CREATE TABLE users (
    id CHAR(36) PRIMARY KEY,                    -- UUID
    email VARCHAR(255) NOT NULL UNIQUE,         -- Email
    password_hash VARCHAR(255) NOT NULL,        -- Senha hash
    name VARCHAR(255) NOT NULL,                 -- Nome
    role ENUM('admin','cashier','fieldOperator') DEFAULT 'fieldOperator',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    last_login TIMESTAMP NULL,                  -- Último login
    is_active BOOLEAN DEFAULT TRUE,             -- Ativo
    
    INDEX idx_email (email),
    INDEX idx_role (role),
    INDEX idx_active (is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabela de Sincronização (controle)
CREATE TABLE sync_log (
    id INT AUTO_INCREMENT PRIMARY KEY,
    table_name VARCHAR(50) NOT NULL,           -- Nome tabela
    record_id CHAR(36) NOT NULL,               -- ID do registro
    action ENUM('insert','update','delete') NOT NULL,
    sync_status ENUM('pending','success','failed') DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    synced_at TIMESTAMP NULL,
    error_message TEXT NULL,
    
    INDEX idx_status (sync_status),
    INDEX idx_table (table_name),
    INDEX idx_created (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

## 🚀 API REST PHP Requerida

### **Estrutura da API**

```
api/
├── config/
│   ├── database.php          # Configuração BD
│   ├── cors.php              # CORS headers
│   └── auth.php              # JWT config
├── models/
│   ├── Client.php            # Modelo Cliente
│   ├── Reading.php           # Modelo Leitura
│   ├── Payment.php           # Modelo Pagamento
│   └── User.php              # Modelo Usuário
├── controllers/
│   ├── ClientController.php  # CRUD Clientes
│   ├── ReadingController.php # CRUD Leituras
│   ├── PaymentController.php # CRUD Pagamentos
│   └── AuthController.php    # Autenticação
├── routes/
│   └── api.php              # Definição rotas
├── middleware/
│   ├── AuthMiddleware.php    # Verificação JWT
│   └── CorsMiddleware.php    # CORS
├── utils/
│   ├── Response.php          # Padronização respostas
│   ├── Validation.php        # Validações
│   └── Database.php          # Conexão BD
└── index.php                # Ponto entrada
```

### **Endpoints Necessários**

#### **Autenticação**
```
POST   /api/auth/login           # Login usuário
POST   /api/auth/refresh         # Refresh token
POST   /api/auth/logout          # Logout
GET    /api/auth/me              # Dados usuário atual
```

#### **Clientes**
```
GET    /api/clients              # Listar clientes
GET    /api/clients/{id}         # Cliente específico
POST   /api/clients              # Criar cliente
PUT    /api/clients/{id}         # Atualizar cliente
DELETE /api/clients/{id}         # Deletar cliente
GET    /api/clients/search       # Buscar clientes
GET    /api/clients/stats        # Estatísticas
GET    /api/clients/with-debt    # Clientes com dívida
```

#### **Leituras**
```
GET    /api/readings             # Listar leituras
GET    /api/readings/{id}        # Leitura específica
POST   /api/readings             # Criar leitura
PUT    /api/readings/{id}        # Atualizar leitura
DELETE /api/readings/{id}        # Deletar leitura
GET    /api/readings/client/{id} # Por cliente
GET    /api/readings/monthly     # Estatísticas mensais
```

#### **Pagamentos**
```
GET    /api/payments             # Listar pagamentos
GET    /api/payments/{id}        # Pagamento específico
POST   /api/payments             # Processar pagamento
PUT    /api/payments/{id}        # Atualizar pagamento
DELETE /api/payments/{id}        # Deletar pagamento
GET    /api/payments/client/{id} # Por cliente
GET    /api/payments/stats       # Estatísticas
```

#### **Sincronização**
```
POST   /api/sync/bulk            # Sincronização em lote
GET    /api/sync/status          # Status sincronização
POST   /api/sync/client/{id}     # Sincronizar cliente
POST   /api/sync/reading/{id}    # Sincronizar leitura
POST   /api/sync/payment/{id}    # Sincronizar pagamento
```

### **Formato de Resposta Padrão**

```json
// Sucesso
{
    "success": true,
    "message": "Operação realizada com sucesso",
    "data": {
        // dados retornados
    },
    "meta": {
        "timestamp": "2025-08-11T10:30:00Z",
        "total": 100,
        "page": 1,
        "per_page": 20
    }
}

// Erro  
{
    "success": false,
    "message": "Mensagem de erro",
    "error": {
        "code": "VALIDATION_ERROR",
        "details": {
            "name": ["Nome é obrigatório"],
            "email": ["Email inválido"]
        }
    },
    "meta": {
        "timestamp": "2025-08-11T10:30:00Z"
    }
}
```

## 🔧 Configurações Específicas

### **Configuração BD (database.php)**
```php
define('DB_HOST', 'localhost');
define('DB_NAME', 'vitalh2x');
define('DB_USER', 'root');
define('DB_PASS', '');
define('DB_CHARSET', 'utf8mb4');
define('DB_TIMEZONE', '+00:00');
```

### **Preço por Metro Cúbico**
```php
define('PRICE_PER_CUBIC_METER', 50.00); // MT
```

### **Configurações JWT**
```php
define('JWT_SECRET', 'sua-chave-secreta-super-segura');
define('JWT_EXPIRE', 86400); // 24 horas
```

## 📱 Alterações no Flutter

### **Dependências a Remover**
```yaml
# Remover do pubspec.yaml
supabase_flutter: null
```

### **Dependências a Adicionar**
```yaml
# Adicionar ao pubspec.yaml
http: ^1.1.0              # Requisições HTTP
dio: ^5.3.2               # Cliente HTTP avançado
json_annotation: ^4.8.1   # Serialização JSON
shared_preferences: ^2.2.2 # Token storage
```

### **Estrutura de Conexão**
```dart
// config/api_config.dart
class ApiConfig {
  static const String baseUrl = 'https://seu-dominio.com/api';
  static const String loginEndpoint = '/auth/login';
  static const String refreshEndpoint = '/auth/refresh';
  
  // Headers padrão
  static Map<String, String> get defaultHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
}

// services/http_service.dart  
class HttpService {
  static final Dio _dio = Dio();
  
  static Future<Response> get(String endpoint) async { ... }
  static Future<Response> post(String endpoint, dynamic data) async { ... }
  static Future<Response> put(String endpoint, dynamic data) async { ... }
  static Future<Response> delete(String endpoint) async { ... }
}
```

### **Método de Sincronização**
```dart
// services/sync_service.dart
class SyncService {
  // Sincronizar dados locais → servidor
  static Future<bool> syncToServer() async { ... }
  
  // Baixar dados servidor → local
  static Future<bool> syncFromServer() async { ... }
  
  // Sincronização completa
  static Future<bool> fullSync() async { ... }
}
```

## 📊 Sistema de Logs e Auditoria

### **Tabela de Logs**
```sql
CREATE TABLE activity_logs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id CHAR(36) NULL,
    action VARCHAR(100) NOT NULL,
    table_name VARCHAR(50) NOT NULL,
    record_id CHAR(36) NULL,
    old_values JSON NULL,
    new_values JSON NULL,
    ip_address VARCHAR(45) NULL,
    user_agent TEXT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_user (user_id),
    INDEX idx_action (action),
    INDEX idx_date (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

## 🔒 Segurança Implementada

### **Autenticação JWT**
- Tokens com expiração
- Refresh tokens
- Logout seguro

### **Validação de Dados**
- Sanitização de inputs
- Validação de tipos
- Prevenção SQL injection

### **Controle de Acesso**
- Roles por endpoint
- Middleware de autorização
- Rate limiting

### **CORS Configurado**
```php
// Apenas para domínios autorizados
$allowed_origins = [
    'http://localhost',
    'https://seu-app.com'
];
```

## 🚀 Plano de Implementação

### **Fase 1: Preparação**
1. Configurar servidor MySQL
2. Criar estrutura de tabelas
3. Desenvolver API PHP básica
4. Implementar autenticação

### **Fase 2: CRUD Principal**  
5. Endpoints de clientes
6. Endpoints de leituras
7. Endpoints de pagamentos
8. Testes da API

### **Fase 3: Integração Flutter**
9. Remover Supabase do Flutter
10. Implementar HttpService
11. Atualizar repositories
12. Testar sincronização

### **Fase 4: Finalização**
13. Sistema de logs
14. Otimizações de performance
15. Deploy em produção
16. Documentação final

## 📋 Checklist de Migração

### **Backend PHP**
- [ ] Configurar ambiente MySQL
- [ ] Criar tabelas com índices
- [ ] Implementar autenticação JWT
- [ ] Desenvolver CRUD endpoints
- [ ] Sistema de validação
- [ ] Middleware de segurança
- [ ] Logs de auditoria
- [ ] Testes de API

### **Flutter App**
- [ ] Remover dependências Supabase
- [ ] Adicionar cliente HTTP
- [ ] Implementar ApiService
- [ ] Atualizar todos os repositories
- [ ] Sistema de cache local
- [ ] Tratamento de erros HTTP
- [ ] Sincronização offline/online
- [ ] Testes de integração

### **DevOps**
- [ ] Configurar servidor web
- [ ] SSL/HTTPS
- [ ] Backup automático MySQL
- [ ] Monitoramento de logs
- [ ] Rate limiting
- [ ] CDN (se necessário)

---

**Este documento fornece todas as informações necessárias para implementar a migração completa de Supabase para MySQL + PHP. Use este arquivo como referência para uma nova conversa onde será implementada toda a estrutura PHP.**