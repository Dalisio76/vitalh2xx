// ===== CLIENT MODEL =====
// lib/app/data/models/client_model.dart

import 'package:vitalh2x/models/metodo_pagamento_model.dart';

class ClientModel {
  final String? id;
  final String name;
  final String contact;
  final String reference;
  final String counterNumber;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isActive;
  final double? lastReading;
  final double totalDebt;
  final bool isSynced;

  ClientModel({
    this.id,
    required this.name,
    required this.contact,
    required this.reference,
    required this.counterNumber,
    required this.createdAt,
    this.updatedAt,
    this.isActive = true,
    this.lastReading,
    this.totalDebt = 0.0,
    this.isSynced = false,
  });

  // Converter para Map (para SQLite)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'contact': contact,
      'reference': reference,
      'counter_number': counterNumber,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'is_active': isActive ? 1 : 0,
      'last_reading': lastReading,
      'total_debt': totalDebt,
      'is_synced': isSynced ? 1 : 0,
    };
  }

  // Criar objeto do Map
  factory ClientModel.fromMap(Map<String, dynamic> map) {
    return ClientModel(
      id: map['id'],
      name: map['name'] ?? '',
      contact: map['contact'] ?? '',
      reference: map['reference'] ?? '',
      counterNumber: map['counter_number'] ?? '',
      createdAt: DateTime.parse(map['created_at']),
      updatedAt:
          map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
      isActive: map['is_active'] == 1,
      lastReading: map['last_reading']?.toDouble(),
      totalDebt: map['total_debt']?.toDouble() ?? 0.0,
      isSynced: map['is_synced'] == 1,
    );
  }

  // Converter para JSON (para API)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'contact': contact,
      'reference': reference,
      'counter_number': counterNumber,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'is_active': isActive,
      'last_reading': lastReading,
      'total_debt': totalDebt,
      'is_synced': isSynced,
    };
  }

  // Criar objeto do JSON
  factory ClientModel.fromJson(Map<String, dynamic> json) {
    return ClientModel(
      id: json['id'],
      name: json['name'] ?? '',
      contact: json['contact'] ?? '',
      reference: json['reference'] ?? '',
      counterNumber: json['counter_number'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt:
          json['updated_at'] != null
              ? DateTime.parse(json['updated_at'])
              : null,
      isActive: json['is_active'] ?? true,
      lastReading: json['last_reading']?.toDouble(),
      totalDebt: json['total_debt']?.toDouble() ?? 0.0,
      isSynced: json['is_synced'] ?? false,
    );
  }

  // Método copyWith para atualizações
  ClientModel copyWith({
    String? id,
    String? name,
    String? contact,
    String? reference,
    String? counterNumber,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    double? lastReading,
    double? totalDebt,
    bool? isSynced,
  }) {
    return ClientModel(
      id: id ?? this.id,
      name: name ?? this.name,
      contact: contact ?? this.contact,
      reference: reference ?? this.reference,
      counterNumber: counterNumber ?? this.counterNumber,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      lastReading: lastReading ?? this.lastReading,
      totalDebt: totalDebt ?? this.totalDebt,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  @override
  String toString() {
    return 'ClientModel(id: $id, name: $name, reference: $reference, counterNumber: $counterNumber, totalDebt: $totalDebt)';
  }
}

enum PaymentMethod {
  cash, // Dinheiro
  bankTransfer, // Transferência bancária
  mobileMoney, // M-Pesa, E-Mola, etc.
  check, // Cheque
  other, // Outros
}

// Extensions para melhor uso
extension PaymentStatusExtension on PaymentStatus {
  String get displayName {
    switch (this) {
      case PaymentStatus.pending:
        return 'Pendente';
      case PaymentStatus.paid:
        return 'Pago';
      case PaymentStatus.overdue:
        return 'Em Atraso';
      case PaymentStatus.partial:
        return 'Parcial';
    }
  }

  bool get isPaid => this == PaymentStatus.paid;
  bool get isOverdue => this == PaymentStatus.overdue;
}

extension PaymentMethodExtension on PaymentMethod {
  String get displayName {
    switch (this) {
      case PaymentMethod.cash:
        return 'Dinheiro';
      case PaymentMethod.bankTransfer:
        return 'Transferência';
      case PaymentMethod.mobileMoney:
        return 'Mobile Money';
      case PaymentMethod.check:
        return 'Cheque';
      case PaymentMethod.other:
        return 'Outros';
    }
  }
}
