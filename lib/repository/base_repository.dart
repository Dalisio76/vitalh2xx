import 'package:vitalh2x/services/database_helpers.dart';
import 'package:vitalh2x/services/database_providers.dart';

abstract class BaseRepository<T> {
  final DatabaseProvider databaseProvider;
  final String tableName;

  BaseRepository(this.databaseProvider, this.tableName);

  // Métodos abstratos que cada repository deve implementar
  T fromMap(Map<String, dynamic> map);
  Map<String, dynamic> toMap(T model);

  // Operações básicas CRUD
  Future<String> create(T model) async {
    final id = DatabaseHelper.generateId();
    final data = toMap(model);
    data['id'] = id;
    data['created_at'] = DateTime.now().toIso8601String();

    await databaseProvider.insert(tableName, data);
    return id;
  }

  Future<T?> findById(String id) async {
    final results = await databaseProvider.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (results.isEmpty) return null;
    return fromMap(results.first);
  }

  Future<List<T>> findAll({String? orderBy, int? limit, int? offset}) async {
    final results = await databaseProvider.query(
      tableName,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );

    return results.map((map) => fromMap(map)).toList();
  }

  Future<bool> update(String id, T model) async {
    final data = toMap(model);
    data['updated_at'] = DateTime.now().toIso8601String();

    final count = await databaseProvider.update(
      tableName,
      data,
      where: 'id = ?',
      whereArgs: [id],
    );

    return count > 0;
  }

  Future<bool> delete(String id) async {
    final count = await databaseProvider.delete(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );

    return count > 0;
  }

  Future<int> count({String? where, List<dynamic>? whereArgs}) async {
    String query = 'SELECT COUNT(*) as count FROM $tableName';
    if (where != null) {
      query += ' WHERE $where';
    }

    final results = await (databaseProvider as SQLiteDatabaseProvider).rawQuery(
      query,
      whereArgs,
    );
    return results.first['count'] as int;
  }
}
