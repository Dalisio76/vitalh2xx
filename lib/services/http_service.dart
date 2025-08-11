import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitalh2x/services/app_config.dart';

class HttpService {
  static late Dio _dio;
  static bool _isInitialized = false;

  static Future<void> initialize() async {
    if (_isInitialized) return;

    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.apiUrl,
      connectTimeout: Duration(milliseconds: AppConfig.connectionTimeout),
      receiveTimeout: Duration(milliseconds: AppConfig.receiveTimeout),
      sendTimeout: Duration(milliseconds: AppConfig.sendTimeout),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    _setupInterceptors();
    _isInitialized = true;
  }

  static void _setupInterceptors() {
    // Interceptor para adicionar token automaticamente
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onResponse: (response, handler) {
        handler.next(response);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          // Token expirado - tentar refresh
          final refreshed = await _refreshToken();
          if (refreshed) {
            // Retry request com novo token
            final token = await _getToken();
            error.requestOptions.headers['Authorization'] = 'Bearer $token';
            final response = await _dio.fetch(error.requestOptions);
            handler.resolve(response);
            return;
          } else {
            // Logout se não conseguir refresh
            await _clearAuthData();
          }
        }
        handler.next(error);
      },
    ));

    // Interceptor para logs (apenas em desenvolvimento)
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      requestHeader: false,
      responseHeader: false,
      error: true,
    ));
  }

  // Métodos HTTP principais
  static Future<ApiResponse<T>> get<T>(String endpoint) async {
    await _ensureInitialized();
    try {
      final response = await _dio.get(endpoint);
      return _handleResponse<T>(response);
    } catch (e) {
      return _handleError<T>(e);
    }
  }

  static Future<ApiResponse<T>> post<T>(String endpoint, dynamic data) async {
    await _ensureInitialized();
    try {
      final response = await _dio.post(endpoint, data: data);
      return _handleResponse<T>(response);
    } catch (e) {
      return _handleError<T>(e);
    }
  }

  static Future<ApiResponse<T>> put<T>(String endpoint, dynamic data) async {
    await _ensureInitialized();
    try {
      final response = await _dio.put(endpoint, data: data);
      return _handleResponse<T>(response);
    } catch (e) {
      return _handleError<T>(e);
    }
  }

  static Future<ApiResponse<T>> delete<T>(String endpoint) async {
    await _ensureInitialized();
    try {
      final response = await _dio.delete(endpoint);
      return _handleResponse<T>(response);
    } catch (e) {
      return _handleError<T>(e);
    }
  }

  // Método para upload de arquivos (futuro)
  static Future<ApiResponse<T>> postFormData<T>(
    String endpoint, 
    Map<String, dynamic> data,
  ) async {
    await _ensureInitialized();
    try {
      final formData = FormData.fromMap(data);
      final response = await _dio.post(endpoint, data: formData);
      return _handleResponse<T>(response);
    } catch (e) {
      return _handleError<T>(e);
    }
  }

  // Métodos de autenticação
  static Future<bool> login(String email, String password) async {
    try {
      final response = await post<Map<String, dynamic>>(
        AppConfig.loginEndpoint,
        {'email': email, 'password': password},
      );

      if (response.success && response.data != null) {
        await _saveAuthData(
          response.data!['token'],
          response.data!['refresh_token'],
          response.data!['user'],
        );
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> logout() async {
    try {
      await post(AppConfig.logoutEndpoint, {});
    } catch (e) {
      // Ignorar erro de logout no servidor
    } finally {
      await _clearAuthData();
    }
    return true;
  }

  static Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final response = await get<Map<String, dynamic>>(AppConfig.meEndpoint);
      return response.success ? response.data : null;
    } catch (e) {
      return null;
    }
  }

  // Método para verificar conectividade
  static Future<bool> hasConnection() async {
    try {
      final connectivityList = await Connectivity().checkConnectivity();
      return connectivityList.any((result) => result != ConnectivityResult.none);
    } catch (e) {
      print('Erro ao verificar conectividade: $e');
      return false;
    }
  }

  // Método para sync em lote
  static Future<ApiResponse<List<Map<String, dynamic>>>> syncBulk(
    Map<String, List<Map<String, dynamic>>> data,
  ) async {
    return await post<List<Map<String, dynamic>>>(
      '${AppConfig.syncEndpoint}/bulk',
      data,
    );
  }

  // Helpers internos
  static Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  static ApiResponse<T> _handleResponse<T>(Response response) {
    final data = response.data;
    
    if (data is Map<String, dynamic>) {
      return ApiResponse<T>(
        success: data['success'] ?? true,
        message: data['message'] ?? '',
        data: data['data'] as T?,
        meta: data['meta'] != null ? Map<String, dynamic>.from(data['meta']) : null,
      );
    }
    
    return ApiResponse<T>(
      success: true,
      message: 'Success',
      data: data as T?,
    );
  }

  static ApiResponse<T> _handleError<T>(dynamic error) {
    String message = 'Erro desconhecido';
    int? statusCode;
    Map<String, dynamic>? errorDetails;

    if (error is DioException) {
      statusCode = error.response?.statusCode;
      
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout) {
        message = 'Timeout na conexão';
      } else if (error.type == DioExceptionType.connectionError) {
        message = 'Erro de conexão';
      } else if (error.response?.data != null) {
        final responseData = error.response!.data;
        if (responseData is Map<String, dynamic>) {
          message = responseData['message'] ?? message;
          errorDetails = responseData['error'];
        }
      }
    } else if (error is SocketException) {
      message = 'Sem conexão com internet';
    }

    return ApiResponse<T>(
      success: false,
      message: message,
      statusCode: statusCode,
      errorDetails: errorDetails,
    );
  }

  // Gestão de tokens
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConfig.tokenKey);
  }

  static Future<String?> _getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConfig.refreshTokenKey);
  }

  static Future<void> _saveAuthData(
    String token,
    String refreshToken,
    Map<String, dynamic> userData,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConfig.tokenKey, token);
    await prefs.setString(AppConfig.refreshTokenKey, refreshToken);
    await prefs.setString(AppConfig.userDataKey, jsonEncode(userData));
  }

  static Future<void> _clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConfig.tokenKey);
    await prefs.remove(AppConfig.refreshTokenKey);
    await prefs.remove(AppConfig.userDataKey);
  }

  static Future<bool> _refreshToken() async {
    try {
      final refreshToken = await _getRefreshToken();
      if (refreshToken == null) return false;

      final response = await _dio.post(
        AppConfig.refreshEndpoint,
        data: {'refresh_token': refreshToken},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        await _saveAuthData(
          response.data['data']['token'],
          response.data['data']['refresh_token'],
          response.data['data']['user'],
        );
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Método para verificar se está autenticado
  static Future<bool> isAuthenticated() async {
    final token = await _getToken();
    return token != null;
  }

  // Método para obter dados do usuário salvos
  static Future<Map<String, dynamic>?> getSavedUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString(AppConfig.userDataKey);
    if (userDataString != null) {
      return jsonDecode(userDataString);
    }
    return null;
  }
}

// Classe para padronizar respostas da API
class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final Map<String, dynamic>? meta;
  final int? statusCode;
  final Map<String, dynamic>? errorDetails;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.meta,
    this.statusCode,
    this.errorDetails,
  });

  bool get hasError => !success;
  bool get hasData => data != null;
  
  @override
  String toString() {
    return 'ApiResponse(success: $success, message: $message, data: $data)';
  }
}