// ===== READING MODEL =====
// lib/app/data/models/reading_model.dart

import 'package:vitalh2x/models/metodo_pagamento_model.dart';

class ReadingModel {
  final String? id;
  final String clientId;
  final int month;
  final int year;
  final double previousReading;
  final double currentReading;
  final double consumption; // m³ consumidos
  final double billAmount; // valor da conta
  final DateTime readingDate;
  final PaymentStatus paymentStatus;
  final DateTime? paymentDate;
  final String? notes;
  final bool isSynced;

  ReadingModel({
    this.id,
    required this.clientId,
    required this.month,
    required this.year,
    required this.previousReading,
    required this.currentReading,
    required this.consumption,
    required this.billAmount,
    required this.readingDate,
    this.paymentStatus = PaymentStatus.pending,
    this.paymentDate,
    this.notes,
    this.isSynced = false,
  });

  // Calcular consumo automaticamente
  double calculateConsumption() {
    return currentReading - previousReading;
  }

  // Calcular valor da conta (50 meticais por m³)
  double calculateBillAmount(double pricePerCubicMeter) {
    return consumption * pricePerCubicMeter;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'client_id': clientId,
      'month': month,
      'year': year,
      'previous_reading': previousReading,
      'current_reading': currentReading,
      'consumption': consumption,
      'bill_amount': billAmount,
      'reading_date': readingDate.toIso8601String(),
      'payment_status': paymentStatus.index,
      'payment_date': paymentDate?.toIso8601String(),
      'notes': notes,
      'is_synced': isSynced ? 1 : 0,
    };
  }

  factory ReadingModel.fromMap(Map<String, dynamic> map) {
    return ReadingModel(
      id: map['id'],
      clientId: map['client_id'],
      month: map['month'],
      year: map['year'],
      previousReading: map['previous_reading']?.toDouble() ?? 0.0,
      currentReading: map['current_reading']?.toDouble() ?? 0.0,
      consumption: map['consumption']?.toDouble() ?? 0.0,
      billAmount: map['bill_amount']?.toDouble() ?? 0.0,
      readingDate: DateTime.parse(map['reading_date']),
      paymentStatus: PaymentStatus.values[map['payment_status'] ?? 0],
      paymentDate:
          map['payment_date'] != null
              ? DateTime.parse(map['payment_date'])
              : null,
      notes: map['notes'],
      isSynced: map['is_synced'] == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'client_id': clientId,
      'month': month,
      'year': year,
      'previous_reading': previousReading,
      'current_reading': currentReading,
      'consumption': consumption,
      'bill_amount': billAmount,
      'reading_date': readingDate.toIso8601String(),
      'payment_status': paymentStatus.name,
      'payment_date': paymentDate?.toIso8601String(),
      'notes': notes,
      'is_synced': isSynced,
    };
  }

  factory ReadingModel.fromJson(Map<String, dynamic> json) {
    return ReadingModel(
      id: json['id'],
      clientId: json['client_id'],
      month: json['month'],
      year: json['year'],
      previousReading: json['previous_reading']?.toDouble() ?? 0.0,
      currentReading: json['current_reading']?.toDouble() ?? 0.0,
      consumption: json['consumption']?.toDouble() ?? 0.0,
      billAmount: json['bill_amount']?.toDouble() ?? 0.0,
      readingDate: DateTime.parse(json['reading_date']),
      paymentStatus: PaymentStatus.values.firstWhere(
        (e) => e.name == json['payment_status'],
        orElse: () => PaymentStatus.pending,
      ),
      paymentDate:
          json['payment_date'] != null
              ? DateTime.parse(json['payment_date'])
              : null,
      notes: json['notes'],
      isSynced: json['is_synced'] ?? false,
    );
  }

  ReadingModel copyWith({
    String? id,
    String? clientId,
    int? month,
    int? year,
    double? previousReading,
    double? currentReading,
    double? consumption,
    double? billAmount,
    DateTime? readingDate,
    PaymentStatus? paymentStatus,
    DateTime? paymentDate,
    String? notes,
    bool? isSynced,
  }) {
    return ReadingModel(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      month: month ?? this.month,
      year: year ?? this.year,
      previousReading: previousReading ?? this.previousReading,
      currentReading: currentReading ?? this.currentReading,
      consumption: consumption ?? this.consumption,
      billAmount: billAmount ?? this.billAmount,
      readingDate: readingDate ?? this.readingDate,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentDate: paymentDate ?? this.paymentDate,
      notes: notes ?? this.notes,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  // Métodos úteis
  String get monthYear => '$month/$year';
  bool get isPaid => paymentStatus == PaymentStatus.paid;
  bool get isOverdue => paymentStatus == PaymentStatus.overdue;
  int get daysOverdue {
    if (paymentDate == null) return 0;
    return DateTime.now().difference(paymentDate!).inDays;
  }

  @override
  String toString() {
    return 'ReadingModel(clientId: $clientId, month: $month, year: $year, consumption: $consumption, billAmount: $billAmount, status: $paymentStatus)';
  }
}
