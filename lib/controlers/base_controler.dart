// ===== BASE CONTROLLER =====
// lib/app/controllers/base_controller.dart

import 'package:get/get.dart';

abstract class BaseController extends GetxController {
  // Loading states
  final RxBool _isLoading = false.obs;
  final RxString _loadingMessage = ''.obs;

  bool get isLoading => _isLoading.value;
  String get loadingMessage => _loadingMessage.value;

  // Error handling
  final RxString _errorMessage = ''.obs;
  String get errorMessage => _errorMessage.value;
  bool get hasError => _errorMessage.value.isNotEmpty;

  // Success messages
  final RxString _successMessage = ''.obs;
  String get successMessage => _successMessage.value;
  bool get hasSuccess => _successMessage.value.isNotEmpty;

  // Loading management
  void showLoading([String? message]) {
    _isLoading.value = true;
    _loadingMessage.value = message ?? 'Carregando...';
    _errorMessage.value = '';
    _successMessage.value = '';
  }

  void hideLoading() {
    _isLoading.value = false;
    _loadingMessage.value = '';
  }

  // Error management
  void showError(String message) {
    hideLoading();
    _errorMessage.value = message;
    _successMessage.value = '';
    Get.snackbar(
      'Erro',
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Get.theme.colorScheme.error,
      colorText: Get.theme.colorScheme.onError,
    );
  }

  // Success management
  void showSuccess(String message) {
    hideLoading();
    _successMessage.value = message;
    _errorMessage.value = '';
    Get.snackbar(
      'Sucesso',
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Get.theme.primaryColor,
      colorText: Get.theme.colorScheme.onPrimary,
    );
  }

  // Clear messages
  void clearMessages() {
    _errorMessage.value = '';
    _successMessage.value = '';
  }

  // Handle exceptions
  void handleException(dynamic error) {
    hideLoading();
    print('Controller Error: $error');

    String message = 'Ocorreu um erro inesperado';
    if (error is Exception) {
      message = error.toString().replaceAll('Exception: ', '');
    } else if (error is String) {
      message = error;
    }

    showError(message);
  }
}
