import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:vitalh2x/models/cliente_model.dart';
import 'package:vitalh2x/models/usuario_model.dart';
import 'package:vitalh2x/services/app_config.dart';

class DatabaseService {
  static Database? _database;
  static final DatabaseService _instance = DatabaseService._internal();

  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    try {
      // Obter diretório para armazenar a base de dados
      Directory documentsDirectory = await getApplicationDocumentsDirectory();
      String path = join(documentsDirectory.path, AppConfig.databaseName);

      print('Database path: $path');

      // Abrir/criar base de dados
      return await openDatabase(
        path,
        version: AppConfig.databaseVersion,
        onCreate: _createTables,
        onUpgrade: _onUpgrade,
        onOpen: _onOpen,
      );
    } catch (e) {
      print('Erro ao inicializar base de dados: $e');
      rethrow;
    }
  }

  // Criar todas as tabelas
  Future<void> _createTables(Database db, int version) async {
    try {
      print('Criando tabelas da base de dados...');

      // Tabela de Usuários
      await db.execute('''
        CREATE TABLE users (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          email TEXT UNIQUE NOT NULL,
          phone TEXT,
          role INTEGER NOT NULL DEFAULT 2,
          password_hash TEXT NOT NULL,
          created_at TEXT NOT NULL,
          updated_at TEXT,
          last_login TEXT,
          is_active INTEGER NOT NULL DEFAULT 1,
          is_synced INTEGER NOT NULL DEFAULT 0
        )
      ''');

      // Tabela de Clientes
      await db.execute('''
        CREATE TABLE clients (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          contact TEXT NOT NULL,
          reference TEXT UNIQUE NOT NULL,
          counter_number TEXT UNIQUE NOT NULL,
          created_at TEXT NOT NULL,
          updated_at TEXT,
          is_active INTEGER NOT NULL DEFAULT 1,
          last_reading REAL DEFAULT 0.0,
          total_debt REAL NOT NULL DEFAULT 0.0
        )
      ''');

      // Tabela de Leituras - VERSÃO ATUALIZADA COM TIMESTAMPS
      await db.execute('''
        CREATE TABLE readings (
          id TEXT PRIMARY KEY,
          client_id TEXT NOT NULL,
          month INTEGER NOT NULL,
          year INTEGER NOT NULL,
          previous_reading REAL NOT NULL DEFAULT 0.0,
          current_reading REAL NOT NULL DEFAULT 0.0,
          consumption REAL NOT NULL DEFAULT 0.0,
          bill_amount REAL NOT NULL DEFAULT 0.0,
          reading_date TEXT NOT NULL,
          payment_status INTEGER NOT NULL DEFAULT 0,
          payment_date TEXT,
          notes TEXT,
          is_synced INTEGER NOT NULL DEFAULT 0,
          created_at TEXT NOT NULL,
          updated_at TEXT,
          FOREIGN KEY (client_id) REFERENCES clients (id) ON DELETE CASCADE,
          UNIQUE(client_id, month, year)
        )
      ''');

      // Tabela de Pagamentos
      await db.execute('''
        CREATE TABLE payments (
          id TEXT PRIMARY KEY,
          client_id TEXT NOT NULL,
          reading_id TEXT NOT NULL,
          amount_paid REAL NOT NULL,
          payment_method INTEGER NOT NULL DEFAULT 0,
          payment_date TEXT NOT NULL,
          receipt_number TEXT UNIQUE NOT NULL,
          transaction_reference TEXT,
          notes TEXT,
          user_id TEXT NOT NULL,
          is_synced INTEGER NOT NULL DEFAULT 0,
          FOREIGN KEY (client_id) REFERENCES clients (id) ON DELETE CASCADE,
          FOREIGN KEY (reading_id) REFERENCES readings (id) ON DELETE CASCADE,
          FOREIGN KEY (user_id) REFERENCES users (id)
        )
      ''');

      // Criar índices para melhor performance
      await _createIndexes(db);

      // Inserir usuário administrador padrão
      await _insertDefaultAdmin(db);

      print('Tabelas criadas com sucesso!');
    } catch (e) {
      print('Erro ao criar tabelas: $e');
      rethrow;
    }
  }

  // Criar índices para otimizar consultas
  Future<void> _createIndexes(Database db) async {
    await db.execute(
      'CREATE INDEX idx_clients_reference ON clients(reference)',
    );
    await db.execute(
      'CREATE INDEX idx_clients_counter ON clients(counter_number)',
    );
    await db.execute('CREATE INDEX idx_clients_active ON clients(is_active)');
    await db.execute(
      'CREATE INDEX idx_clients_created_at ON clients(created_at)',
    );

    await db.execute('CREATE INDEX idx_readings_client ON readings(client_id)');
    await db.execute(
      'CREATE INDEX idx_readings_date ON readings(reading_date)',
    );
    await db.execute(
      'CREATE INDEX idx_readings_status ON readings(payment_status)',
    );
    await db.execute(
      'CREATE INDEX idx_readings_month_year ON readings(month, year)',
    );
    await db.execute(
      'CREATE INDEX idx_readings_created_at ON readings(created_at)',
    );
    await db.execute(
      'CREATE INDEX idx_readings_updated_at ON readings(updated_at)',
    );

    await db.execute('CREATE INDEX idx_payments_client ON payments(client_id)');
    await db.execute(
      'CREATE INDEX idx_payments_reading ON payments(reading_id)',
    );
    await db.execute(
      'CREATE INDEX idx_payments_date ON payments(payment_date)',
    );
    await db.execute(
      'CREATE INDEX idx_payments_created_at ON payments(created_at)',
    );

    await db.execute('CREATE INDEX idx_users_email ON users(email)');
    await db.execute('CREATE INDEX idx_users_active ON users(is_active)');
  }

  // Inserir administrador padrão
  Future<void> _insertDefaultAdmin(Database db) async {
    try {
      final defaultAdmin = UserModel(
        id: 'admin-001',
        name: 'Administrador',
        email: 'admin@waterSystem.local',
        phone: '84000000000',
        role: UserRole.admin,
        passwordHash: _hashPassword('admin123'), // Senha padrão: admin123
        createdAt: DateTime.now(),
        isActive: true,
      );

      await db.insert('users', defaultAdmin.toMap());
      print(
        'Usuário administrador criado: email: admin@waterSystem.local, senha: admin123',
      );
    } catch (e) {
      print('Administrador já existe ou erro ao criar: $e');
    }
  }

  // Hash simples da senha (em produção usar crypto melhor)
  String _hashPassword(String password) {
    // Por simplicidade, usando base64. Em produção usar bcrypt ou similar
    return password; // TODO: Implementar hash real
  }

  // Upgrade da base de dados
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print('Upgrading database from version $oldVersion to $newVersion');

    try {
      if (oldVersion < 2) {
        print('🔄 Executando migração para versão 2...');
        await _migrateToVersion2(db);
      }

      if (oldVersion < 3) {
        print('🔄 Executando migração para versão 3...');
        await _migrateToVersion3(db);
      }

      // Adicione outras migrações conforme necessário
    } catch (e) {
      print('❌ Erro durante upgrade: $e');
      rethrow;
    }
  }

  // Migração para versão 2 - Adicionar timestamps às tabelas
  Future<void> _migrateToVersion2(Database db) async {
    await db.transaction((txn) async {
      // Adicionar timestamps à tabela readings se não existirem
      try {
        final readingsInfo = await txn.rawQuery("PRAGMA table_info(readings)");
        final hasCreatedAt = readingsInfo.any(
          (col) => col['name'] == 'created_at',
        );
        final hasUpdatedAt = readingsInfo.any(
          (col) => col['name'] == 'updated_at',
        );

        if (!hasCreatedAt) {
          await txn.execute('ALTER TABLE readings ADD COLUMN created_at TEXT');
          await txn.execute('''
            UPDATE readings 
            SET created_at = reading_date 
            WHERE created_at IS NULL
          ''');
          print('✅ Coluna created_at adicionada à tabela readings');
        }

        if (!hasUpdatedAt) {
          await txn.execute('ALTER TABLE readings ADD COLUMN updated_at TEXT');
          print('✅ Coluna updated_at adicionada à tabela readings');
        }
      } catch (e) {
        print('ℹ️  Erro ao migrar readings (pode já existir): $e');
      }

      // Adicionar timestamps à tabela payments se não existirem
      try {
        final paymentsInfo = await txn.rawQuery("PRAGMA table_info(payments)");
        final hasCreatedAt = paymentsInfo.any(
          (col) => col['name'] == 'created_at',
        );
        final hasUpdatedAt = paymentsInfo.any(
          (col) => col['name'] == 'updated_at',
        );

        if (!hasCreatedAt) {
          await txn.execute('ALTER TABLE payments ADD COLUMN created_at TEXT');
          await txn.execute('''
            UPDATE payments 
            SET created_at = payment_date 
            WHERE created_at IS NULL
          ''');
          print('✅ Coluna created_at adicionada à tabela payments');
        }

        if (!hasUpdatedAt) {
          await txn.execute('ALTER TABLE payments ADD COLUMN updated_at TEXT');
          print('✅ Coluna updated_at adicionada à tabela payments');
        }
      } catch (e) {
        print('ℹ️  Erro ao migrar payments (pode já existir): $e');
      }

      // Criar índices para os novos campos
      try {
        await txn.execute(
          'CREATE INDEX IF NOT EXISTS idx_readings_created_at ON readings(created_at)',
        );
        await txn.execute(
          'CREATE INDEX IF NOT EXISTS idx_readings_updated_at ON readings(updated_at)',
        );
        await txn.execute(
          'CREATE INDEX IF NOT EXISTS idx_payments_created_at ON payments(created_at)',
        );
        print('✅ Índices de timestamp criados');
      } catch (e) {
        print('ℹ️  Índices já existem: $e');
      }
    });
  }

  // Migração para versão 3 - Exemplo para futuras migrações
  Future<void> _migrateToVersion3(Database db) async {
    // Exemplo: adicionar novas colunas, tabelas, etc.
    // await db.execute('ALTER TABLE clients ADD COLUMN new_field TEXT');
    print('✅ Migração para versão 3 executada (exemplo)');
  }

  // Executado quando a base de dados é aberta
  Future<void> _onOpen(Database db) async {
    print('Base de dados aberta com sucesso!');
    // Ativar foreign keys
    await db.execute('PRAGMA foreign_keys = ON');
  }

  // ===== MÉTODOS DE MIGRAÇÃO MANUAL =====

  // Migração específica para readings (pode ser chamada manualmente)
  Future<void> migrateReadingsTable() async {
    try {
      print('🔄 Iniciando migração da tabela readings...');

      final db = await this.database;

      await db.transaction((txn) async {
        // Verificar se as colunas já existem
        final tableInfo = await txn.rawQuery("PRAGMA table_info(readings)");
        final hasCreatedAt = tableInfo.any(
          (col) => col['name'] == 'created_at',
        );
        final hasUpdatedAt = tableInfo.any(
          (col) => col['name'] == 'updated_at',
        );

        // Adicionar created_at se não existir
        if (!hasCreatedAt) {
          await txn.execute('ALTER TABLE readings ADD COLUMN created_at TEXT');
          print('✅ Coluna created_at adicionada');

          // Preencher dados existentes com reading_date
          await txn.execute('''
            UPDATE readings 
            SET created_at = reading_date 
            WHERE created_at IS NULL OR created_at = ''
          ''');
          print('✅ Dados existentes preenchidos para created_at');
        } else {
          print('ℹ️  Coluna created_at já existe');
        }

        // Adicionar updated_at se não existir
        if (!hasUpdatedAt) {
          await txn.execute('ALTER TABLE readings ADD COLUMN updated_at TEXT');
          print('✅ Coluna updated_at adicionada');
        } else {
          print('ℹ️  Coluna updated_at já existe');
        }

        // Criar índices para performance
        try {
          await txn.execute(
            'CREATE INDEX IF NOT EXISTS idx_readings_created_at ON readings(created_at)',
          );
          await txn.execute(
            'CREATE INDEX IF NOT EXISTS idx_readings_updated_at ON readings(updated_at)',
          );
          print('✅ Índices criados/verificados');
        } catch (e) {
          print('ℹ️  Índices já existem: $e');
        }

        // Verificar resultado
        final count = await txn.rawQuery('''
          SELECT COUNT(*) as total 
          FROM readings 
          WHERE created_at IS NOT NULL
        ''');
        final total = count.first['total'] as int;

        print('✅ Migração concluída: $total leituras com timestamps');
      });
    } catch (e) {
      print('❌ Erro na migração: $e');
      rethrow;
    }
  }

  // Verificar status da migração
  Future<Map<String, dynamic>> getMigrationStatus() async {
    try {
      final db = await this.database;

      // Verificar estrutura da tabela readings
      final readingsInfo = await db.rawQuery("PRAGMA table_info(readings)");
      final hasReadingsCreatedAt = readingsInfo.any(
        (col) => col['name'] == 'created_at',
      );
      final hasReadingsUpdatedAt = readingsInfo.any(
        (col) => col['name'] == 'updated_at',
      );

      // Verificar estrutura da tabela payments
      final paymentsInfo = await db.rawQuery("PRAGMA table_info(payments)");
      final hasPaymentsCreatedAt = paymentsInfo.any(
        (col) => col['name'] == 'created_at',
      );
      final hasPaymentsUpdatedAt = paymentsInfo.any(
        (col) => col['name'] == 'updated_at',
      );

      // Contar registros na tabela readings
      final totalReadingsResult = await db.rawQuery(
        'SELECT COUNT(*) as total FROM readings',
      );
      final totalReadings = totalReadingsResult.first['total'] as int;

      final withTimestampsResult = await db.rawQuery('''
        SELECT COUNT(*) as count 
        FROM readings 
        WHERE created_at IS NOT NULL
      ''');
      final readingsWithTimestamps = withTimestampsResult.first['count'] as int;

      // Contar registros na tabela payments
      final totalPaymentsResult = await db.rawQuery(
        'SELECT COUNT(*) as total FROM payments',
      );
      final totalPayments = totalPaymentsResult.first['total'] as int;

      return {
        'readings': {
          'has_created_at': hasReadingsCreatedAt,
          'has_updated_at': hasReadingsUpdatedAt,
          'total_records': totalReadings,
          'records_with_timestamps': readingsWithTimestamps,
          'migration_complete': hasReadingsCreatedAt && hasReadingsUpdatedAt,
        },
        'payments': {
          'has_created_at': hasPaymentsCreatedAt,
          'has_updated_at': hasPaymentsUpdatedAt,
          'total_records': totalPayments,
          'migration_complete': hasPaymentsCreatedAt && hasPaymentsUpdatedAt,
        },
        'overall_migration_needed':
            !hasReadingsCreatedAt ||
            !hasReadingsUpdatedAt ||
            !hasPaymentsCreatedAt ||
            !hasPaymentsUpdatedAt,
        'overall_migration_complete':
            hasReadingsCreatedAt &&
            hasReadingsUpdatedAt &&
            hasPaymentsCreatedAt &&
            hasPaymentsUpdatedAt,
      };
    } catch (e) {
      print('Erro ao verificar status da migração: $e');
      return {'error': e.toString()};
    }
  }

  // ===== MÉTODOS UTILITÁRIOS =====

  // Executar query personalizada
  Future<List<Map<String, dynamic>>> rawQuery(
    String sql, [
    List<dynamic>? arguments,
  ]) async {
    final db = await database;
    return await db.rawQuery(sql, arguments);
  }

  // Executar comando personalizado
  Future<int> rawExecute(String sql, [List<dynamic>? arguments]) async {
    final db = await database;
    return await db.rawUpdate(sql, arguments);
  }

  // Começar transação
  Future<T> transaction<T>(Future<T> Function(Transaction txn) action) async {
    final db = await database;
    return await db.transaction(action);
  }

  // Verificar se tabela existe
  Future<bool> tableExists(String tableName) async {
    final db = await database;
    final result = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
      [tableName],
    );
    return result.isNotEmpty;
  }

  // Contar registros em uma tabela
  Future<int> countRecords(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $table ${where != null ? 'WHERE $where' : ''}',
      whereArgs,
    );
    return result.first['count'] as int;
  }

  // Limpar dados de uma tabela
  Future<int> clearTable(String table) async {
    final db = await database;
    return await db.delete(table);
  }

  // Resetar base de dados (apagar tudo)
  Future<void> resetDatabase() async {
    try {
      final db = await database;

      // Apagar todas as tabelas
      await db.execute('DROP TABLE IF EXISTS payments');
      await db.execute('DROP TABLE IF EXISTS readings');
      await db.execute('DROP TABLE IF EXISTS clients');
      await db.execute('DROP TABLE IF EXISTS users');

      // Recriar tabelas
      await _createTables(db, AppConfig.databaseVersion);

      print('Base de dados resetada com sucesso!');
    } catch (e) {
      print('Erro ao resetar base de dados: $e');
      rethrow;
    }
  }

  // Backup da base de dados
  Future<String> backupDatabase() async {
    try {
      final db = await database;
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final backupPath = join(
        documentsDirectory.path,
        'backup_${DateTime.now().millisecondsSinceEpoch}.db',
      );

      // Fechar conexão atual
      await db.close();

      // Copiar arquivo
      final originalFile = File(db.path);
      await originalFile.copy(backupPath);

      // Reabrir base de dados
      _database = await _initDatabase();

      print('Backup criado em: $backupPath');
      return backupPath;
    } catch (e) {
      print('Erro ao criar backup: $e');
      rethrow;
    }
  }

  // Estatísticas da base de dados
  Future<Map<String, int>> getDatabaseStats() async {
    try {
      final stats = <String, int>{};

      stats['users'] = await countRecords('users');
      stats['clients'] = await countRecords('clients');
      stats['readings'] = await countRecords('readings');
      stats['payments'] = await countRecords('payments');

      // Clientes ativos
      stats['active_clients'] = await countRecords(
        'clients',
        where: 'is_active = 1',
      );

      // Contas pendentes
      stats['pending_bills'] = await countRecords(
        'readings',
        where: 'payment_status = 0',
      );

      // Contas pagas este mês
      final now = DateTime.now();
      stats['paid_this_month'] = await countRecords(
        'readings',
        where: 'payment_status = 1 AND month = ? AND year = ?',
        whereArgs: [now.month, now.year],
      );

      return stats;
    } catch (e) {
      print('Erro ao obter estatísticas: $e');
      return {};
    }
  }

  // Obter informações detalhadas das tabelas
  Future<Map<String, dynamic>> getTableInfo() async {
    try {
      final db = await database;
      final tables = ['users', 'clients', 'readings', 'payments'];
      final tableInfo = <String, dynamic>{};

      for (final table in tables) {
        final info = await db.rawQuery("PRAGMA table_info($table)");
        final count = await countRecords(table);

        tableInfo[table] = {
          'columns':
              info
                  .map(
                    (col) => {
                      'name': col['name'],
                      'type': col['type'],
                      'not_null': col['notnull'] == 1,
                      'primary_key': col['pk'] == 1,
                    },
                  )
                  .toList(),
          'record_count': count,
        };
      }

      return tableInfo;
    } catch (e) {
      print('Erro ao obter informações das tabelas: $e');
      return {};
    }
  }

  // Verificar integridade da base de dados
  Future<bool> checkDatabaseIntegrity() async {
    try {
      final db = await database;

      // Verificar integridade
      final integrity = await db.rawQuery('PRAGMA integrity_check');
      final isOk = integrity.isNotEmpty && integrity.first.values.first == 'ok';

      if (isOk) {
        print('✅ Integridade da base de dados OK');
      } else {
        print('❌ Problemas de integridade encontrados: $integrity');
      }

      return isOk;
    } catch (e) {
      print('Erro ao verificar integridade: $e');
      return false;
    }
  }

  // Otimizar base de dados
  Future<void> optimizeDatabase() async {
    try {
      final db = await database;

      print('🔄 Otimizando base de dados...');

      // VACUUM para otimizar espaço
      await db.execute('VACUUM');

      // ANALYZE para otimizar consultas
      await db.execute('ANALYZE');

      print('✅ Base de dados otimizada');
    } catch (e) {
      print('Erro ao otimizar base de dados: $e');
      rethrow;
    }
  }

  // Fechar base de dados
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
      print('Base de dados fechada');
    }
  }
}
