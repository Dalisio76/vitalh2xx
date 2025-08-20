import 'package:vitalh2x/models/cliente_model.dart';
import 'package:vitalh2x/models/pagamento_model.dart';
import 'package:vitalh2x/services/database_providers.dart';

import 'base_repository.dart';

class PaymentRepository extends BaseRepository<PaymentModel> {
  PaymentRepository(DatabaseProvider databaseProvider)
    : super(databaseProvider, 'payments');

  @override
  PaymentModel fromMap(Map<String, dynamic> map) {
    return PaymentModel.fromMap(map);
  }

  @override
  Map<String, dynamic> toMap(PaymentModel model) {
    return model.toMap();
  }

  // Buscar pagamentos por cliente
  Future<List<PaymentModel>> findByClient(
    String clientId, {
    int? limit,
    int? offset,
  }) async {
    final results = await databaseProvider.query(
      tableName,
      where: 'client_id = ?',
      whereArgs: [clientId],
      orderBy: 'payment_date DESC',
      limit: limit,
      offset: offset,
    );

    return results.map((map) => fromMap(map)).toList();
  }

  // Buscar pagamentos por leitura
  Future<List<PaymentModel>> findByReading(String readingId) async {
    final results = await databaseProvider.query(
      tableName,
      where: 'reading_id = ?',
      whereArgs: [readingId],
      orderBy: 'payment_date DESC',
    );

    return results.map((map) => fromMap(map)).toList();
  }

  // Buscar pagamento por número do recibo
  Future<PaymentModel?> findByReceiptNumber(String receiptNumber) async {
    final results = await databaseProvider.query(
      tableName,
      where: 'receipt_number = ?',
      whereArgs: [receiptNumber],
      limit: 1,
    );

    if (results.isEmpty) return null;
    return fromMap(results.first);
  }

  // Buscar pagamentos por período
  Future<List<PaymentModel>> findByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final results = await databaseProvider.query(
      tableName,
      where: 'payment_date >= ? AND payment_date <= ?',
      whereArgs: [startDate.toIso8601String(), endDate.toIso8601String()],
      orderBy: 'payment_date DESC',
    );

    return results.map((map) => fromMap(map)).toList();
  }

  // Buscar pagamentos por método
  Future<List<PaymentModel>> findByPaymentMethod(PaymentMethod method) async {
    final results = await databaseProvider.query(
      tableName,
      where: 'payment_method = ?',
      whereArgs: [method.index],
      orderBy: 'payment_date DESC',
    );

    return results.map((map) => fromMap(map)).toList();
  }

  // Gerar próximo número de recibo
  Future<String> generateReceiptNumber() async {
    final now = DateTime.now();
    final year = now.year.toString();
    final month = now.month.toString().padLeft(2, '0');

    // Buscar último recibo do mês
    final results = await databaseProvider.query(
      tableName,
      where: 'receipt_number LIKE ?',
      whereArgs: ['$year$month%'],
      orderBy: 'receipt_number DESC',
      limit: 1,
    );

    int nextNumber = 1;
    if (results.isNotEmpty) {
      final lastReceipt = results.first['receipt_number'] as String;
      if (lastReceipt.length >= 8) {
        final lastNumber = int.tryParse(lastReceipt.substring(6)) ?? 0;
        nextNumber = lastNumber + 1;
      }
    }

    return '$year$month${nextNumber.toString().padLeft(4, '0')}';
  }

  // Verificar se número de recibo existe
  Future<bool> receiptNumberExists(String receiptNumber) async {
    final count = await this.count(
      where: 'receipt_number = ?',
      whereArgs: [receiptNumber],
    );
    return count > 0;
  }

  // Calcular total pago por cliente
  Future<double> getTotalPaidByClient(String clientId) async {
    final results = await (databaseProvider as SQLiteDatabaseProvider).rawQuery(
      'SELECT SUM(amount_paid) as total FROM payments WHERE client_id = ?',
      [clientId],
    );

    return (results.first['total'] as double?) ?? 0.0;
  }

  // Calcular total pago por leitura
  Future<double> getTotalPaidByReading(String readingId) async {
    final results = await (databaseProvider as SQLiteDatabaseProvider).rawQuery(
      'SELECT SUM(amount_paid) as total FROM payments WHERE reading_id = ?',
      [readingId],
    );

    return (results.first['total'] as double?) ?? 0.0;
  }

  // Estatísticas de pagamentos
  Future<Map<String, dynamic>> getPaymentStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final stats = <String, dynamic>{};

    List<dynamic> whereArgs = [];

    if (startDate != null && endDate != null) {
      whereArgs = [startDate.toIso8601String(), endDate.toIso8601String()];
    }

    // Total de pagamentos
    stats['total_payments'] = await count(
      where:
          startDate != null && endDate != null
              ? 'payment_date >= ? AND payment_date <= ?'
              : null,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
    );

    // Total arrecadado
    final totalQuery =
        startDate != null && endDate != null
            ? 'SELECT SUM(amount_paid) as total FROM payments WHERE payment_date >= ? AND payment_date <= ?'
            : 'SELECT SUM(amount_paid) as total FROM payments';

    final totalResult = await (databaseProvider as SQLiteDatabaseProvider)
        .rawQuery(totalQuery, whereArgs.isEmpty ? null : whereArgs);

    stats['total_amount'] = (totalResult.first['total'] as double?) ?? 0.0;

    // Por método de pagamento
    for (PaymentMethod method in PaymentMethod.values) {
      final methodWhere =
          startDate != null && endDate != null
              ? 'payment_method = ? AND payment_date >= ? AND payment_date <= ?'
              : 'payment_method = ?';
      final methodArgs =
          startDate != null && endDate != null
              ? [method.index, ...whereArgs]
              : [method.index];

      final methodQuery =
          'SELECT COUNT(*) as count, SUM(amount_paid) as total FROM payments WHERE $methodWhere';
      final methodResult = await (databaseProvider as SQLiteDatabaseProvider)
          .rawQuery(methodQuery, methodArgs);

      stats['${method.name}_count'] = methodResult.first['count'] ?? 0;
      stats['${method.name}_amount'] =
          (methodResult.first['total'] as double?) ?? 0.0;
    }

    return stats;
  }

  // Buscar pagamentos com informações completas
  Future<List<Map<String, dynamic>>> findPaymentsWithDetails({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    String where = '';
    List<dynamic> whereArgs = [];

    if (startDate != null && endDate != null) {
      where = 'WHERE p.payment_date >= ? AND p.payment_date <= ?';
      whereArgs = [startDate.toIso8601String(), endDate.toIso8601String()];
    }

    final query = '''
      SELECT 
        p.*,
        c.name as client_name,
        c.reference as client_reference,
        r.month as reading_month,
        r.year as reading_year,
        r.bill_amount as bill_amount,
        u.name as user_name
      FROM payments p
      INNER JOIN clients c ON p.client_id = c.id
      INNER JOIN readings r ON p.reading_id = r.id
      INNER JOIN users u ON p.user_id = u.id
      $where
      ORDER BY p.payment_date DESC
    ''';

    return await (databaseProvider as SQLiteDatabaseProvider).rawQuery(
      query,
      whereArgs.isEmpty ? null : whereArgs,
    );
  }

  // Relatório de arrecadação por forma de pagamento por mês
  Future<Map<String, dynamic>> getMonthlyRevenueByPaymentMethod(
    int month,
    int year,
  ) async {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 1).subtract(Duration(days: 1));

    final report = <String, dynamic>{
      'month': month,
      'year': year,
      'total_amount': 0.0,
      'total_payments': 0,
      'payment_methods': <String, dynamic>{},
    };

    // Total geral do mês
    final totalQuery = '''
      SELECT 
        COUNT(*) as total_payments,
        COALESCE(SUM(amount_paid), 0) as total_amount
      FROM payments 
      WHERE payment_date >= ? AND payment_date < ?
    ''';

    final totalResult = await (databaseProvider as SQLiteDatabaseProvider).rawQuery(
      totalQuery,
      [startDate.toIso8601String(), endDate.add(Duration(days: 1)).toIso8601String()],
    );

    report['total_payments'] = totalResult.first['total_payments'] ?? 0;
    report['total_amount'] = (totalResult.first['total_amount'] as double?) ?? 0.0;

    // Por cada método de pagamento
    for (PaymentMethod method in PaymentMethod.values) {
      final methodQuery = '''
        SELECT 
          COUNT(*) as count,
          COALESCE(SUM(amount_paid), 0) as amount,
          ROUND((COALESCE(SUM(amount_paid), 0) * 100.0 / ?), 2) as percentage
        FROM payments 
        WHERE payment_method = ? 
        AND payment_date >= ? AND payment_date < ?
      ''';

      final methodResult = await (databaseProvider as SQLiteDatabaseProvider).rawQuery(
        methodQuery,
        [
          report['total_amount'] > 0 ? report['total_amount'] : 1, // Evitar divisão por zero
          method.index,
          startDate.toIso8601String(),
          endDate.add(Duration(days: 1)).toIso8601String(),
        ],
      );

      final methodData = methodResult.first;
      report['payment_methods'][method.name] = {
        'display_name': method.displayName,
        'count': methodData['count'] ?? 0,
        'amount': (methodData['amount'] as double?) ?? 0.0,
        'percentage': report['total_amount'] > 0 ? (methodData['percentage'] as double?) ?? 0.0 : 0.0,
      };
    }

    return report;
  }

  // Relatório de arrecadação anual com breakdown por mês
  Future<Map<String, dynamic>> getYearlyRevenueReport(int year) async {
    final report = <String, dynamic>{
      'year': year,
      'total_amount': 0.0,
      'total_payments': 0,
      'monthly_breakdown': <Map<String, dynamic>>[],
      'payment_methods_summary': <String, dynamic>{},
    };

    // Para cada mês do ano
    for (int month = 1; month <= 12; month++) {
      final monthlyReport = await getMonthlyRevenueByPaymentMethod(month, year);
      report['monthly_breakdown'].add(monthlyReport);
      
      // Somar ao total anual
      report['total_amount'] = (report['total_amount'] as double) + (monthlyReport['total_amount'] as double);
      report['total_payments'] = (report['total_payments'] as int) + (monthlyReport['total_payments'] as int);
    }

    // Resumo por método de pagamento no ano
    for (PaymentMethod method in PaymentMethod.values) {
      final yearMethodQuery = '''
        SELECT 
          COUNT(*) as count,
          COALESCE(SUM(amount_paid), 0) as amount
        FROM payments 
        WHERE payment_method = ? 
        AND payment_date >= ? AND payment_date < ?
      ''';

      final yearMethodResult = await (databaseProvider as SQLiteDatabaseProvider).rawQuery(
        yearMethodQuery,
        [
          method.index,
          DateTime(year, 1, 1).toIso8601String(),
          DateTime(year + 1, 1, 1).toIso8601String(),
        ],
      );

      final methodData = yearMethodResult.first;
      final amount = (methodData['amount'] as double?) ?? 0.0;
      report['payment_methods_summary'][method.name] = {
        'display_name': method.displayName,
        'count': methodData['count'] ?? 0,
        'amount': amount,
        'percentage': report['total_amount'] > 0 ? (amount * 100.0 / (report['total_amount'] as double)) : 0.0,
      };
    }

    return report;
  }
}
