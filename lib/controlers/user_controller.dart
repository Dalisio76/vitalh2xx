// ===== USER CONTROLLER =====
// lib/app/controllers/user_controller.dart

import 'package:crypto/crypto.dart';
import 'package:get/get.dart';
import 'package:vitalh2x/controlers/auth_controller.dart';
import 'package:vitalh2x/controlers/base_controler.dart';
import 'package:vitalh2x/models/usuario_model.dart';
import 'package:vitalh2x/repository/user_repository.dart';
import 'package:vitalh2x/services/database_providers.dart';
import 'dart:convert';

class UserController extends BaseController {
  final UserRepository _userRepository = UserRepository(
    SQLiteDatabaseProvider(),
  );

  // Lists
  final RxList<UserModel> users = <UserModel>[].obs;
  final RxList<UserModel> filteredUsers = <UserModel>[].obs;

  // Current user
  final Rx<UserModel?> selectedUser = Rx<UserModel?>(null);
  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);

  // Form fields
  final RxString name = ''.obs;
  final RxString email = ''.obs;
  final RxString phone = ''.obs;
  final RxString password = ''.obs;
  final RxString confirmPassword = ''.obs;
  final Rx<UserRole> role = UserRole.fieldOperator.obs;
  final RxBool isActive = true.obs;

  // Search and filters
  final RxString searchTerm = ''.obs;
  final Rx<UserRole?> filterRole = Rx<UserRole?>(null);
  final RxBool showOnlyActive = true.obs;

  // Statistics
  final RxMap<String, dynamic> stats = <String, dynamic>{}.obs;

  // Estado do formulário
  final RxBool isEditing = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadCurrentUser();
    loadUsers();
    loadStats();

    // Setup reactive searches and filters
    ever(searchTerm, (_) => filterUsers());
    ever(filterRole, (_) => filterUsers());
    ever(showOnlyActive, (_) => filterUsers());
  }

  // Load current user from auth controller
  void _loadCurrentUser() {
    try {
      final authController = Get.find<AuthController>();
      currentUser.value = authController.currentUser;
    } catch (e) {
      print('Error loading current user: $e');
    }
  }

  // Load all users
  Future<void> loadUsers() async {
    try {
      showLoading('Carregando usuários...');

      final userList = await _userRepository.findAll();
      users.assignAll(userList);
      filterUsers();
      
      hideLoading();
    } catch (e) {
      handleException(e);
    }
  }

  // Load user statistics
  Future<void> loadStats() async {
    try {
      final totalUsers = await _userRepository.count();
      final activeUsers = await _userRepository.count(
        where: 'is_active = 1',
      );
      
      final adminCount = await _userRepository.count(
        where: 'role = ? AND is_active = 1',
        whereArgs: [UserRole.admin.index],
      );
      
      final cashierCount = await _userRepository.count(
        where: 'role = ? AND is_active = 1',
        whereArgs: [UserRole.cashier.index],
      );
      
      final fieldOpCount = await _userRepository.count(
        where: 'role = ? AND is_active = 1',
        whereArgs: [UserRole.fieldOperator.index],
      );

      stats.assignAll({
        'total': totalUsers,
        'active': activeUsers,
        'admins': adminCount,
        'cashiers': cashierCount,
        'fieldOperators': fieldOpCount,
      });
    } catch (e) {
      print('Error loading user stats: $e');
    }
  }

  // Filter users based on search term and filters
  void filterUsers() {
    List<UserModel> filtered = users.toList();

    // Filter by search term
    if (searchTerm.value.isNotEmpty) {
      final term = searchTerm.value.toLowerCase();
      filtered = filtered.where((user) {
        return user.name.toLowerCase().contains(term) ||
               user.email.toLowerCase().contains(term) ||
               (user.phone?.toLowerCase().contains(term) ?? false);
      }).toList();
    }

    // Filter by role
    if (filterRole.value != null) {
      filtered = filtered.where((user) {
        return user.role == filterRole.value;
      }).toList();
    }

    // Filter by active status
    if (showOnlyActive.value) {
      filtered = filtered.where((user) => user.isActive).toList();
    }

    filteredUsers.assignAll(filtered);
  }

  // Create new user
  Future<void> createUser() async {
    try {
      if (!_validateForm()) return;

      showLoading('Criando usuário...');

      // Check if email already exists
      final emailExists = await _userRepository.emailExists(email.value.trim());
      if (emailExists) {
        showError('Este email já está em uso');
        hideLoading();
        return;
      }

      // Hash password
      final hashedPassword = _hashPassword(password.value);

      // Create user model
      final user = UserModel(
        name: name.value.trim(),
        email: email.value.trim().toLowerCase(),
        phone: phone.value.trim().isEmpty ? null : phone.value.trim(),
        role: role.value,
        passwordHash: hashedPassword,
        createdAt: DateTime.now(),
        isActive: isActive.value,
      );

      // Save user
      await _userRepository.create(user);

      // Reload data
      clearForm();
      await loadUsers();
      await loadStats();

      hideLoading();
      showSuccess('Usuário criado com sucesso!');

      // Navigate back
      await Future.delayed(const Duration(milliseconds: 1500));
      Get.back();
    } catch (e) {
      hideLoading();
      handleException(e);
    }
  }

  // Update existing user
  Future<void> updateUser() async {
    try {
      if (!_validateForm()) return;
      if (selectedUser.value == null) {
        showError('Nenhum usuário selecionado para edição');
        return;
      }

      showLoading('Atualizando usuário...');

      // Check if email already exists (excluding current user)
      final emailExists = await _userRepository.emailExists(
        email.value.trim(),
        excludeId: selectedUser.value!.id,
      );
      if (emailExists) {
        showError('Este email já está em uso');
        hideLoading();
        return;
      }

      // Create updated user data
      Map<String, dynamic> updateData = {
        'name': name.value.trim(),
        'email': email.value.trim().toLowerCase(),
        'phone': phone.value.trim().isEmpty ? null : phone.value.trim(),
        'role': role.value.index,
        'is_active': isActive.value ? 1 : 0,
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Update password if provided
      if (password.value.isNotEmpty) {
        updateData['password_hash'] = _hashPassword(password.value);
      }

      // Update in database
      await _userRepository.databaseProvider.update(
        'users',
        updateData,
        where: 'id = ?',
        whereArgs: [selectedUser.value!.id!],
      );

      // Reload data
      clearForm();
      await loadUsers();
      await loadStats();

      hideLoading();
      showSuccess('Usuário atualizado com sucesso!');

      // Navigate back
      await Future.delayed(const Duration(milliseconds: 1500));
      Get.back();
    } catch (e) {
      hideLoading();
      handleException(e);
    }
  }

  // Unified save method
  Future<void> saveUser() async {
    if (isEditing.value) {
      await updateUser();
    } else {
      await createUser();
    }
  }

  // Select user for editing
  void selectUser(UserModel user) {
    selectedUser.value = user;
    name.value = user.name;
    email.value = user.email;
    phone.value = user.phone ?? '';
    role.value = user.role;
    isActive.value = user.isActive;
    password.value = '';
    confirmPassword.value = '';
    isEditing.value = true;
  }

  // Deactivate user
  Future<void> deactivateUser(String userId) async {
    try {
      showLoading('Desativando usuário...');

      await _userRepository.deactivateUser(userId);

      await loadUsers();
      await loadStats();

      hideLoading();
      showSuccess('Usuário desativado com sucesso!');
    } catch (e) {
      hideLoading();
      handleException(e);
    }
  }

  // Activate user
  Future<void> activateUser(String userId) async {
    try {
      showLoading('Ativando usuário...');

      await _userRepository.databaseProvider.update(
        'users',
        {'is_active': 1, 'updated_at': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [userId],
      );

      await loadUsers();
      await loadStats();

      hideLoading();
      showSuccess('Usuário ativado com sucesso!');
    } catch (e) {
      hideLoading();
      handleException(e);
    }
  }

  // Delete user (soft delete)
  Future<void> deleteUser(String userId) async {
    try {
      showLoading('Excluindo usuário...');

      await _userRepository.delete(userId);

      await loadUsers();
      await loadStats();

      hideLoading();
      showSuccess('Usuário excluído com sucesso!');
    } catch (e) {
      hideLoading();
      handleException(e);
    }
  }

  // Reset password
  Future<void> resetPassword(String userId, String newPassword) async {
    try {
      showLoading('Redefinindo senha...');

      final hashedPassword = _hashPassword(newPassword);

      await _userRepository.databaseProvider.update(
        'users',
        {
          'password_hash': hashedPassword,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [userId],
      );

      hideLoading();
      showSuccess('Senha redefinida com sucesso!');
    } catch (e) {
      hideLoading();
      handleException(e);
    }
  }

  // Clear form
  void clearForm() {
    name.value = '';
    email.value = '';
    phone.value = '';
    password.value = '';
    confirmPassword.value = '';
    role.value = UserRole.fieldOperator;
    isActive.value = true;
    selectedUser.value = null;
    isEditing.value = false;
  }

  // Refresh data
  Future<void> refreshData() async {
    await loadUsers();
    await loadStats();
  }

  // Form validation
  bool _validateForm() {
    if (name.value.trim().isEmpty) {
      showError('Nome é obrigatório');
      return false;
    }

    if (email.value.trim().isEmpty) {
      showError('Email é obrigatório');
      return false;
    }

    if (!GetUtils.isEmail(email.value.trim())) {
      showError('Email inválido');
      return false;
    }

    if (!isEditing.value && password.value.isEmpty) {
      showError('Senha é obrigatória');
      return false;
    }

    if (password.value.isNotEmpty && password.value.length < 6) {
      showError('Senha deve ter pelo menos 6 caracteres');
      return false;
    }

    if (password.value != confirmPassword.value) {
      showError('Confirmação de senha não confere');
      return false;
    }

    return true;
  }

  // Field validators
  String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Nome é obrigatório';
    }
    if (value.trim().length < 2) {
      return 'Nome deve ter pelo menos 2 caracteres';
    }
    return null;
  }

  String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email é obrigatório';
    }
    if (!GetUtils.isEmail(value.trim())) {
      return 'Email inválido';
    }
    return null;
  }

  String? validatePassword(String? value) {
    if (!isEditing.value && (value == null || value.isEmpty)) {
      return 'Senha é obrigatória';
    }
    if (value != null && value.isNotEmpty && value.length < 6) {
      return 'Senha deve ter pelo menos 6 caracteres';
    }
    return null;
  }

  String? validateConfirmPassword(String? value) {
    if (password.value.isNotEmpty && value != password.value) {
      return 'Confirmação de senha não confere';
    }
    return null;
  }

  // Utility methods
  String _hashPassword(String password) {
    // Simple hash for demo - in production use bcrypt or similar
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Get form title
  String get formTitle => isEditing.value ? 'Editar Usuário' : 'Novo Usuário';

  // Get save button text
  String get saveButtonText => isEditing.value ? 'Atualizar' : 'Salvar';

  // Get role display name
  String getRoleDisplayName(UserRole userRole) {
    return userRole.displayName;
  }

  // Get user by ID
  Future<UserModel?> getUserById(String userId) async {
    try {
      return await _userRepository.findById(userId);
    } catch (e) {
      print('Error getting user by ID: $e');
      return null;
    }
  }

  // Check if current user can manage users
  bool get canManageUsers {
    return currentUser.value?.isAdmin ?? false;
  }

  // Check if user can edit other users
  bool canEditUser(UserModel user) {
    final current = currentUser.value;
    if (current == null) return false;
    
    // Admin can edit anyone except themselves
    if (current.isAdmin) return current.id != user.id;
    
    return false;
  }

  // Check if user can delete other users
  bool canDeleteUser(UserModel user) {
    final current = currentUser.value;
    if (current == null) return false;
    
    // Admin can delete non-admin users and inactive admins
    if (current.isAdmin) {
      return current.id != user.id && (!user.isAdmin || !user.isActive);
    }
    
    return false;
  }
}