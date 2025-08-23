// ===== AUTH CONTROLLER =====
// lib/app/controllers/auth_controller.dart

import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitalh2x/controlers/base_controler.dart';
import 'package:vitalh2x/models/usuario_model.dart';
import 'package:vitalh2x/repository/user_repository.dart';
import 'package:vitalh2x/services/database_providers.dart';

class AuthController extends BaseController {
  final UserRepository _userRepository = UserRepository(
    SQLiteDatabaseProvider(),
  );

  // Current user
  final Rx<UserModel?> _currentUser = Rx<UserModel?>(null);
  UserModel? get currentUser => _currentUser.value;
  bool get isLoggedIn => _currentUser.value != null;

  // Form fields
  final RxString email = ''.obs;
  final RxString password = ''.obs;
  final RxBool rememberMe = false.obs;

  @override
  void onInit() {
    super.onInit();
    _checkAutoLogin();
  }

  // Check for auto login
  Future<void> _checkAutoLogin() async {
    try {
      // Aguardar um pouco para garantir que o banco esteja inicializado
      await Future.delayed(Duration(milliseconds: 500));
      
      final prefs = await SharedPreferences.getInstance();
      final savedUserId = prefs.getString('current_user_id');

      if (savedUserId != null) {
        print('🔍 AUTO LOGIN - Tentando com ID: $savedUserId');
        // Buscar usuário no banco local
        final user = await _userRepository.findById(savedUserId);
        if (user != null && user.isActive) {
          print('✅ AUTO LOGIN - Usuário encontrado: ${user.name}');
          _currentUser.value = user;
          rememberMe.value = true;
          Get.offAllNamed('/home');
        } else {
          print('❌ AUTO LOGIN - Usuário inválido, limpando dados');
          // Usuário inválido, limpar dados salvos
          await _clearSavedCredentials();
        }
      } else {
        print('🔍 AUTO LOGIN - Nenhum usuário salvo encontrado');
      }
    } catch (e) {
      print('❌ AUTO LOGIN - Erro: $e');
      await _clearSavedCredentials();
    }
  }

  // Login
  Future<void> login({bool autoLogin = false}) async {
    try {
      if (!autoLogin) {
        if (email.value.isEmpty || password.value.isEmpty) {
          showError('Por favor, preencha todos os campos');
          return;
        }
        showLoading('Fazendo login...');
      }

      final user = await _userRepository.authenticate(
        email.value.trim(),
        password.value,
      );

      if (user == null) {
        showError('Email ou senha incorretos');
        return;
      }

      if (!user.isActive) {
        showError('Usuário desativado. Contacte o administrador');
        return;
      }

      _currentUser.value = user;

      // Save user session if remember me is checked
      if (rememberMe.value) {
        await _saveUserSession(user.id!);
      } else {
        await _clearSavedCredentials();
      }

      hideLoading();

      if (!autoLogin) {
        showSuccess('Login realizado com sucesso!');
        Get.offAllNamed('/home');
      } else {
        Get.offAllNamed('/home');
      }
    } catch (e) {
      handleException(e);
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      showLoading('Fazendo logout...');

      // Clear saved credentials if not remember me
      if (!rememberMe.value) {
        await _clearSavedCredentials();
      }

      _currentUser.value = null;
      email.value = '';
      password.value = '';

      hideLoading();
      Get.offAllNamed('/login');
      showSuccess('Logout realizado com sucesso!');
    } catch (e) {
      handleException(e);
    }
  }

  // Save user session
  Future<void> _saveUserSession(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_user_id', userId);
      await prefs.setString('saved_email', email.value);
      // Não salvar senha em texto plano por segurança
    } catch (e) {
      print('Error saving user session: $e');
    }
  }

  // Clear saved credentials
  Future<void> _clearSavedCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('current_user_id');
      await prefs.remove('saved_email');
      await prefs.remove('saved_password'); // Para compatibilidade
    } catch (e) {
      print('Error clearing credentials: $e');
    }
  }

  // Check user permissions
  bool canRegisterPayments() {
    return currentUser?.canRegisterPayments ?? false;
  }

  bool canRegisterClients() {
    return currentUser?.canRegisterClients ?? false;
  }

  bool canOnlyReadMeters() {
    return currentUser?.canOnlyReadMeters ?? false;
  }

  bool isAdmin() {
    return currentUser?.isAdmin ?? false;
  }

  // Validate fields
  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email é obrigatório';
    }
    if (!GetUtils.isEmail(value)) {
      return 'Email inválido';
    }
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Senha é obrigatória';
    }
    if (value.length < 3) {
      return 'Senha deve ter pelo menos 3 caracteres';
    }
    return null;
  }
}
