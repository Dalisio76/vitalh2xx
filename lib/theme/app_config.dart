// ===== APP CONFIG =====
// lib/core/config/app_config.dart

class AppConfig {
  static const String appName = 'Water Management System';
  static const String appVersion = '1.0.0';

  // Database Configuration
  static const String databaseName = 'water_management.db';
  static const int databaseVersion = 1;

  // App Settings
  static const double pricePerCubicMeter = 50.0;
  static const int readingDay = 20; // Dia 20 de cada mês

  // Company Info
  static const String companyName = 'Sua Empresa de Água';
  static const String companyAddress = 'Maputo, Moçambique';
  static const String companyPhone = '+258 84 000 0000';

  // Default Admin Credentials
  static const String defaultAdminEmail = 'admin@waterSystem.local';
  static const String defaultAdminPassword = 'admin123';
}
