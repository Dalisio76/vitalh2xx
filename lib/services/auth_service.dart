import 'dart:convert';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitalh2x/models/usuario_model.dart';
import 'package:vitalh2x/services/app_config.dart';
import 'package:vitalh2x/services/http_service.dart';

class AuthService extends GetxController {
  // Estado reativo do usuário
  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);
  final RxBool isLoggedIn = false.obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    _initializeAuth();
  }

  // Inicializar autenticação ao abrir app
  Future<void> _initializeAuth() async {
    isLoading.value = true;
    
    try {
      // Verificar se tem token salvo
      final token = await _getStoredToken();
      if (token != null) {
        // Verificar se token ainda é válido
        final userData = await HttpService.getCurrentUser();
        if (userData != null) {
          currentUser.value = UserModel.fromJson(userData);
          isLoggedIn.value = true;
        } else {
          // Token inválido, limpar dados
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
      final success = await HttpService.login(email, password);
      
      if (success) {
        // Buscar dados atualizados do usuário
        final userData = await HttpService.getCurrentUser();
        if (userData != null) {
          currentUser.value = UserModel.fromJson(userData);
          isLoggedIn.value = true;
          
          // Salvar último login
          await _updateLastLogin();
          
          return AuthResult.success('Login realizado com sucesso');
        }
      }
      
      return AuthResult.error('Credenciais inválidas');
    } catch (e) {
      return AuthResult.error('Erro de conexão: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Logout do usuário
  Future<void> logout() async {
    isLoading.value = true;

    try {
      // Fazer logout no servidor
      await HttpService.logout();
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

  // Atualizar perfil do usuário
  Future<AuthResult> updateProfile(Map<String, dynamic> data) async {
    if (currentUser.value == null) {
      return AuthResult.error('Usuário não autenticado');
    }

    isLoading.value = true;

    try {
      final response = await HttpService.put<Map<String, dynamic>>(
        AppConfig.buildUserUrl(currentUser.value!.id),
        data,
      );

      if (response.success && response.data != null) {
        currentUser.value = UserModel.fromJson(response.data!);
        return AuthResult.success('Perfil atualizado com sucesso');
      }

      return AuthResult.error(response.message);
    } catch (e) {
      return AuthResult.error('Erro ao atualizar perfil: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Alterar senha
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
      final response = await HttpService.put<Map<String, dynamic>>(
        '${AppConfig.buildUserUrl(currentUser.value!.id)}/change-password',
        {
          'current_password': currentPassword,
          'new_password': newPassword,
          'confirm_password': confirmPassword,
        },
      );

      if (response.success) {
        return AuthResult.success('Senha alterada com sucesso');
      }

      return AuthResult.error(response.message);
    } catch (e) {
      return AuthResult.error('Erro ao alterar senha: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Refresh dos dados do usuário
  Future<void> refreshUserData() async {
    if (!isLoggedIn.value) return;

    try {
      final userData = await HttpService.getCurrentUser();
      if (userData != null) {
        currentUser.value = UserModel.fromJson(userData);
      }
    } catch (e) {
      print('Erro ao atualizar dados do usuário: $e');
    }
  }

  // Helpers privados
  Future<String?> _getStoredToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConfig.tokenKey);
  }

  Future<void> _updateLastLogin() async {
    try {
      await HttpService.put<Map<String, dynamic>>(
        '${AppConfig.buildUserUrl(currentUser.value!.id)}/last-login',
        {'last_login': DateTime.now().toIso8601String()},
      );
    } catch (e) {
      print('Erro ao atualizar último login: $e');
    }
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