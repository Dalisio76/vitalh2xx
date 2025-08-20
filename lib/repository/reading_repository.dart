import 'package:vitalh2x/models/leitura_model.dart';
import 'package:vitalh2x/models/metodo_pagamento_model.dart';
import 'package:vitalh2x/services/database_providers.dart';

import 'base_repository.dart';

class ReadingRepository extends BaseRepository<ReadingModel> {
  ReadingRepository(DatabaseProvider databaseProvider)
    : super(databaseProvider, 'readings');

  @override
  Future<String> create(ReadingModel model) async {
    try {
      // Gerar reading_number se não foi fornecido
      final readingNumber = model.readingNumber ?? await getNextReadingNumber();
      
      // Criar modelo com reading_number
      final modelWithNumber = model.copyWith(readingNumber: readingNumber);
      
      // Chamar create do pai
      return await super.create(modelWithNumber);
    } catch (e) {
      print('Erro ao criar leitura: $e');
      // Se houver erro, tentar criar sem reading_number
      final modelWithoutNumber = model.copyWith(readingNumber: null);
      return await super.create(modelWithoutNumber);
    }
  }

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
      orderBy: 'created_at DESC, reading_date DESC',
    );

    return results.map((map) => fromMap(map)).toList();
  }

  // Buscar apenas leituras pendentes (não pagas) de um mês específico
  Future<List<ReadingModel>> findPendingByMonth(int month, int year) async {
    final results = await databaseProvider.query(
      tableName,
      where: 'month = ? AND year = ? AND payment_status != ?',
      whereArgs: [month, year, PaymentStatus.paid.index],
      orderBy: 'created_at DESC, reading_date DESC',
    );

    return results.map((map) => fromMap(map)).toList();
  }

  // Buscar leituras que devem virar dívidas (após dia 5 do mês seguinte)
  Future<List<ReadingModel>> findOverdueReadings() async {
    final now = DateTime.now();
    final currentDay = now.day;
    final currentMonth = now.month;
    final currentYear = now.year;
    
    // LÓGICA CORRIGIDA: 
    // Se hoje é após dia 5, leituras do mês passado pendentes viram dívida
    // Mas retorna as leituras que DEVEM ser marcadas como overdue
    
    if (currentDay <= 5) {
      // Ainda estamos dentro do prazo - retornar leituras antigas pendentes
      var overdueMonth = currentMonth - 1;
      var overdueYear = currentYear;
      
      if (overdueMonth == 0) {
        overdueMonth = 12;
        overdueYear -= 1;
      }
      
      // Buscar leituras de meses anteriores que ainda estão pendentes
      final results = await databaseProvider.query(
        tableName,
        where: '(year < ? OR (year = ? AND month < ?)) AND payment_status = ?',
        whereArgs: [overdueYear, overdueYear, overdueMonth, PaymentStatus.pending.index],
        orderBy: 'reading_date ASC',
      );

      return results.map((map) => fromMap(map)).toList();
    }
    
    // Calcular mês anterior
    var overdueMonth = currentMonth - 1;
    var overdueYear = currentYear;
    
    if (overdueMonth == 0) {
      overdueMonth = 12;
      overdueYear -= 1;
    }
    
    // Buscar leituras do mês passado e anteriores que ainda estão pendentes
    final results = await databaseProvider.query(
      tableName,
      where: '(year < ? OR (year = ? AND month <= ?)) AND payment_status = ?',
      whereArgs: [overdueYear, overdueYear, overdueMonth, PaymentStatus.pending.index],
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
      orderBy: 'created_at DESC, reading_date DESC',
    );

    return results.map((map) => fromMap(map)).toList();
  }

  // Buscar contas pendentes
  Future<List<ReadingModel>> findPendingBills() async {
    return await findByPaymentStatus(PaymentStatus.pending);
  }

  // Buscar contas pendentes para um cliente específico
  Future<List<ReadingModel>> findPendingBillsByClientId(String clientId) async {
    final results = await databaseProvider.query(
      tableName,
      where: 'client_id = ? AND payment_status = ?',
      whereArgs: [clientId, PaymentStatus.pending.index],
      orderBy: 'created_at DESC, year DESC, month DESC',
    );

    return results.map((map) => fromMap(map)).toList();
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

  // Atualizar leituras pendentes para overdue automaticamente
  Future<int> updateOverdueReadings() async {
    final overdueReadings = await findOverdueReadings();
    
    if (overdueReadings.isEmpty) {
      return 0;
    }
    
    int updated = 0;
    for (final reading in overdueReadings) {
      final success = await updatePaymentStatus(reading.id!, PaymentStatus.overdue);
      if (success) updated++;
    }
    
    return updated;
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

  // Gerar próximo número de leitura
  Future<int> getNextReadingNumber() async {
    try {
      final results = await databaseProvider.query(
        tableName,
        columns: ['reading_number'],
        where: 'reading_number IS NOT NULL',
        orderBy: 'reading_number DESC',
        limit: 1,
      );

      if (results.isEmpty) {
        return 1; // Primeira leitura
      }

      final lastNumber = results.first['reading_number'] as int?;
      return (lastNumber ?? 0) + 1;
    } catch (e) {
      print('Erro ao obter próximo número de leitura: $e');
      // Fallback: usar timestamp como número
      return DateTime.now().millisecondsSinceEpoch % 1000000;
    }
  }

  // Estatísticas de leituras
  Future<Map<String, dynamic>> getReadingStats({int? month, int? year}) async {
    final stats = <String, dynamic>{};

    List<dynamic> whereArgs = [];

    if (month != null && year != null) {
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

  // Buscar clientes sem leitura em um mês específico
  Future<List<Map<String, dynamic>>> findClientsWithoutReading(
    int month,
    int year,
  ) async {
    final query = '''
      SELECT 
        c.id,
        c.name,
        c.reference,
        c.counter_number,
        c.contact,
        c.address,
        c.last_reading,
        c.created_at
      FROM clients c
      WHERE c.is_active = 1
      AND c.id NOT IN (
        SELECT DISTINCT r.client_id 
        FROM readings r 
        WHERE r.month = ? AND r.year = ?
      )
      ORDER BY c.name ASC
    ''';

    return await (databaseProvider as SQLiteDatabaseProvider).rawQuery(
      query,
      [month, year],
    );
  }

  // Relatório completo de leituras não feitas
  Future<Map<String, dynamic>> getMissingReadingsReport(
    int month,
    int year,
  ) async {
    final clientsWithoutReadings = await findClientsWithoutReading(month, year);
    
    // Contar total de clientes ativos
    final totalActiveClientsQuery = '''
      SELECT COUNT(*) as total
      FROM clients
      WHERE is_active = 1
    ''';
    
    final totalActiveResult = await (databaseProvider as SQLiteDatabaseProvider).rawQuery(
      totalActiveClientsQuery,
    );

    // Contar clientes com leituras no mês
    final clientsWithReadingsQuery = '''
      SELECT COUNT(DISTINCT r.client_id) as total
      FROM readings r
      INNER JOIN clients c ON r.client_id = c.id
      WHERE r.month = ? AND r.year = ? AND c.is_active = 1
    ''';
    
    final clientsWithReadingsResult = await (databaseProvider as SQLiteDatabaseProvider).rawQuery(
      clientsWithReadingsQuery,
      [month, year],
    );

    final totalActiveClients = totalActiveResult.first['total'] ?? 0;
    final clientsWithReadings = clientsWithReadingsResult.first['total'] ?? 0;
    final clientsWithoutReadingsCount = clientsWithoutReadings.length;

    return {
      'month': month,
      'year': year,
      'total_active_clients': totalActiveClients,
      'clients_with_readings': clientsWithReadings,
      'clients_without_readings_count': clientsWithoutReadingsCount,
      'missing_percentage': totalActiveClients > 0 ? 
        ((clientsWithoutReadingsCount * 100.0) / totalActiveClients) : 0.0,
      'completion_percentage': totalActiveClients > 0 ? 
        ((clientsWithReadings * 100.0) / totalActiveClients) : 0.0,
      'clients_without_readings': clientsWithoutReadings,
    };
  }
}
