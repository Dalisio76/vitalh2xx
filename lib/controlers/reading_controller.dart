// ===== READING CONTROLLER CORRIGIDO =====
// lib/app/controllers/reading_controller.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vitalh2x/controlers/auth_controller.dart';
import 'package:vitalh2x/controlers/base_controler.dart';
import 'package:vitalh2x/models/cliente_model.dart';
import 'package:vitalh2x/models/leitura_model.dart';
import 'package:vitalh2x/models/metodo_pagamento_model.dart';
import 'package:vitalh2x/repository/cliente_repository.dart';
import 'package:vitalh2x/repository/reading_repository.dart';
import 'package:vitalh2x/services/app_config.dart';
import 'package:vitalh2x/services/database_providers.dart';
import 'package:vitalh2x/services/print_service.dart';

class ReadingController extends BaseController {
  final ReadingRepository _readingRepository = ReadingRepository(
    SQLiteDatabaseProvider(),
  );
  final ClientRepository _clientRepository = ClientRepository(
    SQLiteDatabaseProvider(),
  );

  // Lists
  final RxList<ReadingModel> readings = <ReadingModel>[].obs;
  final RxList<ReadingModel> monthlyReadings = <ReadingModel>[].obs;
  final RxList<ReadingModel> pendingBills = <ReadingModel>[].obs;
  final RxList<ReadingModel> overdueBills = <ReadingModel>[].obs;

  // Current reading
  final Rx<ReadingModel?> selectedReading = Rx<ReadingModel?>(null);
  final Rx<ClientModel?> selectedClient = Rx<ClientModel?>(null);

  // Form fields
  final RxString clientReference = ''.obs;
  final RxDouble currentReading = 0.0.obs;
  final RxString notes = ''.obs;
  
  // Client search
  final RxString clientSearchTerm = ''.obs;
  final RxList<ClientModel> searchResults = <ClientModel>[].obs;
  final RxBool isSearching = false.obs;

  // Calculated fields
  final RxDouble previousReading = 0.0.obs;
  final RxDouble consumption = 0.0.obs;
  final RxDouble billAmount = 0.0.obs;

  // Current month/year
  final RxInt currentMonth = DateTime.now().month.obs;
  final RxInt currentYear = DateTime.now().year.obs;

  // Statistics
  final RxMap<String, dynamic> monthlyStats = <String, dynamic>{}.obs;

  // Estado do formulário
  final RxBool isEditing = false.obs;

  @override
  void onInit() {
    super.onInit();
    updateOverdueReadings(); // Atualizar status das leituras em atraso primeiro
    loadMonthlyReadings();
    loadPendingBills();
    loadMonthlyStats();

    // Setup reactive calculations
    ever(currentReading, (_) => _calculateValues());
    
    // Setup reactive client search
    debounce(clientSearchTerm, (_) => searchClients(), time: const Duration(milliseconds: 500));
  }

  // Load readings for current month (apenas leituras pendentes, não pagas)
  Future<void> loadMonthlyReadings() async {
    try {
      showLoading('Carregando leituras pendentes...');

      final readings = await _readingRepository.findPendingByMonth(
        currentMonth.value,
        currentYear.value,
      );
      monthlyReadings.assignAll(readings);

      hideLoading();
    } catch (e) {
      handleException(e);
    }
  }

  // Load pending bills
  Future<void> loadPendingBills() async {
    try {
      final pending = await _readingRepository.findPendingBills();
      pendingBills.assignAll(pending);
    } catch (e) {
      print('Error loading pending bills: $e');
    }
  }

  // Load overdue bills
  Future<void> loadOverdueBills() async {
    try {
      showLoading('Carregando contas em atraso...');

      final overdue = await _readingRepository.findOverdueBills();
      overdueBills.assignAll(overdue);

      hideLoading();
    } catch (e) {
      handleException(e);
    }
  }

  // Load monthly statistics
  Future<void> loadMonthlyStats() async {
    try {
      final stats = await _readingRepository.getReadingStats(
        month: currentMonth.value,
        year: currentYear.value,
      );
      monthlyStats.assignAll(stats);
    } catch (e) {
      print('Error loading monthly stats: $e');
    }
  }

  // Find client by reference - MÉTODO CORRIGIDO
  Future<void> findClientByReference() async {
    try {
      if (clientReference.value.trim().isEmpty) {
        selectedClient.value = null;
        _resetForm();
        return;
      }

      showLoading('Buscando cliente...');

      final client = await _clientRepository.findByReference(
        clientReference.value.trim(),
      );

      if (client == null) {
        showError('Cliente não encontrado');
        selectedClient.value = null;
        _resetForm();
        hideLoading();
        return;
      }

      if (!client.isActive) {
        showError('Cliente está desativado');
        selectedClient.value = null;
        _resetForm();
        hideLoading();
        return;
      }

      selectedClient.value = client;
      
      // Clear search when client is found via reference
      clientSearchTerm.value = '';
      searchResults.clear();

      // Verificar se já existe leitura para este mês
      final existingReading = await _readingRepository.findByClientAndMonth(
        client.id!,
        currentMonth.value,
        currentYear.value,
      );

      if (existingReading != null) {
        // MODO EDIÇÃO - leitura já existe
        showSuccess('Leitura encontrada para edição');
        _setupEditMode(existingReading);
      } else {
        // MODO NOVA LEITURA
        showSuccess('Cliente encontrado: ${client.name}');
        await _setupNewReadingMode(client);
      }

      hideLoading();
    } catch (e) {
      handleException(e);
    }
  }

  // Setup para nova leitura - MÉTODO NOVO
  Future<void> _setupNewReadingMode(ClientModel client) async {
    try {
      isEditing.value = false;
      selectedReading.value = null;

      // Buscar última leitura para pegar leitura anterior
      final lastReading = await _readingRepository.findLastReadingByClient(
        client.id!,
      );

      previousReading.value = lastReading?.currentReading ?? 0.0;
      currentReading.value = 0.0;
      notes.value = '';

      _calculateValues();
      
      // Forçar atualização da interface
      update();
      
      // Mostrar informação sobre leitura anterior encontrada
      if (lastReading != null) {
        showSuccess('Leitura anterior carregada: ${previousReading.value.toStringAsFixed(1)} m³');
      } else {
        showSuccess('Primeira leitura do cliente - iniciando do zero');
      }
    } catch (e) {
      print('Erro ao configurar nova leitura: $e');
      previousReading.value = 0.0;
      showError('Erro ao carregar leitura anterior: $e');
    }
  }

  // Setup para modo edição - MÉTODO NOVO
  void _setupEditMode(ReadingModel reading) {
    isEditing.value = true;
    selectedReading.value = reading;
    currentReading.value = reading.currentReading;
    previousReading.value = reading.previousReading;
    notes.value = reading.notes ?? '';
    _calculateValues();
  }

  // Reset form - MÉTODO NOVO
  void _resetForm() {
    isEditing.value = false;
    selectedReading.value = null;
    currentReading.value = 0.0;
    previousReading.value = 0.0;
    consumption.value = 0.0;
    billAmount.value = 0.0;
    notes.value = '';
  }

  // Calculate consumption and bill amount
  void _calculateValues() async {
    if (currentReading.value > previousReading.value) {
      consumption.value = currentReading.value - previousReading.value;
      
      // Use dynamic price from settings
      final pricePerCubicMeter = await AppConfig.getPricePerCubicMeter();
      billAmount.value = consumption.value * pricePerCubicMeter;
    } else {
      consumption.value = 0.0;
      billAmount.value = 0.0;
    }
  }

  // Create reading - MÉTODO CORRIGIDO
  Future<void> createReading() async {
    try {
      if (!_validateForm()) return;

      showLoading('Registrando leitura...');

      // Verificar novamente se não existe (segurança extra)
      final existingCheck = await _readingRepository.findByClientAndMonth(
        selectedClient.value!.id!,
        currentMonth.value,
        currentYear.value,
      );

      if (existingCheck != null) {
        showError('Já existe leitura para este cliente neste mês');
        hideLoading();
        return;
      }

      // Criar nova leitura SEM ID (será gerado automaticamente)
      final reading = ReadingModel(
        // NÃO definir ID - deixar null para gerar automaticamente
        clientId: selectedClient.value!.id!,
        month: currentMonth.value,
        year: currentYear.value,
        previousReading: previousReading.value,
        currentReading: currentReading.value,
        consumption: consumption.value,
        billAmount: billAmount.value,
        readingDate: DateTime.now(),
        notes: notes.value.trim().isEmpty ? null : notes.value.trim(),
      );

      // Salvar usando repository
      await _readingRepository.create(reading);

      // Update client's last reading
      await _clientRepository.updateLastReading(
        selectedClient.value!.id!,
        currentReading.value,
      );

      // Recarregar dados ANTES de limpar o formulário
      await loadMonthlyReadings();
      await loadPendingBills();
      await loadMonthlyStats();

      hideLoading();
      showSuccess('Leitura registrada com sucesso!');

      print('DEBUG: Tentando oferecer impressão do recibo...');
      // Salvar referência do cliente antes de limpar o formulário
      final clientForPrint = selectedClient.value;
      
      // Oferecer impressão do recibo - sempre chamar
      if (clientForPrint != null) {
        _offerPrintReceipt(reading, clientForPrint).catchError((e) {
          print('Erro na oferta de impressão: $e');
        });
        print('DEBUG: Oferta de impressão disparada.');
      } else {
        print('DEBUG: Cliente não encontrado, não é possível imprimir');
      }

      // Limpar formulário DEPOIS da impressão
      clearForm();

      // Aguardar um pouco para mostrar a mensagem
      await Future.delayed(const Duration(milliseconds: 1500));
      Get.back();
    } catch (e) {
      hideLoading();
      handleException(e);
    }
  }

  // Update reading - MÉTODO CORRIGIDO
  Future<void> updateReading() async {
    try {
      if (!_validateForm()) return;
      if (selectedReading.value == null) {
        showError('Nenhuma leitura selecionada para edição');
        return;
      }

      showLoading('Atualizando leitura...');

      // ✅ USAR O DATABASEPROVIDER DO PRÓPRIO REPOSITORY
      final updateData = <String, dynamic>{
        'current_reading': currentReading.value,
        'consumption': consumption.value,
        'bill_amount': billAmount.value,
        'notes': notes.value.trim().isEmpty ? null : notes.value.trim(),
      };

      // ✅ ACESSAR DATABASEPROVIDER DIRETAMENTE
      await _readingRepository.databaseProvider.update(
        'readings',
        updateData,
        where: 'id = ?',
        whereArgs: [selectedReading.value!.id!],
      );

      // Update client's last reading
      await _clientRepository.updateLastReading(
        selectedClient.value!.id!,
        currentReading.value,
      );

      clearForm();
      await loadMonthlyReadings();
      await loadMonthlyStats();

      hideLoading();
      showSuccess('Leitura atualizada com sucesso!');

      await Future.delayed(const Duration(milliseconds: 1500));
      Get.back();
    } catch (e) {
      hideLoading();
      handleException(e);
    }
  }

  // Método unificado para salvar - NOVO
  Future<void> saveReading() async {
    if (isEditing.value) {
      await updateReading();
    } else {
      await createReading();
    }
  }

  // Select reading for editing
  void selectReading(ReadingModel reading) async {
    try {
      selectedReading.value = reading;
      currentReading.value = reading.currentReading;
      previousReading.value = reading.previousReading;
      notes.value = reading.notes ?? '';
      isEditing.value = true;

      // Load client info
      final client = await _clientRepository.findById(reading.clientId);
      if (client != null) {
        selectedClient.value = client;
        clientReference.value = client.reference;
      }
    } catch (e) {
      handleException(e);
    }
  }

  // Change month/year
  void changeMonth(int month, int year) {
    currentMonth.value = month;
    currentYear.value = year;
    updateOverdueReadings(); // Atualizar status primeiro
    loadMonthlyReadings();
    loadMonthlyStats();
  }

  // Get readings by client
  Future<void> loadClientReadings(String clientId) async {
    try {
      showLoading('Carregando histórico...');

      final clientReadings = await _readingRepository.findByClient(clientId);
      readings.assignAll(clientReadings);

      hideLoading();
    } catch (e) {
      handleException(e);
    }
  }

  // Clear form - MÉTODO CORRIGIDO
  void clearForm() {
    clientReference.value = '';
    currentReading.value = 0.0;
    notes.value = '';
    previousReading.value = 0.0;
    consumption.value = 0.0;
    billAmount.value = 0.0;
    selectedClient.value = null;
    selectedReading.value = null;
    isEditing.value = false;
    clientSearchTerm.value = '';
    searchResults.clear();
  }

  // Search clients by name or reference
  Future<void> searchClients() async {
    try {
      final searchTerm = clientSearchTerm.value.trim();
      
      if (searchTerm.isEmpty) {
        searchResults.clear();
        return;
      }

      if (searchTerm.length < 2) {
        return; // Require at least 2 characters
      }

      isSearching.value = true;

      // Search active clients by name or reference
      final clients = await _clientRepository.searchClients(searchTerm);
      
      // Filter only active clients
      final activeClients = clients.where((client) => client.isActive).toList();
      
      searchResults.assignAll(activeClients);

    } catch (e) {
      print('Error searching clients: $e');
      searchResults.clear();
    } finally {
      isSearching.value = false;
    }
  }

  // Select client from search results
  void selectClientFromSearch(ClientModel client) {
    selectedClient.value = client;
    clientReference.value = client.reference;
    clientSearchTerm.value = client.name; // Show selected client name in search
    searchResults.clear(); // Hide dropdown
    
    // Load client data (readings, etc.)
    findClientByReference();
  }

  // Clear client search
  void clearClientSearch() {
    clientSearchTerm.value = '';
    searchResults.clear();
    selectedClient.value = null;
    clientReference.value = '';
    _resetForm();
  }

  // Form validation
  bool _validateForm() {
    if (selectedClient.value == null) {
      showError('Cliente não selecionado');
      return false;
    }

    if (currentReading.value <= 0) {
      showError('Leitura atual deve ser maior que zero');
      return false;
    }

    if (currentReading.value == previousReading.value) {
      showError('Leitura atual deve ser diferente da anterior (consumo = 0)');
      return false;
    }

    if (currentReading.value < previousReading.value) {
      showError('Leitura atual não pode ser menor que a anterior');
      return false;
    }

    // Validação adicional para leituras muito baixas (pode ser suspeito)
    if (currentReading.value > 0 && currentReading.value < 1.0) {
      showError('Leitura muito baixa. Verifique se está correta.');
      return false;
    }

    return true;
  }

  // Field validators
  String? validateClientReference(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Referência do cliente é obrigatória';
    }
    return null;
  }

  String? validateCurrentReading(String? value) {
    if (value == null || value.isEmpty) {
      return 'Leitura atual é obrigatória';
    }

    final reading = double.tryParse(value);
    if (reading == null || reading <= 0) {
      return 'Leitura deve ser um número válido maior que zero';
    }

    if (reading < previousReading.value) {
      return 'Leitura não pode ser menor que a anterior';
    }

    return null;
  }

  // Delete reading (only for admins)
  Future<void> deleteReading(ReadingModel reading) async {
    try {
      // Verificar se é administrador
      final authController = Get.find<AuthController>();
      if (!authController.isAdmin()) {
        showError('Apenas administradores podem apagar leituras');
        return;
      }

      // Confirmar exclusão
      final confirmed = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('Confirmar Exclusão'),
          content: Text(
            'Tem certeza que deseja apagar esta leitura?\n\n'
            'Cliente: ${reading.clientId}\n'
            'Período: ${reading.month}/${reading.year}\n'
            'Leitura: ${reading.currentReading.toStringAsFixed(1)} m³\n\n'
            'Esta ação não pode ser desfeita!',
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Get.back(result: true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Apagar'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      showLoading('Apagando leitura...');

      // Apagar do banco
      final success = await _readingRepository.delete(reading.id!);

      if (success) {
        showSuccess('Leitura apagada com sucesso');
        await refreshData();
      } else {
        showError('Erro ao apagar leitura');
      }

      hideLoading();
    } catch (e) {
      showError('Erro ao apagar leitura: $e');
      hideLoading();
    }
  }

  // Refresh data
  Future<void> refreshData() async {
    await updateOverdueReadings(); // Atualizar status primeiro
    await loadMonthlyReadings();
    await loadPendingBills();
    await loadOverdueBills();
    await loadMonthlyStats();
  }

  // Get formatted consumption
  String get formattedConsumption =>
      '${consumption.value.toStringAsFixed(1)} m³';

  // Get formatted bill amount
  String get formattedBillAmount => '${billAmount.value.toStringAsFixed(2)} MT';

  // Get form title
  String get formTitle => isEditing.value ? 'Editar Leitura' : 'Nova Leitura';

  // Get save button text
  String get saveButtonText =>
      isEditing.value ? 'Atualizar Leitura' : 'Salvar Leitura';

  // Get client name by ID
  Future<String> getClientName(String clientId) async {
    try {
      final client = await _clientRepository.findById(clientId);
      return client?.name ?? 'Cliente não encontrado';
    } catch (e) {
      return 'Cliente não encontrado';
    }
  }

  // Get client by ID
  Future<ClientModel?> getClientById(String clientId) async {
    try {
      return await _clientRepository.findById(clientId);
    } catch (e) {
      print('Error getting client by ID: $e');
      return null;
    }
  }

  // Load paid bills by date range
  Future<List<Map<String, dynamic>>> loadPaidBillsWithClientInfo({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // Get paid readings with client info
      final paidReadingsWithInfo = await _readingRepository.findReadingsWithClientInfo(
        status: PaymentStatus.paid,
      );
      
      // Filter by date range if provided
      if (startDate != null || endDate != null) {
        return paidReadingsWithInfo.where((reading) {
          final paymentDateStr = reading['payment_date'] as String?;
          if (paymentDateStr == null) return false;
          
          final paymentDate = DateTime.parse(paymentDateStr);
          
          if (startDate != null && paymentDate.isBefore(startDate)) {
            return false;
          }
          
          if (endDate != null && paymentDate.isAfter(endDate.add(Duration(days: 1)))) {
            return false;
          }
          
          return true;
        }).toList();
      }
      
      return paidReadingsWithInfo;
    } catch (e) {
      print('Error loading paid bills with client info: $e');
      return [];
    }
  }

  // Método legado para compatibilidade
  Future<List<ReadingModel>> loadPaidBills({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // First get all paid readings
      final paidReadings = await _readingRepository.findByPaymentStatus(PaymentStatus.paid);
      
      // Filter by date range if provided
      if (startDate != null || endDate != null) {
        return paidReadings.where((reading) {
          if (reading.paymentDate == null) return false;
          
          final paymentDate = reading.paymentDate!;
          
          if (startDate != null && paymentDate.isBefore(startDate)) {
            return false;
          }
          
          if (endDate != null && paymentDate.isAfter(endDate.add(Duration(days: 1)))) {
            return false;
          }
          
          return true;
        }).toList();
      }
      
      return paidReadings;
    } catch (e) {
      print('Error loading paid bills: $e');
      return [];
    }
  }

  // Atualizar leituras que devem virar dívidas (após dia 5 do mês - baseado no calendário do computador)
  // Atualizar leituras que devem virar dívidas (execução silenciosa)
  Future<void> updateOverdueReadings() async {
    try {
      print('🔄 Verificando leituras que devem virar dívidas...');
      
      final now = DateTime.now();
      final currentDay = now.day;
      
      // Só atualizar se hoje é após dia 5
      if (currentDay > 5) {
        final overdueReadings = await _readingRepository.findOverdueReadings();

        int updated = 0;
        for (final reading in overdueReadings) {
          // Atualizar status para overdue (dívida)
          final success = await _readingRepository.updatePaymentStatus(
            reading.id!,
            PaymentStatus.overdue,
          );
          if (success) updated++;
        }

        if (updated > 0) {
          print('📋 $updated leituras atualizadas para status de dívida');
        } else {
          print('ℹ️  Nenhuma leitura pendente encontrada para atualizar');
        }
      } else {
        print('📅 Ainda dentro do prazo de pagamento (dia $currentDay <= 5)');
      }
    } catch (e) {
      print('❌ Erro ao atualizar leituras em atraso: $e');
    }
  }

  // Método para forçar atualização manual (para admin)
  Future<void> forceUpdateOverdueReadings() async {
    try {
      showLoading('Atualizando status de leituras pendentes...');
      
      final overdueReadings = await _readingRepository.findOverdueReadings();
      int updated = 0;
      
      for (final reading in overdueReadings) {
        final success = await _readingRepository.updatePaymentStatus(
          reading.id!,
          PaymentStatus.overdue,
        );
        if (success) updated++;
      }
      
      if (updated > 0) {
        showSuccess('$updated leituras atualizadas para status de dívida');
        await refreshData();
      } else {
        showSuccess('Nenhuma leitura pendente encontrada para atualizar');
      }
      
      hideLoading();
    } catch (e) {
      showError('Erro ao atualizar leituras: $e');
      hideLoading();
    }
  }

  // ===== MÉTODOS DE IMPRESSÃO =====
  
  /// Oferece opção de imprimir recibo de leitura
  Future<void> _offerPrintReceipt(ReadingModel reading, ClientModel client) async {
    print('=== INÍCIO _offerPrintReceipt ===');
    try {
      // Verificar se o serviço de impressão está disponível
      if (!Get.isRegistered<PrintService>()) {
        print('PrintService não está registrado!');
        Get.snackbar('Info', 'Sistema de impressão não configurado');
        return;
      }
      
      final printService = Get.find<PrintService>();
      print('PrintService encontrado: ${printService.isInitialized.value}');
      
      if (!printService.isInitialized.value) {
        print('PrintService não inicializado');
        Get.snackbar('Info', 'Serviço de impressão não está ativo');
        return;
      }
      
      // Mostrar dialog simples perguntando se quer imprimir
      final shouldPrint = await Get.dialog<bool>(
        AlertDialog(
          title: Text('Imprimir Recibo'),
          content: Text(
            'Deseja imprimir o recibo da leitura para ${client.name}?\n\n'
            'Consumo: ${reading.consumption.toStringAsFixed(1)} m³\n'
            'Valor: ${reading.billAmount.toStringAsFixed(2)} MT',
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
      
      print('Dialog result: $shouldPrint');
      if (shouldPrint == true) {
        print('Usuário escolheu imprimir, chamando _printReadingReceipt...');
        await _printReadingReceipt(reading, client);
      } else {
        print('Usuário escolheu não imprimir');
      }
      
    } catch (e) {
      print('Erro ao oferecer impressão: $e');
      Get.snackbar('Erro', 'Erro no sistema de impressão: $e');
    }
    print('=== FIM _offerPrintReceipt ===');
  }
  
  /// Imprime recibo de leitura
  Future<void> _printReadingReceipt(ReadingModel reading, ClientModel client) async {
    try {
      showLoading('Imprimindo recibo...');
      
      final printService = Get.find<PrintService>();
      
      final success = await printService.printReadingReceipt(
        clientName: client.name,
        reference: client.reference,
        previousReading: reading.previousReading,
        currentReading: reading.currentReading,
        consumption: reading.consumption,
        billAmount: reading.billAmount,
        readingDate: reading.readingDate,
      );
      
      hideLoading();
      
      if (success) {
        showSuccess('Recibo impresso com sucesso!');
      } else {
        showError('Erro na impressão: ${printService.lastError.value}');
        // Oferecer tentar novamente
        _offerRetryPrint(reading, client);
      }
      
    } catch (e) {
      hideLoading();
      showError('Erro ao imprimir recibo: $e');
    }
  }
  
  /// Oferece tentar imprimir novamente
  void _offerRetryPrint(ReadingModel reading, ClientModel client) {
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
              _printReadingReceipt(reading, client);
            },
            child: Text('Tentar Novamente'),
          ),
        ],
      ),
    );
  }

  /// Método público para imprimir recibo de leitura existente
  Future<void> printReadingReceipt(ReadingModel reading) async {
    try {
      final client = await _clientRepository.findById(reading.clientId);
      if (client == null) {
        showError('Cliente não encontrado');
        return;
      }
      
      await _printReadingReceipt(reading, client);
    } catch (e) {
      showError('Erro ao imprimir recibo: $e');
    }
  }
}
