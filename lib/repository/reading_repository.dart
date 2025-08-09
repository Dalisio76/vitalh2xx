import 'package:vitalh2x/models/leitura_model.dart';
import 'package:vitalh2x/models/metodo_pagamento_model.dart';
import 'package:vitalh2x/services/database_providers.dart';

import 'base_repository.dart';

class ReadingRepository extends BaseRepository<ReadingModel> {
  ReadingRepository(DatabaseProvider databaseProvider)
    : super(databaseProvider, 'readings');

  @override
  ReadingModel fromMap(Map<String, dynamic> map) {
    return ReadingModel.fromMap(map);
  }

  @override
  Map<String, dynamic> toMap(ReadingModel model) {
    return model.toMap();
  }

  // Buscar leitura específica por cliente e mês/ano
  Future<ReadingModel?> findByClientAndMonth(
    String clientId,
    int month,
    int year,
  ) async {
    final results = await databaseProvider.query(
      tableName,
      where: 'client_id = ? AND month = ? AND year = ?',
      whereArgs: [clientId, month, year],
      limit: 1,
    );

    if (results.isEmpty) return null;
    return fromMap(results.first);
  }

  // Buscar última leitura de um cliente
  Future<ReadingModel?> findLastReadingByClient(String clientId) async {
    final results = await databaseProvider.query(
      tableName,
      where: 'client_id = ?',
      whereArgs: [clientId],
      orderBy: 'year DESC, month DESC',
      limit: 1,
    );

    if (results.isEmpty) return null;
    return fromMap(results.first);
  }

  // Buscar leituras de um cliente
  Future<List<ReadingModel>> findByClient(
    String clientId, {
    int? limit,
    int? offset,
  }) async {
    final results = await databaseProvider.query(
      tableName,
      where: 'client_id = ?',
      whereArgs: [clientId],
      orderBy: 'year DESC, month DESC',
      limit: limit,
      offset: offset,
    );

    return results.map((map) => fromMap(map)).toList();
  }

  // Buscar leituras de um mês específico
  Future<List<ReadingModel>> findByMonth(int month, int year) async {
    final results = await databaseProvider.query(
      tableName,
      where: 'month = ? AND year = ?',
      whereArgs: [month, year],
      orderBy: 'reading_date ASC',
    );

    return results.map((map) => fromMap(map)).toList();
  }

  // Buscar leituras por status de pagamento
  Future<List<ReadingModel>> findByPaymentStatus(PaymentStatus status) async {
    final results = await databaseProvider.query(
      tableName,
      where: 'payment_status = ?',
      whereArgs: [status.index],
      orderBy: 'reading_date DESC',
    );

    return results.map((map) => fromMap(map)).toList();
  }

  // Buscar contas pendentes
  Future<List<ReadingModel>> findPendingBills() async {
    return await findByPaymentStatus(PaymentStatus.pending);
  }

  // Buscar contas em atraso (mais de 30 dias)
  Future<List<ReadingModel>> findOverdueBills() async {
    final cutoffDate = DateTime.now().subtract(const Duration(days: 30));

    final results = await (databaseProvider as SQLiteDatabaseProvider).rawQuery(
      '''
      SELECT r.*, c.name as client_name 
      FROM readings r 
      INNER JOIN clients c ON r.client_id = c.id 
      WHERE r.payment_status = ? AND r.reading_date < ?
      ORDER BY r.reading_date ASC
      ''',
      [PaymentStatus.pending.index, cutoffDate.toIso8601String()],
    );

    return results.map((map) => fromMap(map)).toList();
  }

  // Atualizar status de pagamento
  Future<bool> updatePaymentStatus(
    String readingId,
    PaymentStatus status, {
    DateTime? paymentDate,
  }) async {
    final data = <String, dynamic>{
      'payment_status': status.index,
      //  'updated_at': DateTime.now().toIso8601String(),
    };

    if (paymentDate != null) {
      data['payment_date'] = paymentDate.toIso8601String();
    }

    final count = await databaseProvider.update(
      tableName,
      data,
      where: 'id = ?',
      whereArgs: [readingId],
    );

    return count > 0;
  }

  // Verificar se leitura já existe para o cliente no mês
  Future<bool> readingExistsForMonth(
    String clientId,
    int month,
    int year,
  ) async {
    final count = await this.count(
      where: 'client_id = ? AND month = ? AND year = ?',
      whereArgs: [clientId, month, year],
    );
    return count > 0;
  }

  // Estatísticas de leituras
  Future<Map<String, dynamic>> getReadingStats({int? month, int? year}) async {
    final stats = <String, dynamic>{};

    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (month != null && year != null) {
      whereClause = 'WHERE month = ? AND year = ?';
      whereArgs = [month, year];
    }

    // Total de leituras
    stats['total'] = await count(
      where: month != null && year != null ? 'month = ? AND year = ?' : null,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
    );

    // Por status
    for (PaymentStatus status in PaymentStatus.values) {
      final statusWhere =
          month != null && year != null
              ? 'payment_status = ? AND month = ? AND year = ?'
              : 'payment_status = ?';
      final statusArgs =
          month != null && year != null
              ? [status.index, month, year]
              : [status.index];

      stats[status.name] = await count(
        where: statusWhere,
        whereArgs: statusArgs,
      );
    }

    // Consumo total
    final consumptionQuery =
        month != null && year != null
            ? 'SELECT SUM(consumption) as total FROM readings WHERE month = ? AND year = ?'
            : 'SELECT SUM(consumption) as total FROM readings';

    final consumptionResult = await (databaseProvider as SQLiteDatabaseProvider)
        .rawQuery(consumptionQuery, whereArgs.isEmpty ? null : whereArgs);

    stats['total_consumption'] = consumptionResult.first['total'] ?? 0.0;

    // Valor total faturado
    final revenueQuery =
        month != null && year != null
            ? 'SELECT SUM(bill_amount) as total FROM readings WHERE month = ? AND year = ?'
            : 'SELECT SUM(bill_amount) as total FROM readings';

    final revenueResult = await (databaseProvider as SQLiteDatabaseProvider)
        .rawQuery(revenueQuery, whereArgs.isEmpty ? null : whereArgs);

    stats['total_revenue'] = revenueResult.first['total'] ?? 0.0;

    return stats;
  }

  // Buscar leituras com informações do cliente
  Future<List<Map<String, dynamic>>> findReadingsWithClientInfo({
    int? month,
    int? year,
    PaymentStatus? status,
  }) async {
    String where = '';
    List<dynamic> whereArgs = [];

    if (month != null && year != null) {
      where = 'r.month = ? AND r.year = ?';
      whereArgs = [month, year];
    }

    if (status != null) {
      if (where.isNotEmpty) where += ' AND ';
      where += 'r.payment_status = ?';
      whereArgs.add(status.index);
    }

    final query = '''
      SELECT 
        r.*,
        c.name as client_name,
        c.reference as client_reference,
        c.counter_number as client_counter_number,
        c.contact as client_contact
      FROM readings r
      INNER JOIN clients c ON r.client_id = c.id
      ${where.isNotEmpty ? 'WHERE $where' : ''}
      ORDER BY r.reading_date DESC
    ''';

    return await (databaseProvider as SQLiteDatabaseProvider).rawQuery(
      query,
      whereArgs.isEmpty ? null : whereArgs,
    );
  }
}
