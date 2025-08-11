// ===== USER MODEL =====
// lib/app/data/models/user_model.dart

// Enum UserRole (movido de cliente_model.dart)
enum UserRole {
  admin,          // Administrador
  cashier,        // Caixa
  fieldOperator   // Operador Campo
}

// Extension para UserRole
extension UserRoleExtension on UserRole {
  String get displayName {
    switch (this) {
      case UserRole.admin:
        return 'Administrador';
      case UserRole.cashier:
        return 'Caixa';
      case UserRole.fieldOperator:
        return 'Operador de Campo';
    }
  }
}

class UserModel {
  final String? id;
  final String name;
  final String email;
  final String? phone;
  final UserRole role;
  final String? passwordHash;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? lastLogin;
  final bool isActive;
  final bool isSynced;

  UserModel({
    this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
    this.passwordHash,
    required this.createdAt,
    this.updatedAt,
    this.lastLogin,
    this.isActive = true,
    this.isSynced = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role.index,
      'password_hash': passwordHash,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'last_login': lastLogin?.toIso8601String(),
      'is_active': isActive ? 1 : 0,
      'is_synced': isSynced ? 1 : 0,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      role: UserRole.values[map['role'] ?? 0],
      passwordHash: map['password_hash'] ?? '',
      createdAt: DateTime.parse(map['created_at']),
      updatedAt:
          map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
      lastLogin:
          map['last_login'] != null ? DateTime.parse(map['last_login']) : null,
      isActive: map['is_active'] == 1,
      isSynced: map['is_synced'] == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role.name,
      'password_hash': passwordHash,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'last_login': lastLogin?.toIso8601String(),
      'is_active': isActive,
      'is_synced': isSynced,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      role: UserRole.values.firstWhere(
        (e) => e.name == json['role'],
        orElse: () => UserRole.fieldOperator,
      ),
      passwordHash: json['password_hash'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt:
          json['updated_at'] != null
              ? DateTime.parse(json['updated_at'])
              : null,
      lastLogin:
          json['last_login'] != null
              ? DateTime.parse(json['last_login'])
              : null,
      isActive: json['is_active'] ?? true,
      isSynced: json['is_synced'] ?? false,
    );
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    UserRole? role,
    String? passwordHash,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastLogin,
    bool? isActive,
    bool? isSynced,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      passwordHash: passwordHash ?? this.passwordHash,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastLogin: lastLogin ?? this.lastLogin,
      isActive: isActive ?? this.isActive,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  // Métodos úteis
  bool get isAdmin => role == UserRole.admin;
  bool get canRegisterPayments =>
      role == UserRole.admin || role == UserRole.cashier;
  bool get canRegisterClients =>
      role == UserRole.admin || role == UserRole.cashier;
  bool get canOnlyReadMeters => role == UserRole.fieldOperator;

  @override
  String toString() {
    return 'UserModel(id: $id, name: $name, email: $email, role: $role)';
  }
}
