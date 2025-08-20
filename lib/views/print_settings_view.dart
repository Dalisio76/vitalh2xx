// ===== PRINT SETTINGS VIEW =====
// lib/views/print_settings_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vitalh2x/services/print_service.dart';

class PrintSettingsView extends StatelessWidget {
  const PrintSettingsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final printService = Get.find<PrintService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações de Impressão'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status da impressão
            _buildStatus(printService),
            
            const SizedBox(height: 24),
            
            // Teste de impressão
            _buildTestSection(printService),
            
            const SizedBox(height: 24),
            
            // Informações
            _buildInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatus(PrintService printService) {
    return Obx(() => Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  printService.isInitialized.value 
                    ? Icons.check_circle 
                    : Icons.error,
                  color: printService.isInitialized.value 
                    ? Colors.green 
                    : Colors.red,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Status do Serviço',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            _buildStatusRow(
              'Serviço de Impressão',
              printService.isInitialized.value ? 'Ativo' : 'Inativo',
              printService.isInitialized.value ? Colors.green : Colors.red,
            ),
            
            if (printService.isPrinting.value)
              _buildStatusRow(
                'Status',
                'Imprimindo...',
                Colors.orange,
              ),
            
            if (printService.lastError.value.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildStatusRow(
                'Último Erro',
                printService.lastError.value,
                Colors.red,
              ),
            ],
          ],
        ),
      ),
    ));
  }

  Widget _buildStatusRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestSection(PrintService printService) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Teste de Impressão',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            const Text(
              'Use os botões abaixo para testar a impressão de recibos.',
              style: TextStyle(color: Colors.grey),
            ),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: Obx(() => ElevatedButton.icon(
                    onPressed: printService.isPrinting.value
                      ? null
                      : () => _testPrint(printService),
                    icon: const Icon(Icons.print),
                    label: const Text('Teste Simples'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  )),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Obx(() => ElevatedButton.icon(
                    onPressed: printService.isPrinting.value
                      ? null
                      : () => _testReadingReceipt(printService),
                    icon: const Icon(Icons.receipt),
                    label: const Text('Teste Leitura'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  )),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            SizedBox(
              width: double.infinity,
              child: Obx(() => ElevatedButton.icon(
                onPressed: printService.isPrinting.value
                  ? null
                  : () => _testPaymentReceipt(printService),
                icon: const Icon(Icons.payment),
                label: const Text('Teste Pagamento'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                ),
              )),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informações',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            const Text(
              'Funcionalidades Disponíveis:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            
            const Text('• Impressão simulada no console'),
            const Text('• Templates otimizados para recibos 58mm'),
            const Text('• Formatação automática de dados'),
            const Text('• Controle de status e erros'),
            
            const SizedBox(height: 16),
            
            const Text(
              'Próximas Implementações:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            
            const Text('• Impressão via Sunmi V2'),
            const Text('• Impressão via Bluetooth'),
            const Text('• Geração de PDF'),
            const Text('• Configurações avançadas'),
          ],
        ),
      ),
    );
  }

  void _testPrint(PrintService printService) async {
    try {
      Get.dialog(
        const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Executando teste de impressão...'),
                ],
              ),
            ),
          ),
        ),
        barrierDismissible: false,
      );

      final success = await printService.printTest();
      
      Get.back(); // Fechar dialog de loading
      
      if (success) {
        Get.snackbar(
          'Sucesso',
          'Teste de impressão realizado com sucesso!\nVerifique o console para ver o resultado.',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
      } else {
        Get.snackbar(
          'Erro',
          'Falha no teste: ${printService.lastError.value}',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.back(); // Fechar dialog se estiver aberto
      Get.snackbar(
        'Erro',
        'Erro no teste de impressão: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _testReadingReceipt(PrintService printService) async {
    try {
      Get.dialog(
        const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Imprimindo recibo de leitura de teste...'),
                ],
              ),
            ),
          ),
        ),
        barrierDismissible: false,
      );

      final success = await printService.printReadingReceipt(
        clientName: 'JOÃO DA SILVA (TESTE)',
        reference: 'TEST001',
        previousReading: 150.0,
        currentReading: 175.0,
        consumption: 25.0,
        billAmount: 1250.0,
        readingDate: DateTime.now(),
      );
      
      Get.back(); // Fechar dialog de loading
      
      if (success) {
        Get.snackbar(
          'Sucesso',
          'Recibo de leitura de teste impresso com sucesso!\nVerifique o console para ver o resultado.',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
      } else {
        Get.snackbar(
          'Erro',
          'Falha na impressão: ${printService.lastError.value}',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.back(); // Fechar dialog se estiver aberto
      Get.snackbar(
        'Erro',
        'Erro na impressão do recibo: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _testPaymentReceipt(PrintService printService) async {
    try {
      Get.dialog(
        const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Imprimindo recibo de pagamento de teste...'),
                ],
              ),
            ),
          ),
        ),
        barrierDismissible: false,
      );

      final success = await printService.printPaymentReceipt(
        clientName: 'MARIA SANTOS (TESTE)',
        reference: 'TEST002',
        amountPaid: 1250.0,
        paymentMethod: 'Dinheiro',
        receiptNumber: 'REC-2025-001',
        paymentDate: DateTime.now(),
      );
      
      Get.back(); // Fechar dialog de loading
      
      if (success) {
        Get.snackbar(
          'Sucesso',
          'Recibo de pagamento de teste impresso com sucesso!\nVerifique o console para ver o resultado.',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
      } else {
        Get.snackbar(
          'Erro',
          'Falha na impressão: ${printService.lastError.value}',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.back(); // Fechar dialog se estiver aberto
      Get.snackbar(
        'Erro',
        'Erro na impressão do recibo: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}