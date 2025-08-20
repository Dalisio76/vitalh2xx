// ===== UNIFIED PRINT SERVICE =====
// lib/services/print_service.dart

import 'dart:io';
import 'package:get/get.dart';
import 'package:sunmi_printer_plus/sunmi_printer_plus.dart';
import 'package:vitalh2x/services/settings_service.dart';
import 'package:vitalh2x/services/windows_print_service.dart';

class PrintService extends GetxService {
  static PrintService get instance => Get.find<PrintService>();
  
  // Services
  final SettingsService _settings = SettingsService.instance;
  final WindowsPrintService _windowsPrintService = WindowsPrintService.instance;
  
  // Observáveis
  final RxBool isInitialized = false.obs;
  final RxString lastError = ''.obs;
  final RxBool isPrinting = false.obs;
  final RxBool isSunmiDevice = false.obs;
  final RxString currentPrinterType = 'auto'.obs;
  
  @override
  Future<void> onInit() async {
    super.onInit();
    await initialize();
  }
  
  /// Inicializa o serviço de impressão
  Future<void> initialize() async {
    try {
      lastError.value = '';
      
      // Detectar tipo de dispositivo e definir printer type
      await _detectPrinterType();
      
      // Inicializar baseado no tipo detectado
      if (currentPrinterType.value == 'sunmi') {
        await _initializeSunmi();
      } else {
        await _initializeWindows();
      }
      
      isInitialized.value = true;
      print('PrintService inicializado: ${currentPrinterType.value}');
      
    } catch (e) {
      lastError.value = 'Erro ao inicializar: $e';
      print('Erro ao inicializar PrintService: $e');
      // Permitir uso mesmo com erro
      isInitialized.value = true;
    }
  }

  /// Detecta o tipo de impressora a usar
  Future<void> _detectPrinterType() async {
    try {
      // Primeiro verificar configuração do usuário
      final configuredType = await _settings.getPrinterType();
      
      if (configuredType == 'sunmi') {
        // Verificar se realmente é dispositivo Sunmi
        final isSunmi = await _checkSunmiDevice();
        if (isSunmi) {
          currentPrinterType.value = 'sunmi';
          isSunmiDevice.value = true;
          return;
        }
      }
      
      if (configuredType == 'windows') {
        if (Platform.isWindows) {
          currentPrinterType.value = 'windows';
          return;
        }
      }
      
      // Auto detection
      if (Platform.isAndroid) {
        final isSunmi = await _checkSunmiDevice();
        if (isSunmi) {
          currentPrinterType.value = 'sunmi';
          isSunmiDevice.value = true;
        } else {
          currentPrinterType.value = 'none';
        }
      } else if (Platform.isWindows) {
        currentPrinterType.value = 'windows';
      } else {
        currentPrinterType.value = 'none';
      }
      
    } catch (e) {
      print('Erro na detecção do tipo de impressora: $e');
      currentPrinterType.value = 'none';
    }
  }

  /// Verifica se é dispositivo Sunmi
  Future<bool> _checkSunmiDevice() async {
    try {
      return await SunmiPrinter.bindingPrinter() ?? false;
    } catch (e) {
      print('Erro ao verificar dispositivo Sunmi: $e');
      return false;
    }
  }

  /// Inicializa impressora Sunmi
  Future<void> _initializeSunmi() async {
    try {
      await SunmiPrinter.bindingPrinter();
      print('Impressora Sunmi inicializada');
    } catch (e) {
      print('Erro ao inicializar Sunmi: $e');
      throw e;
    }
  }

  /// Inicializa impressão Windows
  Future<void> _initializeWindows() async {
    try {
      // Verificar se há impressoras disponíveis
      final printers = await _windowsPrintService.getAvailablePrinters();
      print('Impressoras Windows encontradas: ${printers.length}');
      
      if (printers.isEmpty) {
        print('Nenhuma impressora Windows encontrada');
      }
    } catch (e) {
      print('Erro ao inicializar Windows printing: $e');
      throw e;
    }
  }
  
  /// Imprime recibo de leitura
  Future<bool> printReadingReceipt({
    required String clientName,
    required String reference,
    required double previousReading,
    required double currentReading,
    required double consumption,
    required double billAmount,
    required DateTime readingDate,
  }) async {
    try {
      isPrinting.value = true;
      lastError.value = '';
      
      // Verificar se impressão está habilitada
      final printingEnabled = await _settings.getEnablePrinting();
      if (!printingEnabled) {
        print('Impressão desabilitada nas configurações');
        return true; // Return true para não bloquear o fluxo
      }
      
      bool success = false;
      
      // Imprimir baseado no tipo configurado
      switch (currentPrinterType.value) {
        case 'sunmi':
          success = await _printReadingReceiptSunmi(
            clientName: clientName,
            reference: reference,
            previousReading: previousReading,
            currentReading: currentReading,
            consumption: consumption,
            billAmount: billAmount,
            readingDate: readingDate,
          );
          break;
          
        case 'windows':
          success = await _windowsPrintService.printReadingReceipt(
            clientName: clientName,
            reference: reference,
            previousReading: previousReading,
            currentReading: currentReading,
            consumption: consumption,
            billAmount: billAmount,
            readingDate: readingDate,
          );
          if (!success) {
            lastError.value = _windowsPrintService.lastError.value;
          }
          break;
          
        default:
          print('Simulando impressão de recibo de leitura para $clientName');
          success = true;
      }
      
      if (success) {
        print('Recibo de leitura impresso com sucesso');
      }
      
      return success;
      
    } catch (e) {
      lastError.value = 'Erro na impressão: $e';
      print('Erro ao imprimir recibo de leitura: $e');
      return false;
    } finally {
      isPrinting.value = false;
    }
  }
  
  /// Imprime recibo de pagamento
  Future<bool> printPaymentReceipt({
    required String clientName,
    required String reference,
    required double billAmount,
    required double paidAmount,
    required String paymentMethod,
    required DateTime paymentDate,
    String? notes,
  }) async {
    try {
      isPrinting.value = true;
      lastError.value = '';
      
      // Verificar se impressão está habilitada
      final printingEnabled = await _settings.getEnablePrinting();
      if (!printingEnabled) {
        print('Impressão desabilitada nas configurações');
        return true; // Return true para não bloquear o fluxo
      }
      
      bool success = false;
      
      // Imprimir baseado no tipo configurado
      switch (currentPrinterType.value) {
        case 'sunmi':
          success = await _printPaymentReceiptSunmi(
            clientName: clientName,
            reference: reference,
            billAmount: billAmount,
            paidAmount: paidAmount,
            paymentMethod: paymentMethod,
            paymentDate: paymentDate,
            notes: notes,
          );
          break;
          
        case 'windows':
          success = await _windowsPrintService.printPaymentReceipt(
            clientName: clientName,
            reference: reference,
            billAmount: billAmount,
            paidAmount: paidAmount,
            paymentMethod: paymentMethod,
            paymentDate: paymentDate,
            notes: notes,
          );
          if (!success) {
            lastError.value = _windowsPrintService.lastError.value;
          }
          break;
          
        default:
          print('Simulando impressão de recibo de pagamento para $clientName');
          success = true;
      }
      
      if (success) {
        print('Recibo de pagamento impresso com sucesso');
      }
      
      return success;
      
    } catch (e) {
      lastError.value = 'Erro na impressão: $e';
      print('Erro ao imprimir recibo de pagamento: $e');
      return false;
    } finally {
      isPrinting.value = false;
    }
  }
  
  /// Teste de impressão
  Future<bool> printTest() async {
    try {
      isPrinting.value = true;
      lastError.value = '';
      
      bool success = false;
      
      // Testar baseado no tipo configurado
      switch (currentPrinterType.value) {
        case 'sunmi':
          success = await _testPrintSunmi();
          break;
          
        case 'windows':
          success = await _windowsPrintService.testPrinter();
          if (!success) {
            lastError.value = _windowsPrintService.lastError.value;
          }
          break;
          
        default:
          print('Teste de impressão simulado');
          success = true;
      }
      
      if (success) {
        print('Teste de impressão realizado com sucesso');
      }
      
      return success;
      
    } catch (e) {
      lastError.value = 'Erro no teste: $e';
      print('Erro no teste de impressão: $e');
      return false;
    } finally {
      isPrinting.value = false;
    }
  }

  /// Get available printers (for Windows)
  Future<List<String>> getAvailablePrinters() async {
    if (Platform.isWindows) {
      return await _windowsPrintService.getAvailablePrinters();
    }
    return [];
  }

  /// Get current printer info
  Map<String, dynamic> getPrinterInfo() {
    return {
      'type': currentPrinterType.value,
      'isSunmiDevice': isSunmiDevice.value,
      'isInitialized': isInitialized.value,
      'lastError': lastError.value,
    };
  }
  
  // ===== MÉTODOS PRIVADOS =====
  
  /// Print reading receipt via SUNMI
  Future<bool> _printReadingReceiptSunmi({
    required String clientName,
    required String reference,
    required double previousReading,
    required double currentReading,
    required double consumption,
    required double billAmount,
    required DateTime readingDate,
  }) async {
    try {
      await SunmiPrinter.initPrinter();
      
      // Header
      await SunmiPrinter.bold();
      await SunmiPrinter.setAlignment(SunmiPrintAlign.CENTER);
      await SunmiPrinter.printText('RECIBO DE LEITURA');
      await SunmiPrinter.resetBold();
      await SunmiPrinter.lineWrap(1);
      
      await SunmiPrinter.printText('VitalH2X - Sistema de Água');
      await SunmiPrinter.lineWrap(2);
      
      // Company info
      final companyName = await _settings.getCompanyName();
      final companyAddress = await _settings.getCompanyAddress();
      final companyPhone = await _settings.getCompanyPhone();
      
      await SunmiPrinter.setAlignment(SunmiPrintAlign.LEFT);
      await SunmiPrinter.printText(companyName);
      await SunmiPrinter.lineWrap(1);
      await SunmiPrinter.printText(companyAddress);
      await SunmiPrinter.lineWrap(1);
      await SunmiPrinter.printText(companyPhone);
      await SunmiPrinter.lineWrap(2);
      
      // Client info
      await SunmiPrinter.printText('Cliente: $clientName');
      await SunmiPrinter.lineWrap(1);
      await SunmiPrinter.printText('Referência: $reference');
      await SunmiPrinter.lineWrap(1);
      await SunmiPrinter.printText('Data: ${_formatDate(readingDate)}');
      await SunmiPrinter.lineWrap(2);
      
      // Reading details
      await SunmiPrinter.bold();
      await SunmiPrinter.printText('CONSUMO:');
      await SunmiPrinter.resetBold();
      await SunmiPrinter.lineWrap(1);
      await SunmiPrinter.printText('Leitura anterior: ${previousReading.toStringAsFixed(1)} m³');
      await SunmiPrinter.lineWrap(1);
      await SunmiPrinter.printText('Leitura atual: ${currentReading.toStringAsFixed(1)} m³');
      await SunmiPrinter.lineWrap(1);
      await SunmiPrinter.printText('Consumo: ${consumption.toStringAsFixed(1)} m³');
      await SunmiPrinter.lineWrap(2);
      
      // Amount
      await SunmiPrinter.bold();
      await SunmiPrinter.setAlignment(SunmiPrintAlign.CENTER);
      await SunmiPrinter.printText('VALOR A PAGAR');
      await SunmiPrinter.lineWrap(1);
      await SunmiPrinter.printText('${billAmount.toStringAsFixed(2)} MT');
      await SunmiPrinter.resetBold();
      await SunmiPrinter.lineWrap(3);
      
      // Footer
      await SunmiPrinter.setAlignment(SunmiPrintAlign.CENTER);
      await SunmiPrinter.printText('Obrigado pela preferência!');
      await SunmiPrinter.lineWrap(3);
      
      await SunmiPrinter.cut();
      return true;
      
    } catch (e) {
      print('Erro na impressão SUNMI de leitura: $e');
      return false;
    }
  }

  /// Print payment receipt via SUNMI
  Future<bool> _printPaymentReceiptSunmi({
    required String clientName,
    required String reference,
    required double billAmount,
    required double paidAmount,
    required String paymentMethod,
    required DateTime paymentDate,
    String? notes,
  }) async {
    try {
      await SunmiPrinter.initPrinter();
      
      // Header
      await SunmiPrinter.bold();
      await SunmiPrinter.setAlignment(SunmiPrintAlign.CENTER);
      await SunmiPrinter.printText('RECIBO DE PAGAMENTO');
      await SunmiPrinter.resetBold();
      await SunmiPrinter.lineWrap(1);
      
      await SunmiPrinter.printText('VitalH2X - Sistema de Água');
      await SunmiPrinter.lineWrap(2);
      
      // Company info
      final companyName = await _settings.getCompanyName();
      final companyAddress = await _settings.getCompanyAddress();
      final companyPhone = await _settings.getCompanyPhone();
      
      await SunmiPrinter.setAlignment(SunmiPrintAlign.LEFT);
      await SunmiPrinter.printText(companyName);
      await SunmiPrinter.lineWrap(1);
      await SunmiPrinter.printText(companyAddress);
      await SunmiPrinter.lineWrap(1);
      await SunmiPrinter.printText(companyPhone);
      await SunmiPrinter.lineWrap(2);
      
      // Payment info
      await SunmiPrinter.printText('Cliente: $clientName');
      await SunmiPrinter.lineWrap(1);
      await SunmiPrinter.printText('Referência: $reference');
      await SunmiPrinter.lineWrap(1);
      await SunmiPrinter.printText('Data: ${_formatDate(paymentDate)}');
      await SunmiPrinter.lineWrap(1);
      await SunmiPrinter.printText('Hora: ${_formatTime(paymentDate)}');
      await SunmiPrinter.lineWrap(2);
      
      // Payment details
      await SunmiPrinter.bold();
      await SunmiPrinter.printText('PAGAMENTO:');
      await SunmiPrinter.resetBold();
      await SunmiPrinter.lineWrap(1);
      await SunmiPrinter.printText('Valor conta: ${billAmount.toStringAsFixed(2)} MT');
      await SunmiPrinter.lineWrap(1);
      await SunmiPrinter.printText('Valor pago: ${paidAmount.toStringAsFixed(2)} MT');
      await SunmiPrinter.lineWrap(1);
      
      final change = paidAmount - billAmount;
      if (change > 0) {
        await SunmiPrinter.printText('Troco: ${change.toStringAsFixed(2)} MT');
        await SunmiPrinter.lineWrap(1);
      }
      
      await SunmiPrinter.printText('Método: $paymentMethod');
      await SunmiPrinter.lineWrap(2);
      
      if (notes != null && notes.isNotEmpty) {
        await SunmiPrinter.printText('Obs: $notes');
        await SunmiPrinter.lineWrap(2);
      }
      
      // Status
      await SunmiPrinter.bold();
      await SunmiPrinter.setAlignment(SunmiPrintAlign.CENTER);
      await SunmiPrinter.printText('*** PAGAMENTO EFETUADO ***');
      await SunmiPrinter.lineWrap(1);
      await SunmiPrinter.printText('*** COM SUCESSO ***');
      await SunmiPrinter.resetBold();
      await SunmiPrinter.lineWrap(3);
      
      // Footer
      await SunmiPrinter.printText('Obrigado pela preferência!');
      await SunmiPrinter.lineWrap(3);
      
      await SunmiPrinter.cut();
      return true;
      
    } catch (e) {
      print('Erro na impressão SUNMI de pagamento: $e');
      return false;
    }
  }

  /// Test print via SUNMI
  Future<bool> _testPrintSunmi() async {
    try {
      await SunmiPrinter.initPrinter();
      
      await SunmiPrinter.bold();
      await SunmiPrinter.setAlignment(SunmiPrintAlign.CENTER);
      await SunmiPrinter.printText('TESTE DE IMPRESSÃO');
      await SunmiPrinter.resetBold();
      await SunmiPrinter.lineWrap(2);
      
      await SunmiPrinter.setAlignment(SunmiPrintAlign.LEFT);
      await SunmiPrinter.printText('VitalH2X - Sistema de Água');
      await SunmiPrinter.lineWrap(1);
      await SunmiPrinter.printText('Data: ${_formatDate(DateTime.now())}');
      await SunmiPrinter.lineWrap(1);
      await SunmiPrinter.printText('Hora: ${_formatTime(DateTime.now())}');
      await SunmiPrinter.lineWrap(2);
      
      await SunmiPrinter.printText('Se você está vendo esta mensagem,');
      await SunmiPrinter.lineWrap(1);
      await SunmiPrinter.printText('a impressora está funcionando');
      await SunmiPrinter.lineWrap(1);
      await SunmiPrinter.printText('corretamente!');
      await SunmiPrinter.lineWrap(3);
      
      await SunmiPrinter.cut();
      return true;
      
    } catch (e) {
      print('Erro no teste SUNMI: $e');
      return false;
    }
  }

  
  /// Formatar data
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
  
  /// Formatar hora
  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
  
  @override
  void onClose() {
    print('PrintService finalizado');
    super.onClose();
  }
}