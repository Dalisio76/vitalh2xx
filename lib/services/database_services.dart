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

      // Tabela de Leituras
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

    await db.execute('CREATE INDEX idx_payments_client ON payments(client_id)');
    await db.execute(
      'CREATE INDEX idx_payments_reading ON payments(reading_id)',
    );
    await db.execute(
      'CREATE INDEX idx_payments_date ON payments(payment_date)',
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

    // Aqui você pode adicionar migrações futuras
    if (oldVersion < 2) {
      // Exemplo de migração para versão 2
      // await db.execute('ALTER TABLE clients ADD COLUMN new_field TEXT');
    }
  }

  // Executado quando a base de dados é aberta
  Future<void> _onOpen(Database db) async {
    print('Base de dados aberta com sucesso!');
    // Ativar foreign keys
    await db.execute('PRAGMA foreign_keys = ON');
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
