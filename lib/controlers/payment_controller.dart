// ===== PAYMENT CONTROLLER =====
// lib/app/controllers/payment_controller.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vitalh2x/controlers/base_controler.dart';
import 'package:vitalh2x/models/cliente_model.dart';
import 'package:vitalh2x/models/leitura_model.dart';
import 'package:vitalh2x/models/metodo_pagamento_model.dart';
import 'package:vitalh2x/models/pagamento_model.dart';
import 'package:vitalh2x/repository/cliente_repository.dart';
import 'package:vitalh2x/repository/payment_repository.dart';
import 'package:vitalh2x/repository/reading_repository.dart';
import 'package:vitalh2x/services/database_providers.dart';
import 'package:vitalh2x/services/print_service.dart';
import 'package:vitalh2x/routs/rout.dart';
import 'auth_controller.dart';
import 'reading_controller.dart';

class PaymentController extends BaseController {
  final PaymentRepository _paymentRepository = PaymentRepository(
    SQLiteDatabaseProvider(),
  );
  final ReadingRepository _readingRepository = ReadingRepository(
    SQLiteDatabaseProvider(),
  );
  final ClientRepository _clientRepository = ClientRepository(
    SQLiteDatabaseProvider(),
  );

  // Lists
  final RxList<PaymentModel> payments = <PaymentModel>[].obs;
  final RxList<ReadingModel> pendingBills = <ReadingModel>[].obs;
  final RxList<Map<String, dynamic>> paymentHistory =
      <Map<String, dynamic>>[].obs;

  // Current objects
  final Rx<ReadingModel?> selectedReading = Rx<ReadingModel?>(null);
  final Rx<ClientModel?> selectedClient = Rx<ClientModel?>(null);
  final Rx<PaymentModel?> selectedPayment = Rx<PaymentModel?>(null);

  // Form fields
  final RxString clientReference = ''.obs;
  final RxDouble amountToPay = 0.0.obs;
  final RxDouble amountPaid = 0.0.obs;
  final Rx<PaymentMethod> paymentMethod = PaymentMethod.cash.obs;
  final RxString transactionReference = ''.obs;
  final RxString notes = ''.obs;
  final RxString receiptNumber = ''.obs;

  // Date filters
  final Rx<DateTime> startDate =
      DateTime.now().subtract(Duration(days: 30)).obs;
  final Rx<DateTime> endDate = DateTime.now().obs;

  // Statistics
  final RxMap<String, dynamic> paymentStats = <String, dynamic>{}.obs;

  @override
  void onInit() {
    super.onInit();
    loadPendingBills();
    loadPaymentStats();
    generateReceiptNumber();
    // Atrasar a verificação de dados pré-carregados para garantir que os argumentos estão disponíveis
    Future.delayed(Duration(milliseconds: 100), () {
      _checkForPreloadedData();
    });
  }

  // Check if data was pre-loaded from reading list
  void _checkForPreloadedData() {
    final arguments = Get.arguments;
    
    if (arguments != null && arguments is Map) {
      final isPreloaded = arguments['preloaded'] as bool? ?? false;
      
      if (isPreloaded) {
        final reading = arguments['reading'] as ReadingModel?;
        final client = arguments['client'] as ClientModel?;
        
        if (reading != null && client != null) {
          loadPreloadedData(client, reading);
        } else if (reading != null) {
          // Carregar cliente a partir da leitura
          loadPreloadedDataFromReading(reading);
        }
      }
    }
  }

  // Load pre-loaded data when only reading is provided
  void loadPreloadedDataFromReading(ReadingModel reading) async {
    try {
      showLoading('Carregando dados do cliente...');
      
      // Buscar cliente pela reading
      final client = await _clientRepository.findById(reading.clientId);
      
      if (client != null) {
        selectedClient.value = client;
        selectedReading.value = reading;
        clientReference.value = client.reference;
        amountToPay.value = reading.billAmount;
        amountPaid.value = reading.billAmount;
        
        // Carregar contas pendentes do cliente
        await loadPendingBillsForClient(client.id!);
        
        hideLoading();
        showSuccess('Dados carregados: ${client.name} - ${reading.billAmount.toStringAsFixed(2)} MT');
      } else {
        hideLoading();
        showError('Cliente não encontrado para esta leitura');
      }
    } catch (e) {
      hideLoading();
      showError('Erro ao carregar dados: $e');
    }
  }

  // Load pre-loaded client and reading data
  void loadPreloadedData(ClientModel client, ReadingModel reading) {
    selectedClient.value = client;
    selectedReading.value = reading;
    clientReference.value = client.reference;
    amountToPay.value = reading.billAmount;
    amountPaid.value = reading.billAmount;
    
    showSuccess('Dados do cliente carregados: ${client.name}');
    showSuccess('Valor a pagar: ${amountToPay.value.toStringAsFixed(2)} MT');
  }

  // Método público para verificar argumentos pré-carregados (pode ser chamado pela view)
  void checkForPreloadedDataFromView() {
    _checkForPreloadedData();
  }

  // Load pending bills
  Future<void> loadPendingBills() async {
    try {
      showLoading('Carregando contas pendentes...');

      final pending = await _readingRepository.findPendingBills();
      pendingBills.assignAll(pending);

      hideLoading();
    } catch (e) {
      handleException(e);
    }
  }

  // Load pending bills for specific client
  Future<void> loadPendingBillsForClient(String clientId) async {
    try {
      final pending = await _readingRepository.findPendingBillsByClientId(clientId);
      pendingBills.assignAll(pending);
    } catch (e) {
      showError('Erro ao carregar contas pendentes: $e');
    }
  }

  // Load payment history
  Future<void> loadPaymentHistory() async {
    try {
      showLoading('Carregando histórico de pagamentos...');

      final history = await _paymentRepository.findPaymentsWithDetails(
        startDate: startDate.value,
        endDate: endDate.value,
      );
      paymentHistory.assignAll(history);

      hideLoading();
    } catch (e) {
      handleException(e);
    }
  }

  // Load payment statistics
  Future<void> loadPaymentStats() async {
    try {
      final stats = await _paymentRepository.getPaymentStats(
        startDate: startDate.value,
        endDate: endDate.value,
      );
      paymentStats.assignAll(stats);
    } catch (e) {
      print('Error loading payment stats: $e');
    }
  }

  // Find client by reference
  Future<void> findClientByReference() async {
    try {
      if (clientReference.value.trim().isEmpty) {
        selectedClient.value = null;
        selectedReading.value = null;
        return;
      }

      showLoading('Buscando cliente...');

      final client = await _clientRepository.findByReference(
        clientReference.value.trim(),
      );

      if (client == null) {
        showError('Cliente não encontrado');
        selectedClient.value = null;
        selectedReading.value = null;
        hideLoading();
        return;
      }

      selectedClient.value = client;

      // Find pending bills for this client
      final clientPendingBills =
          pendingBills.where((bill) => bill.clientId == client.id).toList();

      if (clientPendingBills.isEmpty) {
        showError('Cliente não possui contas pendentes');
        selectedReading.value = null;
        amountToPay.value = 0.0;
        hideLoading();
        return;
      }

      // For simplicity, take the oldest pending bill
      selectedReading.value = clientPendingBills.first;
      amountToPay.value = selectedReading.value!.billAmount;
      amountPaid.value = selectedReading.value!.billAmount;

      hideLoading();
      showSuccess('Cliente encontrado: ${client.name}');
      showSuccess('Valor a pagar: ${amountToPay.value.toStringAsFixed(2)} MT');
    } catch (e) {
      handleException(e);
    }
  }

  // Generate receipt number
  Future<void> generateReceiptNumber() async {
    try {
      final number = await _paymentRepository.generateReceiptNumber();
      receiptNumber.value = number;
    } catch (e) {
      print('Error generating receipt number: $e');
    }
  }

  // Process payment
  Future<void> processPayment() async {
    try {
      if (!_validateForm()) return;

      showLoading('Processando pagamento...');

      final authController = Get.find<AuthController>();

      // Create payment record
      final payment = PaymentModel(
        clientId: selectedClient.value!.id!,
        readingId: selectedReading.value!.id!,
        amountPaid: amountPaid.value,
        paymentMethod: paymentMethod.value,
        paymentDate: DateTime.now(),
        receiptNumber: receiptNumber.value,
        transactionReference:
            transactionReference.value.trim().isEmpty
                ? null
                : transactionReference.value.trim(),
        notes: notes.value.trim().isEmpty ? null : notes.value.trim(),
        userId: authController.currentUser!.id!,
      );

      await _paymentRepository.create(payment);

      // Update reading payment status
      PaymentStatus newStatus = PaymentStatus.paid;
      if (amountPaid.value < amountToPay.value) {
        newStatus = PaymentStatus.partial;
      }

      await _readingRepository.updatePaymentStatus(
        selectedReading.value!.id!,
        newStatus,
        paymentDate: DateTime.now(),
      );

      // Update client total debt
      final currentDebt = selectedClient.value!.totalDebt;
      final newTotalDebt = currentDebt - amountPaid.value;

      await _clientRepository.updateTotalDebt(
        selectedClient.value!.id!,
        newTotalDebt > 0 ? newTotalDebt : 0.0,
      );

      // Generate new receipt number for next payment
      await generateReceiptNumber();

      // Recarregar dados ANTES de limpar formulário
      await loadPendingBills();
      await loadPaymentStats();

      // Atualizar a lista de leituras se o controller existir
      try {
        if (Get.isRegistered<ReadingController>()) {
          final readingController = Get.find<ReadingController>();
          await readingController.refreshData();
        }
      } catch (e) {
        print('Aviso: Não foi possível atualizar lista de leituras: $e');
      }

      hideLoading();
      showSuccess('Pagamento processado com sucesso!');

      print('🎫 DEBUG: Tentando oferecer impressão do recibo de pagamento...');
      // Oferecer impressão do recibo - sempre chamar
      await _offerPrintPaymentReceipt(payment).catchError((e) {
        print('❌ Erro na oferta de impressão: $e');
        showError('Erro ao preparar impressão: $e');
      });
      print('✅ DEBUG: Oferta de impressão de pagamento concluída.');

      // Limpar formulário DEPOIS da impressão
      clearForm();

      // Navegar de volta
      _navigateBackToReadings();
    } catch (e) {
      handleException(e);
    }
  }

  // Print receipt
  Future<void> printReceipt(PaymentModel payment) async {
    try {
      showLoading('Preparando recibo...');

      // TODO: Implement receipt printing
      // This would integrate with the printing service

      hideLoading();
      showSuccess('Recibo enviado para impressão');
    } catch (e) {
      handleException(e);
    }
  }

  // Load payments by client
  Future<void> loadClientPayments(String clientId) async {
    try {
      showLoading('Carregando pagamentos do cliente...');

      final clientPayments = await _paymentRepository.findByClient(clientId);
      payments.assignAll(clientPayments);

      hideLoading();
    } catch (e) {
      handleException(e);
    }
  }

  // Change date range
  void changeDateRange(DateTime start, DateTime end) {
    startDate.value = start;
    endDate.value = end;
    loadPaymentHistory();
    loadPaymentStats();
  }

  // Clear form
  void clearForm() {
    clientReference.value = '';
    amountToPay.value = 0.0;
    amountPaid.value = 0.0;
    paymentMethod.value = PaymentMethod.cash;
    transactionReference.value = '';
    notes.value = '';
    selectedClient.value = null;
    selectedReading.value = null;
  }

  // Form validation
  bool _validateForm() {
    if (selectedClient.value == null) {
      showError('Cliente não selecionado');
      return false;
    }

    if (selectedReading.value == null) {
      showError('Conta não selecionada');
      return false;
    }

    if (amountPaid.value <= 0) {
      showError('Valor pago deve ser maior que zero');
      return false;
    }

    if (amountPaid.value > amountToPay.value) {
      showError('Valor pago não pode ser maior que o valor a pagar');
      return false;
    }

    if (receiptNumber.value.isEmpty) {
      showError('Número do recibo é obrigatório');
      return false;
    }

    return true;
  }

  // Field validators
  String? validateAmountPaid(String? value) {
    if (value == null || value.isEmpty) {
      return 'Valor pago é obrigatório';
    }

    final amount = double.tryParse(value);
    if (amount == null || amount <= 0) {
      return 'Valor deve ser maior que zero';
    }

    if (amount > amountToPay.value) {
      return 'Valor não pode ser maior que o valor a pagar';
    }

    return null;
  }

  // Refresh data
  Future<void> refreshData() async {
    await loadPendingBills();
    await loadPaymentHistory();
    await loadPaymentStats();
  }

  // Navigate back to readings list
  void _navigateBackToReadings() {
    try {
      // Verificar se veio de uma tela específica
      final arguments = Get.arguments;
      if (arguments != null && arguments is Map) {
        final returnTo = arguments['returnTo'] as String?;
        if (returnTo != null) {
          Get.offAllNamed(returnTo);
          return;
        }
      }
      
      // Navegar de volta ao invés de substituir todas as rotas
      if (Get.routing.previous.isNotEmpty) {
        Get.back();
      } else {
        // Fallback: ir para readings
        Get.offAllNamed(Routes.READINGS);
      }
    } catch (e) {
      print('Erro ao navegar: $e');
      // Fallback: voltar para home
      Get.offAllNamed(Routes.HOME);
    }
  }

  // Get formatted amounts
  String get formattedAmountToPay =>
      '${amountToPay.value.toStringAsFixed(2)} MT';
  String get formattedAmountPaid => '${amountPaid.value.toStringAsFixed(2)} MT';

  // ===== MÉTODOS DE IMPRESSÃO =====
  
  /// Oferece opção de imprimir recibo de pagamento
  Future<void> _offerPrintPaymentReceipt(PaymentModel payment) async {
    print('=== INÍCIO _offerPrintPaymentReceipt ===');
    try {
      // Verificar se o serviço de impressão está disponível
      if (!Get.isRegistered<PrintService>()) {
        print('PrintService não está registrado no pagamento!');
        Get.snackbar('Info', 'Sistema de impressão não configurado');
        return;
      }
      
      final printService = Get.find<PrintService>();
      print('PrintService encontrado no pagamento: ${printService.isInitialized.value}');
      
      if (!printService.isInitialized.value) {
        print('PrintService não inicializado no pagamento');
        Get.snackbar('Info', 'Serviço de impressão não está ativo');
        return;
      }
      
      // Mostrar dialog perguntando se quer imprimir
      final shouldPrint = await Get.dialog<bool>(
        AlertDialog(
          title: Text('Imprimir Recibo'),
          content: Text(
            'Pagamento realizado com sucesso!\n\n'
            'Cliente: ${selectedClient.value?.name ?? 'N/A'}\n'
            'Valor: ${payment.amountPaid.toStringAsFixed(2)} MT\n'
            'Recibo: ${payment.receiptNumber}\n\n'
            'Deseja imprimir o recibo?',
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: Text('Não'),
            ),
            TextButton(
              onPressed: () => Get.back(result: true),
              child: Text('Imprimir'),
            ),
          ],
        ),
      );
      
      if (shouldPrint == true) {
        await _printPaymentReceipt(payment);
      }
      
    } catch (e) {
      print('Erro ao oferecer impressão: $e');
    }
  }
  
  /// Imprime recibo de pagamento
  Future<void> _printPaymentReceipt(PaymentModel payment) async {
    try {
      showLoading('Imprimindo recibo...');
      
      final printService = Get.find<PrintService>();
      
      final success = await printService.printPaymentReceipt(
        clientName: selectedClient.value?.name ?? 'Cliente',
        reference: selectedClient.value?.reference ?? 'N/A',
        amountPaid: payment.amountPaid,
        paymentMethod: payment.paymentMethod.displayName,
        receiptNumber: payment.receiptNumber,
        paymentDate: payment.paymentDate,
      );
      
      hideLoading();
      
      if (success) {
        showSuccess('Recibo impresso com sucesso!');
      } else {
        showError('Erro na impressão: ${printService.lastError.value}');
        // Oferecer tentar novamente
        _offerRetryPrintPayment(payment);
      }
      
    } catch (e) {
      hideLoading();
      showError('Erro ao imprimir recibo: $e');
    }
  }
  
  /// Oferece tentar imprimir novamente
  void _offerRetryPrintPayment(PaymentModel payment) {
    Get.dialog(
      AlertDialog(
        title: Text('Falha na Impressão'),
        content: Text(
          'Não foi possível imprimir o recibo.\n\n'
          'Verifique se a impressora está ligada e conectada.\n\n'
          'Deseja tentar novamente?',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              _printPaymentReceipt(payment);
            },
            child: Text('Tentar Novamente'),
          ),
        ],
      ),
    );
  }

  /// Método público para imprimir recibo de pagamento existente
  Future<void> printPaymentReceipt(PaymentModel payment) async {
    await _printPaymentReceipt(payment);
  }

  /// Método legado para compatibilidade (pode ser removido depois)
  @Deprecated('Use printPaymentReceipt instead')
  Future<void> printReceiptLegacy(PaymentModel payment) async {
    await printPaymentReceipt(payment);
  }
}
