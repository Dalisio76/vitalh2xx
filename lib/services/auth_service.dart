import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitalh2x/models/usuario_model.dart';
import 'package:vitalh2x/repository/user_repository.dart';
import 'package:vitalh2x/services/database_providers.dart';

class AuthService extends GetxController {
  // Repositório de usuários
  late final UserRepository _userRepository;
  
  // Estado reativo do usuário
  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);
  final RxBool isLoggedIn = false.obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    _initializeRepository();
    _initializeAuth();
  }

  void _initializeRepository() {
    final databaseProvider = SQLiteDatabaseProvider();
    _userRepository = UserRepository(databaseProvider);
  }

  // Inicializar autenticação ao abrir app
  Future<void> _initializeAuth() async {
    isLoading.value = true;
    
    try {
      // Verificar se tem usuário salvo localmente
      final userId = await _getStoredUserId();
      if (userId != null) {
        // Buscar usuário no banco local
        final user = await _userRepository.findById(userId);
        if (user != null && user.isActive) {
          currentUser.value = user;
          isLoggedIn.value = true;
        } else {
          // Usuário inválido, limpar dados
          await logout();
        }
      }
    } catch (e) {
      print('Erro ao inicializar auth: $e');
      await logout();
    } finally {
      isLoading.value = false;
    }
  }

  // Login do usuário
  Future<AuthResult> login(String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      return AuthResult.error('Email e senha são obrigatórios');
    }

    isLoading.value = true;

    try {
      // Autenticação local usando UserRepository
      final user = await _userRepository.authenticate(email, password);
      
      if (user != null) {
        currentUser.value = user;
        isLoggedIn.value = true;
        
        // Salvar ID do usuário para sessões futuras
        await _storeUserId(user.id!);
        
        return AuthResult.success('Login realizado com sucesso');
      }
      
      return AuthResult.error('Email ou senha incorretos');
    } catch (e) {
      return AuthResult.error('Erro ao fazer login: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Logout do usuário
  Future<void> logout() async {
    isLoading.value = true;

    try {
      // Limpar dados salvos localmente
      await _clearStoredUserId();
    } catch (e) {
      print('Erro no logout: $e');
    } finally {
      // Limpar dados locais independentemente do resultado
      currentUser.value = null;
      isLoggedIn.value = false;
      isLoading.value = false;
      
      // Redirecionar para login
      Get.offAllNamed('/login');
    }
  }

  // Verificar se usuário tem permissão para uma ação
  bool hasPermission(UserPermission permission) {
    if (currentUser.value == null) return false;
    
    final userRole = currentUser.value!.role;
    
    switch (permission) {
      case UserPermission.viewClients:
        return [UserRole.admin, UserRole.cashier, UserRole.fieldOperator]
            .contains(userRole);
            
      case UserPermission.createClients:
      case UserPermission.editClients:
        return [UserRole.admin, UserRole.cashier].contains(userRole);
        
      case UserPermission.deleteClients:
        return userRole == UserRole.admin;
        
      case UserPermission.viewReadings:
        return [UserRole.admin, UserRole.cashier, UserRole.fieldOperator]
            .contains(userRole);
            
      case UserPermission.createReadings:
      case UserPermission.editReadings:
        return [UserRole.admin, UserRole.fieldOperator].contains(userRole);
        
      case UserPermission.deleteReadings:
        return userRole == UserRole.admin;
        
      case UserPermission.viewPayments:
      case UserPermission.createPayments:
      case UserPermission.editPayments:
        return [UserRole.admin, UserRole.cashier].contains(userRole);
        
      case UserPermission.deletePayments:
        return userRole == UserRole.admin;
        
      case UserPermission.viewReports:
        return [UserRole.admin, UserRole.cashier].contains(userRole);
        
      case UserPermission.manageUsers:
      case UserPermission.systemSettings:
        return userRole == UserRole.admin;
    }
  }

  // Verificar se é admin
  bool get isAdmin => currentUser.value?.role == UserRole.admin;
  
  // Verificar se é caixa
  bool get isCashier => currentUser.value?.role == UserRole.cashier;
  
  // Verificar se é operador de campo
  bool get isFieldOperator => currentUser.value?.role == UserRole.fieldOperator;

  // Atualizar perfil do usuário (localmente)
  Future<AuthResult> updateProfile(UserModel updatedUser) async {
    if (currentUser.value == null) {
      return AuthResult.error('Usuário não autenticado');
    }

    isLoading.value = true;

    try {
      updatedUser = updatedUser.copyWith(
        updatedAt: DateTime.now(),
      );
      
      final success = await _userRepository.update(updatedUser.id!, updatedUser);
      if (success) {
        currentUser.value = updatedUser;
        return AuthResult.success('Perfil atualizado com sucesso');
      }

      return AuthResult.error('Erro ao atualizar perfil');
    } catch (e) {
      return AuthResult.error('Erro ao atualizar perfil: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Alterar senha (localmente)
  Future<AuthResult> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    if (currentUser.value == null) {
      return AuthResult.error('Usuário não autenticado');
    }

    if (newPassword != confirmPassword) {
      return AuthResult.error('Senhas não coincidem');
    }

    if (newPassword.length < 6) {
      return AuthResult.error('Nova senha deve ter pelo menos 6 caracteres');
    }

    isLoading.value = true;

    try {
      // Verificar senha atual
      final user = await _userRepository.authenticate(
        currentUser.value!.email,
        currentPassword,
      );
      
      if (user == null) {
        return AuthResult.error('Senha atual incorreta');
      }

      // Atualizar com nova senha
      final updatedUser = currentUser.value!.copyWith(
        passwordHash: _hashPassword(newPassword),
        updatedAt: DateTime.now(),
      );

      final success = await _userRepository.update(updatedUser.id!, updatedUser);
      if (success) {
        currentUser.value = updatedUser;
        return AuthResult.success('Senha alterada com sucesso');
      }

      return AuthResult.error('Erro ao alterar senha');
    } catch (e) {
      return AuthResult.error('Erro ao alterar senha: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Hash da senha (mesmo método do UserRepository e DatabaseService)
  String _hashPassword(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Refresh dos dados do usuário
  Future<void> refreshUserData() async {
    if (!isLoggedIn.value || currentUser.value == null) return;

    try {
      final user = await _userRepository.findById(currentUser.value!.id!);
      if (user != null) {
        currentUser.value = user;
      }
    } catch (e) {
      print('Erro ao atualizar dados do usuário: $e');
    }
  }

  // Helpers privados para autenticação local
  Future<String?> _getStoredUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('current_user_id');
  }

  Future<void> _storeUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_user_id', userId);
  }

  Future<void> _clearStoredUserId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_user_id');
  }

  // Método para guard de rotas
  bool canAccessRoute(String route) {
    if (!isLoggedIn.value) return false;

    // Rotas públicas para usuários logados
    final publicRoutes = ['/dashboard', '/profile', '/help', '/about'];
    if (publicRoutes.contains(route)) return true;

    // Verificar permissões específicas por rota
    switch (route) {
      case '/clients':
        return hasPermission(UserPermission.viewClients);
      case '/clients/form':
        return hasPermission(UserPermission.createClients);
      case '/readings':
        return hasPermission(UserPermission.viewReadings);
      case '/readings/form':
        return hasPermission(UserPermission.createReadings);
      case '/payments':
        return hasPermission(UserPermission.viewPayments);
      case '/payments/form':
        return hasPermission(UserPermission.createPayments);
      case '/reports':
        return hasPermission(UserPermission.viewReports);
      case '/users':
        return hasPermission(UserPermission.manageUsers);
      case '/settings':
        return hasPermission(UserPermission.systemSettings);
      default:
        return false;
    }
  }
}

// Enum para permissões do sistema
enum UserPermission {
  // Clientes
  viewClients,
  createClients,
  editClients,
  deleteClients,
  
  // Leituras
  viewReadings,
  createReadings,
  editReadings,
  deleteReadings,
  
  // Pagamentos
  viewPayments,
  createPayments,
  editPayments,
  deletePayments,
  
  // Relatórios
  viewReports,
  
  // Sistema
  manageUsers,
  systemSettings,
}

// Classe para resultado de operações de auth
class AuthResult {
  final bool success;
  final String message;
  final dynamic data;

  AuthResult._({
    required this.success,
    required this.message,
    this.data,
  });

  factory AuthResult.success(String message, [dynamic data]) {
    return AuthResult._(success: true, message: message, data: data);
  }

  factory AuthResult.error(String message) {
    return AuthResult._(success: false, message: message);
  }

  bool get isSuccess => success;
  bool get isError => !success;
}