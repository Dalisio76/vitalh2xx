// ===== SETTINGS SERVICE =====
// Serviço para gerenciar configurações dinâmicas do app

import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _pricePerCubicMeterKey = 'price_per_cubic_meter';
  static const String _companyNameKey = 'company_name';
  static const String _companyAddressKey = 'company_address';
  static const String _companyPhoneKey = 'company_phone';
  static const String _readingDayKey = 'reading_day';
  static const String _taxRateKey = 'tax_rate';
  static const String _minimumChargeKey = 'minimum_charge';
  static const String _printerNameKey = 'printer_name';
  static const String _printerTypeKey = 'printer_type';
  static const String _enablePrintingKey = 'enable_printing';

  // Valores padrão
  static const double _defaultPricePerCubicMeter = 50.0;
  static const String _defaultCompanyName = 'VitalH2X - Sistema de Água';
  static const String _defaultCompanyAddress = 'Endereço da Empresa';
  static const String _defaultCompanyPhone = '+258 XXX XXXX';
  static const int _defaultReadingDay = 20;
  static const double _defaultTaxRate = 0.0;
  static const double _defaultMinimumCharge = 0.0;
  static const String _defaultPrinterName = '';
  static const String _defaultPrinterType = 'windows';
  static const bool _defaultEnablePrinting = true;

  // Singleton
  static SettingsService? _instance;
  static SettingsService get instance => _instance ??= SettingsService._();
  SettingsService._();

  SharedPreferences? _prefs;

  // Initialize
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // ===== PRICE SETTINGS =====
  
  /// Get price per cubic meter
  Future<double> getPricePerCubicMeter() async {
    await init();
    return _prefs?.getDouble(_pricePerCubicMeterKey) ?? _defaultPricePerCubicMeter;
  }

  /// Set price per cubic meter
  Future<void> setPricePerCubicMeter(double price) async {
    await init();
    await _prefs?.setDouble(_pricePerCubicMeterKey, price);
  }

  // ===== COMPANY SETTINGS =====

  /// Get company name
  Future<String> getCompanyName() async {
    await init();
    return _prefs?.getString(_companyNameKey) ?? _defaultCompanyName;
  }

  /// Set company name
  Future<void> setCompanyName(String name) async {
    await init();
    await _prefs?.setString(_companyNameKey, name);
  }

  /// Get company address
  Future<String> getCompanyAddress() async {
    await init();
    return _prefs?.getString(_companyAddressKey) ?? _defaultCompanyAddress;
  }

  /// Set company address
  Future<void> setCompanyAddress(String address) async {
    await init();
    await _prefs?.setString(_companyAddressKey, address);
  }

  /// Get company phone
  Future<String> getCompanyPhone() async {
    await init();
    return _prefs?.getString(_companyPhoneKey) ?? _defaultCompanyPhone;
  }

  /// Set company phone
  Future<void> setCompanyPhone(String phone) async {
    await init();
    await _prefs?.setString(_companyPhoneKey, phone);
  }

  // ===== BILLING SETTINGS =====

  /// Get reading day
  Future<int> getReadingDay() async {
    await init();
    return _prefs?.getInt(_readingDayKey) ?? _defaultReadingDay;
  }

  /// Set reading day
  Future<void> setReadingDay(int day) async {
    await init();
    await _prefs?.setInt(_readingDayKey, day);
  }

  /// Get tax rate (percentage)
  Future<double> getTaxRate() async {
    await init();
    return _prefs?.getDouble(_taxRateKey) ?? _defaultTaxRate;
  }

  /// Set tax rate (percentage)
  Future<void> setTaxRate(double rate) async {
    await init();
    await _prefs?.setDouble(_taxRateKey, rate);
  }

  /// Get minimum charge
  Future<double> getMinimumCharge() async {
    await init();
    return _prefs?.getDouble(_minimumChargeKey) ?? _defaultMinimumCharge;
  }

  /// Set minimum charge
  Future<void> setMinimumCharge(double charge) async {
    await init();
    await _prefs?.setDouble(_minimumChargeKey, charge);
  }

  // ===== PRINTER SETTINGS =====

  /// Get printer name
  Future<String> getPrinterName() async {
    await init();
    return _prefs?.getString(_printerNameKey) ?? _defaultPrinterName;
  }

  /// Set printer name
  Future<void> setPrinterName(String printerName) async {
    await init();
    await _prefs?.setString(_printerNameKey, printerName);
  }

  /// Get printer type (sunmi, windows, etc.)
  Future<String> getPrinterType() async {
    await init();
    return _prefs?.getString(_printerTypeKey) ?? _defaultPrinterType;
  }

  /// Set printer type
  Future<void> setPrinterType(String printerType) async {
    await init();
    await _prefs?.setString(_printerTypeKey, printerType);
  }

  /// Get printing enabled status
  Future<bool> getEnablePrinting() async {
    await init();
    return _prefs?.getBool(_enablePrintingKey) ?? _defaultEnablePrinting;
  }

  /// Set printing enabled status
  Future<void> setEnablePrinting(bool enabled) async {
    await init();
    await _prefs?.setBool(_enablePrintingKey, enabled);
  }

  // ===== UTILITY METHODS =====

  /// Calculate bill amount with current settings
  Future<double> calculateBillAmount(double consumption) async {
    final pricePerCubicMeter = await getPricePerCubicMeter();
    final minimumCharge = await getMinimumCharge();
    final taxRate = await getTaxRate();

    double baseAmount = consumption * pricePerCubicMeter;
    
    // Apply minimum charge if applicable
    if (baseAmount < minimumCharge) {
      baseAmount = minimumCharge;
    }

    // Apply tax
    double taxAmount = baseAmount * (taxRate / 100);
    
    return baseAmount + taxAmount;
  }

  /// Reset all settings to default
  Future<void> resetToDefaults() async {
    await init();
    await _prefs?.setDouble(_pricePerCubicMeterKey, _defaultPricePerCubicMeter);
    await _prefs?.setString(_companyNameKey, _defaultCompanyName);
    await _prefs?.setString(_companyAddressKey, _defaultCompanyAddress);
    await _prefs?.setString(_companyPhoneKey, _defaultCompanyPhone);
    await _prefs?.setInt(_readingDayKey, _defaultReadingDay);
    await _prefs?.setDouble(_taxRateKey, _defaultTaxRate);
    await _prefs?.setDouble(_minimumChargeKey, _defaultMinimumCharge);
    await _prefs?.setString(_printerNameKey, _defaultPrinterName);
    await _prefs?.setString(_printerTypeKey, _defaultPrinterType);
    await _prefs?.setBool(_enablePrintingKey, _defaultEnablePrinting);
  }

  /// Export all settings
  Future<Map<String, dynamic>> exportSettings() async {
    return {
      'price_per_cubic_meter': await getPricePerCubicMeter(),
      'company_name': await getCompanyName(),
      'company_address': await getCompanyAddress(),
      'company_phone': await getCompanyPhone(),
      'reading_day': await getReadingDay(),
      'tax_rate': await getTaxRate(),
      'minimum_charge': await getMinimumCharge(),
      'printer_name': await getPrinterName(),
      'printer_type': await getPrinterType(),
      'enable_printing': await getEnablePrinting(),
    };
  }

  /// Import settings from map
  Future<void> importSettings(Map<String, dynamic> settings) async {
    if (settings['price_per_cubic_meter'] != null) {
      await setPricePerCubicMeter(settings['price_per_cubic_meter'].toDouble());
    }
    if (settings['company_name'] != null) {
      await setCompanyName(settings['company_name']);
    }
    if (settings['company_address'] != null) {
      await setCompanyAddress(settings['company_address']);
    }
    if (settings['company_phone'] != null) {
      await setCompanyPhone(settings['company_phone']);
    }
    if (settings['reading_day'] != null) {
      await setReadingDay(settings['reading_day'].toInt());
    }
    if (settings['tax_rate'] != null) {
      await setTaxRate(settings['tax_rate'].toDouble());
    }
    if (settings['minimum_charge'] != null) {
      await setMinimumCharge(settings['minimum_charge'].toDouble());
    }
    if (settings['printer_name'] != null) {
      await setPrinterName(settings['printer_name']);
    }
    if (settings['printer_type'] != null) {
      await setPrinterType(settings['printer_type']);
    }
    if (settings['enable_printing'] != null) {
      await setEnablePrinting(settings['enable_printing']);
    }
  }
}