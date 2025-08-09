// ===== READING CONTROLLER CORRIGIDO =====
// lib/app/controllers/reading_controller.dart

import 'package:get/get.dart';
import 'package:vitalh2x/controlers/base_controler.dart';
import 'package:vitalh2x/models/cliente_model.dart';
import 'package:vitalh2x/models/leitura_model.dart';
import 'package:vitalh2x/repository/cliente_repository.dart';
import 'package:vitalh2x/repository/reading_repository.dart';
import 'package:vitalh2x/services/app_config.dart';
import 'package:vitalh2x/services/database_providers.dart';

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
    loadMonthlyReadings();
    loadPendingBills();
    loadMonthlyStats();

    // Setup reactive calculations
    ever(currentReading, (_) => _calculateValues());
  }

  // Load readings for current month
  Future<void> loadMonthlyReadings() async {
    try {
      showLoading('Carregando leituras do mês...');

      final readings = await _readingRepository.findByMonth(
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
    } catch (e) {
      print('Erro ao configurar nova leitura: $e');
      previousReading.value = 0.0;
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
  void _calculateValues() {
    if (currentReading.value > previousReading.value) {
      consumption.value = currentReading.value - previousReading.value;
      billAmount.value = consumption.value * AppConfig.pricePerCubicMeter;
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

      // Limpar formulário e recarregar dados
      clearForm();
      await loadMonthlyReadings();
      await loadPendingBills();
      await loadMonthlyStats();

      hideLoading();
      showSuccess('Leitura registrada com sucesso!');

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

    if (currentReading.value < previousReading.value) {
      showError('Leitura atual não pode ser menor que a anterior');
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

  // Refresh data
  Future<void> refreshData() async {
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
}
