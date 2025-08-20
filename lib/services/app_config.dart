import 'package:vitalh2x/services/settings_service.dart';

class AppConfig {
  static const String appName = 'VitalH2X';
  static const String appVersion = '1.0.0';

  // API Configuration (substitui Supabase)
  static const String baseApiUrl = 'https://seu-dominio.com/api';
  static const String apiVersion = 'v1';
  static const String fullApiUrl = '$baseApiUrl/$apiVersion';
  
  // API Endpoints
  static const String loginEndpoint = '/auth/login';
  static const String refreshEndpoint = '/auth/refresh';
  static const String logoutEndpoint = '/auth/logout';
  static const String meEndpoint = '/auth/me';
  
  // Entity Endpoints
  static const String clientsEndpoint = '/clients';
  static const String readingsEndpoint = '/readings';
  static const String paymentsEndpoint = '/payments';
  static const String usersEndpoint = '/users';
  static const String syncEndpoint = '/sync';
  
  // Local Database Configuration
  static const String databaseName = 'water_management.db';
  static const int databaseVersion = 6;

  // App Settings (agora dinâmicos via SettingsService)
  @Deprecated('Use SettingsService.instance.getPricePerCubicMeter() instead')
  static const double pricePerCubicMeter = 50.0;
  
  static const String currency = 'MT'; // Meticais
  
  // Dynamic settings methods
  static Future<double> getPricePerCubicMeter() async {
    return await SettingsService.instance.getPricePerCubicMeter();
  }
  
  static Future<int> getReadingDay() async {
    return await SettingsService.instance.getReadingDay();
  }
  
  static Future<String> getCompanyName() async {
    return await SettingsService.instance.getCompanyName();
  }
  
  static Future<String> getCompanyAddress() async {
    return await SettingsService.instance.getCompanyAddress();
  }
  
  static Future<String> getCompanyPhone() async {
    return await SettingsService.instance.getCompanyPhone();
  }

  // HTTP Settings
  static const int connectionTimeout = 30000; // 30 segundos
  static const int receiveTimeout = 30000; // 30 segundos
  static const int sendTimeout = 30000; // 30 segundos
  
  // Token Settings
  static const String tokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userDataKey = 'user_data';
  
  // Sync Settings
  static const int syncInterval = 300000; // 5 minutos
  static const int maxRetries = 3;
  static const int retryDelay = 2000; // 2 segundos

  // Printing Settings
  static const String companyName = 'Sua Empresa de Água';
  static const String companyAddress = 'Endereço da Empresa';
  static const String companyPhone = 'Telefone da Empresa';
  
  // Helper methods para construir URLs
  static String get apiUrl => fullApiUrl;
  
  static String buildUrl(String endpoint) => '$fullApiUrl$endpoint';
  
  static String buildClientUrl(String? id) => 
    id != null ? '$fullApiUrl$clientsEndpoint/$id' : '$fullApiUrl$clientsEndpoint';
    
  static String buildReadingUrl(String? id) => 
    id != null ? '$fullApiUrl$readingsEndpoint/$id' : '$fullApiUrl$readingsEndpoint';
    
  static String buildPaymentUrl(String? id) => 
    id != null ? '$fullApiUrl$paymentsEndpoint/$id' : '$fullApiUrl$paymentsEndpoint';
    
  static String buildUserUrl(String? id) => 
    id != null ? '$fullApiUrl$usersEndpoint/$id' : '$fullApiUrl$usersEndpoint';
}
