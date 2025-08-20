// ===== WINDOWS PRINT SERVICE =====
// Serviço para impressão em impressoras Windows por nome

import 'dart:io';
import 'dart:convert';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:vitalh2x/services/settings_service.dart';

class WindowsPrintService {
  static WindowsPrintService? _instance;
  static WindowsPrintService get instance => _instance ??= WindowsPrintService._();
  WindowsPrintService._();

  final SettingsService _settings = SettingsService.instance;
  final RxString lastError = ''.obs;
  final RxBool isInitialized = true.obs; // Windows printing sempre disponível

  /// Get list of available printers
  Future<List<String>> getAvailablePrinters() async {
    try {
      if (!Platform.isWindows) return [];

      // Usar PowerShell para listar impressoras
      final result = await Process.run(
        'powershell',
        ['-Command', 'Get-Printer | Select-Object -ExpandProperty Name'],
        runInShell: true,
      );

      if (result.exitCode == 0) {
        final printers = result.stdout
            .toString()
            .split('\n')
            .where((line) => line.trim().isNotEmpty)
            .map((line) => line.trim())
            .toList();
        
        return printers;
      } else {
        lastError.value = 'Erro ao listar impressoras: ${result.stderr}';
        return [];
      }
    } catch (e) {
      lastError.value = 'Erro ao acessar impressoras: $e';
      return [];
    }
  }

  /// Check if printer exists by name
  Future<bool> printerExists(String printerName) async {
    if (printerName.isEmpty) return false;
    
    final printers = await getAvailablePrinters();
    return printers.any((name) => 
        name.toLowerCase() == printerName.toLowerCase());
  }

  /// Get default printer name
  Future<String?> getDefaultPrinter() async {
    try {
      if (!Platform.isWindows) return null;

      final result = await Process.run(
        'powershell',
        ['-Command', 'Get-CimInstance -Class Win32_Printer | Where-Object { \$_.Default -eq \$true } | Select-Object -ExpandProperty Name'],
        runInShell: true,
      );

      if (result.exitCode == 0) {
        final defaultPrinter = result.stdout.toString().trim();
        return defaultPrinter.isNotEmpty ? defaultPrinter : null;
      }
      
      return null;
    } catch (e) {
      print('Erro ao obter impressora padrão: $e');
      return null;
    }
  }

  /// Print text content to specific printer
  Future<bool> printText({
    required String content,
    String? printerName,
    String jobName = 'VitalH2X Print Job',
  }) async {
    try {
      if (!Platform.isWindows) {
        lastError.value = 'Impressão Windows disponível apenas no Windows';
        return false;
      }

      // Get printer name from settings if not provided
      printerName ??= await _settings.getPrinterName();
      
      if (printerName.isEmpty) {
        // Try to use default printer
        printerName = await getDefaultPrinter();
        if (printerName == null || printerName.isEmpty) {
          lastError.value = 'Nenhuma impressora configurada ou padrão encontrada';
          return false;
        }
      }

      // Verify printer exists
      if (!await printerExists(printerName)) {
        lastError.value = 'Impressora "$printerName" não encontrada no sistema';
        return false;
      }

      // Create temporary file with content
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}\\vitalh2x_print_${DateTime.now().millisecondsSinceEpoch}.txt');
      
      await tempFile.writeAsString(content, encoding: utf8);

      // Print using Windows command
      final result = await Process.run(
        'powershell',
        [
          '-Command',
          'Get-Content "${tempFile.path}" | Out-Printer -Name "$printerName"'
        ],
        runInShell: true,
      );

      // Clean up temp file
      try {
        if (await tempFile.exists()) {
          await tempFile.delete();
        }
      } catch (e) {
        // Ignore cleanup errors
      }

      if (result.exitCode == 0) {
        return true;
      } else {
        lastError.value = 'Erro na impressão: ${result.stderr}';
        return false;
      }
    } catch (e) {
      lastError.value = 'Erro ao imprimir: $e';
      return false;
    }
  }

  /// Print payment receipt
  Future<bool> printPaymentReceipt({
    required String clientName,
    required String reference,
    required double billAmount,
    required double paidAmount,
    required String paymentMethod,
    required DateTime paymentDate,
    String? notes,
  }) async {
    final companyName = await _settings.getCompanyName();
    final companyAddress = await _settings.getCompanyAddress();
    final companyPhone = await _settings.getCompanyPhone();
    
    final content = _buildPaymentReceiptContent(
      companyName: companyName,
      companyAddress: companyAddress,
      companyPhone: companyPhone,
      clientName: clientName,
      reference: reference,
      billAmount: billAmount,
      paidAmount: paidAmount,
      paymentMethod: paymentMethod,
      paymentDate: paymentDate,
      notes: notes,
    );

    return await printText(
      content: content,
      jobName: 'Recibo Pagamento - $clientName',
    );
  }

  /// Print reading receipt
  Future<bool> printReadingReceipt({
    required String clientName,
    required String reference,
    required double previousReading,
    required double currentReading,
    required double consumption,
    required double billAmount,
    required DateTime readingDate,
  }) async {
    final companyName = await _settings.getCompanyName();
    final companyAddress = await _settings.getCompanyAddress();
    final companyPhone = await _settings.getCompanyPhone();
    
    final content = _buildReadingReceiptContent(
      companyName: companyName,
      companyAddress: companyAddress,
      companyPhone: companyPhone,
      clientName: clientName,
      reference: reference,
      previousReading: previousReading,
      currentReading: currentReading,
      consumption: consumption,
      billAmount: billAmount,
      readingDate: readingDate,
    );

    return await printText(
      content: content,
      jobName: 'Recibo Leitura - $clientName',
    );
  }

  /// Build payment receipt content
  String _buildPaymentReceiptContent({
    required String companyName,
    required String companyAddress,
    required String companyPhone,
    required String clientName,
    required String reference,
    required double billAmount,
    required double paidAmount,
    required String paymentMethod,
    required DateTime paymentDate,
    String? notes,
  }) {
    final buffer = StringBuffer();
    
    // Header
    buffer.writeln('=' * 48);
    buffer.writeln('           RECIBO DE PAGAMENTO');
    buffer.writeln('=' * 48);
    buffer.writeln();
    
    // Company info
    buffer.writeln(companyName);
    buffer.writeln(companyAddress);
    buffer.writeln(companyPhone);
    buffer.writeln();
    buffer.writeln('-' * 48);
    
    // Payment details
    buffer.writeln('DADOS DO PAGAMENTO:');
    buffer.writeln();
    buffer.writeln('Cliente: $clientName');
    buffer.writeln('Referência: $reference');
    buffer.writeln('Data: ${_formatDate(paymentDate)}');
    buffer.writeln('Hora: ${_formatTime(paymentDate)}');
    buffer.writeln();
    
    // Amounts
    buffer.writeln('VALORES:');
    buffer.writeln();
    buffer.writeln('Valor da conta:     ${billAmount.toStringAsFixed(2)} MT');
    buffer.writeln('Valor pago:         ${paidAmount.toStringAsFixed(2)} MT');
    
    final change = paidAmount - billAmount;
    if (change > 0) {
      buffer.writeln('Troco:              ${change.toStringAsFixed(2)} MT');
    }
    
    buffer.writeln();
    buffer.writeln('Forma pagamento: $paymentMethod');
    
    if (notes != null && notes.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('Observações: $notes');
    }
    
    // Footer
    buffer.writeln();
    buffer.writeln('-' * 48);
    buffer.writeln('        Obrigado pela preferência!');
    buffer.writeln('    Sistema VitalH2X - Gestão de Água');
    buffer.writeln();
    buffer.writeln('=' * 48);
    
    return buffer.toString();
  }

  /// Build reading receipt content
  String _buildReadingReceiptContent({
    required String companyName,
    required String companyAddress,
    required String companyPhone,
    required String clientName,
    required String reference,
    required double previousReading,
    required double currentReading,
    required double consumption,
    required double billAmount,
    required DateTime readingDate,
  }) {
    final buffer = StringBuffer();
    
    // Header
    buffer.writeln('=' * 48);
    buffer.writeln('           RECIBO DE LEITURA');
    buffer.writeln('=' * 48);
    buffer.writeln();
    
    // Company info
    buffer.writeln(companyName);
    buffer.writeln(companyAddress);
    buffer.writeln(companyPhone);
    buffer.writeln();
    buffer.writeln('-' * 48);
    
    // Reading details
    buffer.writeln('DADOS DA LEITURA:');
    buffer.writeln();
    buffer.writeln('Cliente: $clientName');
    buffer.writeln('Referência: $reference');
    buffer.writeln('Data: ${_formatDate(readingDate)}');
    buffer.writeln('Hora: ${_formatTime(readingDate)}');
    buffer.writeln();
    
    // Consumption
    buffer.writeln('CONSUMO:');
    buffer.writeln();
    buffer.writeln('Leitura anterior:   ${previousReading.toStringAsFixed(1)} m³');
    buffer.writeln('Leitura atual:      ${currentReading.toStringAsFixed(1)} m³');
    buffer.writeln('Consumo:            ${consumption.toStringAsFixed(1)} m³');
    buffer.writeln();
    buffer.writeln('Valor a pagar:      ${billAmount.toStringAsFixed(2)} MT');
    
    // Footer
    buffer.writeln();
    buffer.writeln('-' * 48);
    buffer.writeln('       Apresente este recibo na cobrança');
    buffer.writeln('    Sistema VitalH2X - Gestão de Água');
    buffer.writeln();
    buffer.writeln('=' * 48);
    
    return buffer.toString();
  }

  /// Format date as DD/MM/YYYY
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
           '${date.month.toString().padLeft(2, '0')}/'
           '${date.year}';
  }

  /// Format time as HH:MM
  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:'
           '${date.minute.toString().padLeft(2, '0')}';
  }

  /// Test printer connection
  Future<bool> testPrinter([String? printerName]) async {
    printerName ??= await _settings.getPrinterName();
    
    if (printerName.isEmpty) {
      lastError.value = 'Nome da impressora não configurado';
      return false;
    }

    if (!await printerExists(printerName)) {
      lastError.value = 'Impressora "$printerName" não encontrada';
      return false;
    }

    // Print test page
    final testContent = '''
========================================
           TESTE DE IMPRESSÃO
========================================

Impressora: $printerName
Data/Hora: ${_formatDate(DateTime.now())} ${_formatTime(DateTime.now())}

Se você está vendo esta mensagem,
a impressora está funcionando corretamente!

Sistema VitalH2X - Gestão de Água
========================================
''';

    return await printText(
      content: testContent,
      printerName: printerName,
      jobName: 'Teste de Impressão VitalH2X',
    );
  }
}