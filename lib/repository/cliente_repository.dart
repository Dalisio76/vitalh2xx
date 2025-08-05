import 'package:vitalh2x/models/cliente_model.dart';
import 'package:vitalh2x/services/database_providers.dart';

import 'base_repository.dart';

class ClientRepository extends BaseRepository<ClientModel> {
  ClientRepository(DatabaseProvider databaseProvider)
    : super(databaseProvider, 'clients');

  @override
  ClientModel fromMap(Map<String, dynamic> map) {
    return ClientModel.fromMap(map);
  }

  @override
  Map<String, dynamic> toMap(ClientModel model) {
    return model.toMap();
  }

  // Buscar cliente por referência
  Future<ClientModel?> findByReference(String reference) async {
    final results = await databaseProvider.query(
      tableName,
      where: 'reference = ?',
      whereArgs: [reference],
      limit: 1,
    );

    if (results.isEmpty) return null;
    return fromMap(results.first);
  }

  // Buscar cliente por número do contador
  Future<ClientModel?> findByCounterNumber(String counterNumber) async {
    final results = await databaseProvider.query(
      tableName,
      where: 'counter_number = ?',
      whereArgs: [counterNumber],
      limit: 1,
    );

    if (results.isEmpty) return null;
    return fromMap(results.first);
  }

  // Buscar clientes ativos
  Future<List<ClientModel>> findActiveClients({
    String? searchTerm,
    int? limit,
    int? offset,
  }) async {
    String where = 'is_active = 1';
    List<dynamic> whereArgs = [];

    if (searchTerm != null && searchTerm.isNotEmpty) {
      where +=
          ' AND (name LIKE ? OR reference LIKE ? OR counter_number LIKE ?)';
      final searchPattern = '%$searchTerm%';
      whereArgs.addAll([searchPattern, searchPattern, searchPattern]);
    }

    final results = await databaseProvider.query(
      tableName,
      where: where,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'name ASC',
      limit: limit,
      offset: offset,
    );

    return results.map((map) => fromMap(map)).toList();
  }

  // Verificar se referência já existe
  Future<bool> referenceExists(String reference, {String? excludeId}) async {
    String where = 'reference = ?';
    List<dynamic> whereArgs = [reference];

    if (excludeId != null) {
      where += ' AND id != ?';
      whereArgs.add(excludeId);
    }

    final count = await this.count(where: where, whereArgs: whereArgs);
    return count > 0;
  }

  // Verificar se número do contador já existe
  Future<bool> counterNumberExists(
    String counterNumber, {
    String? excludeId,
  }) async {
    String where = 'counter_number = ?';
    List<dynamic> whereArgs = [counterNumber];

    if (excludeId != null) {
      where += ' AND id != ?';
      whereArgs.add(excludeId);
    }

    final count = await this.count(where: where, whereArgs: whereArgs);
    return count > 0;
  }

  // Atualizar última leitura do cliente
  Future<bool> updateLastReading(String clientId, double lastReading) async {
    final count = await databaseProvider.update(
      tableName,
      {
        'last_reading': lastReading,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [clientId],
    );

    return count > 0;
  }

  // Atualizar dívida total do cliente
  Future<bool> updateTotalDebt(String clientId, double totalDebt) async {
    final count = await databaseProvider.update(
      tableName,
      {'total_debt': totalDebt, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [clientId],
    );

    return count > 0;
  }

  // Buscar clientes com dívidas
  Future<List<ClientModel>> findClientsWithDebt() async {
    final results = await databaseProvider.query(
      tableName,
      where: 'total_debt > 0 AND is_active = 1',
      orderBy: 'total_debt DESC',
    );

    return results.map((map) => fromMap(map)).toList();
  }

  // Desativar cliente
  Future<bool> deactivateClient(String clientId) async {
    final count = await databaseProvider.update(
      tableName,
      {'is_active': 0, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [clientId],
    );

    return count > 0;
  }

  // Estatísticas de clientes
  Future<Map<String, int>> getClientStats() async {
    final stats = <String, int>{};

    stats['total'] = await count();
    stats['active'] = await count(where: 'is_active = 1');
    stats['inactive'] = await count(where: 'is_active = 0');
    stats['with_debt'] = await count(where: 'total_debt > 0 AND is_active = 1');

    return stats;
  }
}
