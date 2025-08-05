// ===== DATABASE PROVIDER =====
// lib/app/data/providers/database_provider.dart

import 'package:vitalh2x/services/database_services.dart';

abstract class DatabaseProvider {
  Future<List<Map<String, dynamic>>> query(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<dynamic>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  });

  Future<int> insert(String table, Map<String, dynamic> values);
  Future<int> update(
    String table,
    Map<String, dynamic> values, {
    String? where,
    List<dynamic>? whereArgs,
  });
  Future<int> delete(String table, {String? where, List<dynamic>? whereArgs});
}

class SQLiteDatabaseProvider implements DatabaseProvider {
  final DatabaseService _databaseService = DatabaseService();

  @override
  Future<List<Map<String, dynamic>>> query(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<dynamic>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    final db = await _databaseService.database;
    return await db.query(
      table,
      distinct: distinct,
      columns: columns,
      where: where,
      whereArgs: whereArgs,
      groupBy: groupBy,
      having: having,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
  }

  @override
  Future<int> insert(String table, Map<String, dynamic> values) async {
    final db = await _databaseService.database;
    return await db.insert(table, values);
  }

  @override
  Future<int> update(
    String table,
    Map<String, dynamic> values, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    final db = await _databaseService.database;
    return await db.update(table, values, where: where, whereArgs: whereArgs);
  }

  @override
  Future<int> delete(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    final db = await _databaseService.database;
    return await db.delete(table, where: where, whereArgs: whereArgs);
  }

  // Métodos específicos para operações complexas
  Future<List<Map<String, dynamic>>> rawQuery(
    String sql, [
    List<dynamic>? arguments,
  ]) async {
    return await _databaseService.rawQuery(sql, arguments);
  }

  Future<int> rawExecute(String sql, [List<dynamic>? arguments]) async {
    return await _databaseService.rawExecute(sql, arguments);
  }

  Future<T> transaction<T>(Future<T> Function() action) async {
    final db = await _databaseService.database;
    return await db.transaction((txn) async => await action());
  }
}
