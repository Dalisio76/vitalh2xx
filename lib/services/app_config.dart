class AppConfig {
  static const String appName = 'Water Management System';
  static const String appVersion = '1.0.0';

  // Supabase Configuration
  static const String supabaseUrl = 'https://vficleycgxwdhsigcatz.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZmaWNsZXljZ3h3ZGhzaWdjYXR6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQzOTQ4NjUsImV4cCI6MjA2OTk3MDg2NX0.jXo_8wEqtt-hno794el5Xmc0SfsjKRxMAim4oLyZ3_U';

  // Database Configuration
  static const String databaseName = 'water_management.db';
  static const int databaseVersion = 1;

  // App Settings
  static const double pricePerCubicMeter = 50.0;
  static const int readingDay = 20; // Dia 20 de cada mês

  // Printing Settings
  static const String companyName = 'Sua Empresa de Água';
  static const String companyAddress = 'Endereço da Empresa';
  static const String companyPhone = 'Telefone da Empresa';
}
