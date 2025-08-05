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
import 'auth_controller.dart';

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
      final remainingDebt = amountToPay.value - amountPaid.value;
      final currentDebt = selectedClient.value!.totalDebt;
      final newTotalDebt = currentDebt - amountPaid.value;

      await _clientRepository.updateTotalDebt(
        selectedClient.value!.id!,
        newTotalDebt > 0 ? newTotalDebt : 0.0,
      );

      // Generate new receipt number for next payment
      await generateReceiptNumber();

      clearForm();
      await loadPendingBills();
      await loadPaymentStats();

      showSuccess('Pagamento processado com sucesso!');

      // Show receipt option
      Get.dialog(
        AlertDialog(
          title: Text('Pagamento Realizado'),
          content: Text('Deseja imprimir o recibo?'),
          actions: [
            TextButton(onPressed: () => Get.back(), child: Text('Não')),
            TextButton(
              onPressed: () {
                Get.back();
                printReceipt(payment);
              },
              child: Text('Imprimir'),
            ),
          ],
        ),
      );
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
      showError('Valor pago não pode ser maior que o valor da conta');
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
      return 'Valor não pode ser maior que o valor da conta';
    }

    return null;
  }

  // Refresh data
  Future<void> refreshData() async {
    await loadPendingBills();
    await loadPaymentHistory();
    await loadPaymentStats();
  }

  // Get formatted amounts
  String get formattedAmountToPay =>
      '${amountToPay.value.toStringAsFixed(2)} MT';
  String get formattedAmountPaid => '${amountPaid.value.toStringAsFixed(2)} MT';
}
