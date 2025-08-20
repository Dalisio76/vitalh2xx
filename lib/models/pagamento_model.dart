// ===== PAYMENT MODEL =====
// lib/app/data/models/payment_model.dart

import 'package:vitalh2x/models/cliente_model.dart';

class PaymentModel {
  final String? id;
  final int? paymentNumber; // Número sequencial do pagamento
  final String clientId;
  final String readingId;
  final double amountPaid;
  final PaymentMethod paymentMethod;
  final DateTime paymentDate;
  final String receiptNumber;
  final String? transactionReference;
  final String? notes;
  final String userId; // quem registrou o pagamento
  final bool isSynced;

  PaymentModel({
    this.id,
    this.paymentNumber,
    required this.clientId,
    required this.readingId,
    required this.amountPaid,
    required this.paymentMethod,
    required this.paymentDate,
    required this.receiptNumber,
    this.transactionReference,
    this.notes,
    required this.userId,
    this.isSynced = false,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'id': id,
      'client_id': clientId,
      'reading_id': readingId,
      'amount_paid': amountPaid,
      'payment_method': paymentMethod.index,
      'payment_date': paymentDate.toIso8601String(),
      'receipt_number': receiptNumber,
      'transaction_reference': transactionReference,
      'notes': notes,
      'user_id': userId,
      'is_synced': isSynced ? 1 : 0,
    };
    
    // Apenas incluir payment_number se não for null
    // Isso evita erros caso a coluna não exista ainda no banco
    if (paymentNumber != null) {
      map['payment_number'] = paymentNumber;
    }
    
    return map;
  }

  factory PaymentModel.fromMap(Map<String, dynamic> map) {
    return PaymentModel(
      id: map['id'],
      paymentNumber: map.containsKey('payment_number') ? map['payment_number'] : null,
      clientId: map['client_id'],
      readingId: map['reading_id'],
      amountPaid: map['amount_paid']?.toDouble() ?? 0.0,
      paymentMethod: PaymentMethod.values[map['payment_method'] ?? 0],
      paymentDate: DateTime.parse(map['payment_date']),
      receiptNumber: map['receipt_number'] ?? '',
      transactionReference: map['transaction_reference'],
      notes: map['notes'],
      userId: map['user_id'],
      isSynced: map['is_synced'] == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'client_id': clientId,
      'reading_id': readingId,
      'amount_paid': amountPaid,
      'payment_method': paymentMethod.name,
      'payment_date': paymentDate.toIso8601String(),
      'receipt_number': receiptNumber,
      'transaction_reference': transactionReference,
      'notes': notes,
      'user_id': userId,
      'is_synced': isSynced,
    };
  }

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'],
      clientId: json['client_id'],
      readingId: json['reading_id'],
      amountPaid: json['amount_paid']?.toDouble() ?? 0.0,
      paymentMethod: PaymentMethod.values.firstWhere(
        (e) => e.name == json['payment_method'],
        orElse: () => PaymentMethod.cash,
      ),
      paymentDate: DateTime.parse(json['payment_date']),
      receiptNumber: json['receipt_number'] ?? '',
      transactionReference: json['transaction_reference'],
      notes: json['notes'],
      userId: json['user_id'],
      isSynced: json['is_synced'] ?? false,
    );
  }

  PaymentModel copyWith({
    String? id,
    int? paymentNumber,
    String? clientId,
    String? readingId,
    double? amountPaid,
    PaymentMethod? paymentMethod,
    DateTime? paymentDate,
    String? receiptNumber,
    String? transactionReference,
    String? notes,
    String? userId,
    bool? isSynced,
  }) {
    return PaymentModel(
      id: id ?? this.id,
      paymentNumber: paymentNumber ?? this.paymentNumber,
      clientId: clientId ?? this.clientId,
      readingId: readingId ?? this.readingId,
      amountPaid: amountPaid ?? this.amountPaid,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentDate: paymentDate ?? this.paymentDate,
      receiptNumber: receiptNumber ?? this.receiptNumber,
      transactionReference: transactionReference ?? this.transactionReference,
      notes: notes ?? this.notes,
      userId: userId ?? this.userId,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  @override
  String toString() {
    return 'PaymentModel(clientId: $clientId, amount: $amountPaid, method: $paymentMethod, date: $paymentDate)';
  }
}
