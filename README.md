# VitalH2X - Sistema de Gestão de Água

Um sistema completo para gerenciamento de serviços de água, desenvolvido em Flutter para desktop e mobile.

## 📋 Visão Geral

O VitalH2X é um sistema robusto para empresas de fornecimento de água que permite:
- Cadastro e gestão de clientes
- Registro de leituras mensais dos contadores
- Processamento de pagamentos com múltiplas formas
- Geração de relatórios administrativos
- Dashboard com métricas em tempo real

## 🚀 Tecnologias Utilizadas

- **Framework:** Flutter 
- **Gerenciamento de Estado:** GetX
- **Banco de Dados Local:** SQLite (sqflite_ffi)
- **Banco de Dados Remoto:** Supabase
- **Arquitetura:** MVC + Repository Pattern

## 🏗️ Estrutura do Projeto

```
lib/
├── bidings/           # Dependency Injection e Bindings
├── controlers/        # Controllers (lógica de negócio)
├── models/           # Modelos de dados
├── repository/       # Acesso aos dados (local e remoto)
├── routs/            # Gerenciamento de rotas
├── services/         # Serviços (BD, configurações)
├── theme/            # Temas e configurações visuais
├── views/            # Interfaces de usuário
├── widgets/          # Componentes reutilizáveis
└── main.dart         # Ponto de entrada da aplicação
```

## 👥 Tipos de Usuários

### 🔑 Administrador
- Acesso total ao sistema
- Gestão de usuários e configurações
- Visualização de todos os relatórios

### 💰 Caixa/Atendimento  
- Processamento de pagamentos
- Cadastro de novos clientes
- Consulta de débitos

### 📊 Operador de Campo
- Registro de leituras dos contadores
- Consulta de dados dos clientes

## 💡 Principais Funcionalidades

### 📈 Dashboard Administrativo
- Visão geral das métricas do sistema
- Gráficos de análise mensal
- Insights rápidos sobre cobrança
- Estatísticas de clientes ativos/inativos

### 👤 Gestão de Clientes
- **Cadastro completo:** nome, contato, referência, número do contador
- **Status:** ativo/inativo
- **Histórico:** última leitura, dívida total
- **Busca e filtros** avançados

### 📊 Leituras dos Contadores
- Registro mensal das leituras (programado para dia 20)
- Cálculo automático do consumo
- Histórico de leituras por cliente
- Validações de consistência

### 💳 Sistema de Pagamentos
- **Formas aceitas:**
  - 💵 Dinheiro
  - 🏦 Transferência bancária  
  - 📱 Mobile Money (M-Pesa, E-Mola)
  - 📝 Cheque
  - 🔄 Outros

- **Status de pagamento:**
  - ⏳ Pendente
  - ✅ Pago
  - ⚠️ Em atraso
  - 📊 Parcial

### 📋 Relatórios
- **Relatório Mensal:** consumo e faturamento
- **Relatório de Dívidas:** clientes em débito
- **Histórico de Pagamentos:** por cliente ou período
- **Análise de Eficiência:** taxa de cobrança

## ⚙️ Configurações do Sistema

### 💰 Preço por Metro Cúbico
- Valor atual: **50 MT/m³**
- Configurável via código

### 📅 Período de Leitura
- Dia programado: **20 de cada mês**
- Configurável via sistema

### 🏢 Dados da Empresa
- Nome, endereço e telefone configuráveis
- Utilizados em impressões e relatórios

## 🗄️ Base de Dados

### Local (SQLite)
- Funciona offline
- Sincronização automática
- Backup local dos dados

### Remoto (Supabase)
- Sincronização em tempo real
- Backup na nuvem
- Acesso multi-dispositivo

## 🚀 Como Executar

### Pré-requisitos
- Flutter SDK instalado
- Dart configurado
- Dependências do projeto

### Passos
```bash
# 1. Instalar dependências
flutter pub get

# 2. Executar aplicação
flutter run
```

## 📱 Plataformas Suportadas
- ✅ Windows Desktop
- ✅ macOS Desktop  
- ✅ Linux Desktop
- ✅ Android Mobile
- ✅ iOS Mobile

## 🔐 Segurança
- Autenticação via Supabase
- Controle de acesso por roles
- Criptografia de dados sensíveis
- Backup automático

## 📊 Métricas do Dashboard
- **Clientes Totais/Ativos**
- **Receita Mensal** (em MT)
- **Consumo Total** (em m³)
- **Taxa de Cobrança** (%)
- **Distribuição por Forma de Pagamento**

## 🎯 Status Atual
- ✅ Estrutura base implementada
- ✅ Modelos de dados definidos
- ✅ Controllers principais criados
- ✅ Views básicas funcionais
- ✅ Sistema de autenticação
- ✅ Dashboard administrativo

## 🔄 Próximos Passos
- Testes unitários e integração
- Otimizações de performance
- Funcionalidades avançadas de relatórios
- Sistema de notificações
- Impressão de faturas

## 📞 Suporte
Para dúvidas ou suporte técnico, consulte a documentação técnica ou entre em contato com a equipe de desenvolvimento.

---
**VitalH2X** - Gestão inteligente de recursos hídricos 💧
