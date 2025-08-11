# 🎯 Contexto para Implementação da API PHP - VitalH2X

## 🚀 **Instruções para Nova Conversa**

**Cole este texto no início da nova conversa:**

---

Preciso implementar uma API REST em PHP + MySQL para o sistema VitalH2X (gestão de água). O projeto Flutter já está desenvolvido, mas atualmente usa Supabase e preciso migrar para backend próprio.

**ESTRUTURA DO PROJETO:**
- **App Flutter:** Sistema de gestão de água (clientes, leituras, pagamentos)
- **Backend Atual:** Supabase (será removido)
- **Backend Desejado:** PHP + MySQL com API REST
- **Dados:** 4 tabelas principais (clients, readings, payments, users)

**CRIAR ESTRUTURA COMPLETA:**
1. Banco de dados MySQL (tabelas, índices, relationships)
2. API PHP moderna (PSR-4, namespaces, composer)
3. Sistema de autenticação JWT
4. Endpoints REST completos
5. Validações e segurança
6. Sistema de sincronização
7. Logs de auditoria

**TECNOLOGIAS PREFERENCIAIS:**
- PHP 8.1+
- MySQL 8.0+
- Composer para autoload
- JWT para auth
- Estrutura MVC
- JSON responses
- CORS configurado

Baseie-se nos modelos e especificações do arquivo MIGRACAO_MYSQL_PHP.md que contém TODOS os detalhes técnicos necessários.

---

## 📊 **Dados Técnicos Essenciais**

### **Modelos de Dados (Dart → MySQL)**

```dart
// ClientModel (Flutter)
{
  "id": "uuid",
  "name": "string",
  "contact": "string", 
  "reference": "string unique",
  "counterNumber": "string unique",
  "createdAt": "datetime",
  "updatedAt": "datetime",
  "isActive": "boolean",
  "lastReading": "double?",
  "totalDebt": "double"
}

// ReadingModel (Flutter)
{
  "id": "uuid",
  "clientId": "uuid FK",
  "month": "int 1-12",
  "year": "int",
  "previousReading": "double",
  "currentReading": "double", 
  "consumption": "double",
  "billAmount": "double",
  "readingDate": "datetime",
  "paymentStatus": "enum[pending,paid,overdue,partial]",
  "paymentDate": "datetime?",
  "notes": "string?",
  "isSynced": "boolean"
}

// PaymentModel (Flutter)
{
  "id": "uuid",
  "clientId": "uuid FK",
  "readingId": "uuid FK?",
  "amount": "double",
  "paymentMethod": "enum[cash,bankTransfer,mobileMoney,check,other]",
  "paymentDate": "datetime",
  "reference": "string?",
  "notes": "string?",
  "isSynced": "boolean"
}

// UserModel (Flutter)
{
  "id": "uuid", 
  "email": "string unique",
  "name": "string",
  "role": "enum[admin,cashier,fieldOperator]",
  "createdAt": "datetime",
  "lastLogin": "datetime?",
  "isActive": "boolean"
}
```

### **Configurações do Sistema**
- **Preço por m³:** 50.00 MT (Meticais)
- **Moeda:** MT (Meticais de Moçambique)
- **Charset:** utf8mb4_unicode_ci
- **Timezone:** UTC
- **IDs:** UUID v4

### **Endpoints Necessários (33 endpoints)**

```
POST   /api/auth/login
POST   /api/auth/refresh
POST   /api/auth/logout
GET    /api/auth/me

GET    /api/clients
GET    /api/clients/{id}
POST   /api/clients
PUT    /api/clients/{id}
DELETE /api/clients/{id}
GET    /api/clients/search?q=term
GET    /api/clients/stats
GET    /api/clients/with-debt

GET    /api/readings
GET    /api/readings/{id}
POST   /api/readings
PUT    /api/readings/{id}
DELETE /api/readings/{id}
GET    /api/readings/client/{clientId}
GET    /api/readings/monthly?month=8&year=2025

GET    /api/payments
GET    /api/payments/{id}
POST   /api/payments
PUT    /api/payments/{id}
DELETE /api/payments/{id}
GET    /api/payments/client/{clientId}
GET    /api/payments/stats

GET    /api/users
GET    /api/users/{id}
POST   /api/users
PUT    /api/users/{id}
DELETE /api/users/{id}

POST   /api/sync/bulk
GET    /api/sync/status
```

### **Estrutura de Resposta Padrão**

```json
{
    "success": true,
    "message": "Success message",
    "data": { /* actual data */ },
    "meta": {
        "timestamp": "2025-08-11T10:30:00Z",
        "total": 100,
        "page": 1,
        "per_page": 20
    }
}
```

### **Regras de Negócio Importantes**

1. **Clientes:**
   - Reference deve ser única
   - CounterNumber deve ser único
   - Soft delete (isActive = false)

2. **Leituras:**
   - Uma por cliente por mês/ano
   - CurrentReading >= PreviousReading
   - Consumption = CurrentReading - PreviousReading
   - BillAmount = Consumption × 50.00 MT

3. **Pagamentos:**
   - Podem ser parciais
   - Atualizar status da leitura quando pago
   - Atualizar totalDebt do cliente

4. **Usuários:**
   - 3 roles: admin, cashier, fieldOperator
   - Admin: acesso total
   - Cashier: clientes + pagamentos
   - FieldOperator: apenas leituras

### **Segurança Requerida**
- JWT com expiração
- Password hashing (bcrypt)
- Validação de inputs
- SQL injection protection
- CORS headers
- Rate limiting básico
- Logs de auditoria

### **Banco de Dados - Tabelas MySQL**

```sql
-- 4 tabelas principais + logs + sync
clients (id, name, contact, reference*, counter_number*, created_at, updated_at, is_active, last_reading, total_debt)
readings (id, client_id FK, month, year, previous_reading, current_reading, consumption, bill_amount, reading_date, payment_status, payment_date, notes, is_synced, created_at, updated_at)
payments (id, client_id FK, reading_id FK?, amount, payment_method, payment_date, reference, notes, is_synced, created_at, updated_at) 
users (id, email*, password_hash, name, role, created_at, updated_at, last_login, is_active)
activity_logs (id, user_id FK?, action, table_name, record_id, old_values JSON, new_values JSON, ip_address, user_agent, created_at)
sync_log (id, table_name, record_id, action, sync_status, created_at, synced_at, error_message)

* = campos únicos
```

### **Estrutura PHP Sugerida**

```
api/
├── composer.json
├── index.php
├── config/
│   ├── database.php
│   ├── cors.php  
│   └── jwt.php
├── src/
│   ├── Models/
│   │   ├── Client.php
│   │   ├── Reading.php
│   │   ├── Payment.php
│   │   └── User.php
│   ├── Controllers/
│   │   ├── AuthController.php
│   │   ├── ClientController.php
│   │   ├── ReadingController.php
│   │   ├── PaymentController.php
│   │   └── UserController.php
│   ├── Middleware/
│   │   ├── AuthMiddleware.php
│   │   └── CorsMiddleware.php
│   ├── Utils/
│   │   ├── Database.php
│   │   ├── Response.php
│   │   ├── Validation.php
│   │   └── JWT.php
│   └── Routes/
│       └── api.php
└── .htaccess
```

## 🎯 **Objetivos da Implementação**

### **Funcionalidades Obrigatórias:**
1. ✅ Sistema de autenticação completo (login, logout, refresh)
2. ✅ CRUD completo para todas as entidades
3. ✅ Validações de dados robustas
4. ✅ Sistema de sincronização
5. ✅ Logs de auditoria
6. ✅ Tratamento de erros padronizado
7. ✅ Segurança (SQL injection, XSS, etc.)

### **Funcionalidades Desejáveis:**
8. 📊 Endpoints de estatísticas/relatórios
9. 🔍 Busca avançada com filtros
10. 📄 Paginação de resultados
11. 💾 Cache básico (se possível)
12. 📝 Documentação da API (Swagger/OpenAPI)

### **Performance:**
- Consultas otimizadas com índices
- Conexão com pooling
- Responses em JSON compacto
- Middleware de cache headers

### **Compatibilidade Flutter:**
- Headers CORS corretos
- JSON format compatível com modelos Dart
- UUIDs como strings
- Timestamps em ISO 8601
- Booleans como true/false
- Decimais como numbers

## 🚨 **Pontos de Atenção**

1. **UUID**: Gerar no servidor, não confiar no client
2. **Timestamps**: Sempre UTC, converter no client
3. **Decimais**: Precisão para valores monetários (10,2)
4. **Enums**: Validar valores permitidos
5. **Foreign Keys**: Cascade deletes onde apropriado
6. **Índices**: Criar para campos de busca frequente
7. **Validação**: Tanto no PHP quanto no BD
8. **Logs**: Não logar senhas ou dados sensíveis

## 📋 **Deliverables Esperados**

1. **Scripts SQL** completos para criação das tabelas
2. **Código PHP** estruturado e comentado
3. **Arquivo .htaccess** para URLs amigáveis
4. **Composer.json** com dependências
5. **README** com instruções de instalação
6. **Collection Postman** para testes (opcional)
7. **Exemplos de uso** dos endpoints principais

---

**Com este contexto, você tem todas as informações necessárias para implementar uma API PHP completa para o VitalH2X. Foque na estrutura robusta, segurança e compatibilidade com o app Flutter existente.**