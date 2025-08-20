import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:vitalh2x/models/usuario_model.dart';
import 'package:vitalh2x/repository/base_repository.dart';
import 'package:vitalh2x/services/database_providers.dart';

class UserRepository extends BaseRepository<UserModel> {
  UserRepository(DatabaseProvider databaseProvider)
    : super(databaseProvider, 'users');

  @override
  UserModel fromMap(Map<String, dynamic> map) {
    return UserModel.fromMap(map);
  }

  @override
  Map<String, dynamic> toMap(UserModel model) {
    return model.toMap();
  }

  // Buscar usuário por email
  Future<UserModel?> findByEmail(String email) async {
    final results = await databaseProvider.query(
      tableName,
      where: 'email = ? AND is_active = 1',
      whereArgs: [email],
      limit: 1,
    );

    if (results.isEmpty) return null;
    return fromMap(results.first);
  }

  // Verificar login
  Future<UserModel?> authenticate(String email, String password) async {
    final user = await findByEmail(email);
    if (user == null) return null;

    // Verificar hash da senha
    final hashedPassword = _hashPassword(password);
    if (user.passwordHash == hashedPassword) {
      // Atualizar último login
      await updateLastLogin(user.id!);
      return user;
    }

    return null;
  }

  // Hash da senha usando SHA256 (mesmo método do DatabaseService)
  String _hashPassword(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Atualizar último login
  Future<void> updateLastLogin(String userId) async {
    await databaseProvider.update(
      tableName,
      {'last_login': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  // Buscar usuários por role
  Future<List<UserModel>> findByRole(role) async {
    final results = await databaseProvider.query(
      tableName,
      where: 'role = ? AND is_active = 1',
      whereArgs: [role.index],
      orderBy: 'name ASC',
    );

    return results.map((map) => fromMap(map)).toList();
  }

  // Verificar se email já existe
  Future<bool> emailExists(String email, {String? excludeId}) async {
    String where = 'email = ?';
    List<dynamic> whereArgs = [email];

    if (excludeId != null) {
      where += ' AND id != ?';
      whereArgs.add(excludeId);
    }

    final count = await this.count(where: where, whereArgs: whereArgs);
    return count > 0;
  }

  // Buscar usuários ativos
  Future<List<UserModel>> findActiveUsers() async {
    final results = await databaseProvider.query(
      tableName,
      where: 'is_active = 1',
      orderBy: 'name ASC',
    );

    return results.map((map) => fromMap(map)).toList();
  }

  // Desativar usuário
  Future<bool> deactivateUser(String userId) async {
    final count = await databaseProvider.update(
      tableName,
      {'is_active': 0, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [userId],
    );

    return count > 0;
  }
}
