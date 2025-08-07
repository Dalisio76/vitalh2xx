// ===== CLIENT CONTROLLER =====
// lib/app/controllers/client_controller.dart

import 'package:get/get.dart';
import 'package:vitalh2x/controlers/base_controler.dart';
import 'package:vitalh2x/models/cliente_model.dart';
import 'package:vitalh2x/repository/cliente_repository.dart';
import 'package:vitalh2x/services/database_providers.dart';

class ClientController extends BaseController {
  final ClientRepository _clientRepository = ClientRepository(
    SQLiteDatabaseProvider(),
  );

  // Lists
  final RxList<ClientModel> clients = <ClientModel>[].obs;
  final RxList<ClientModel> filteredClients = <ClientModel>[].obs;
  final RxList<ClientModel> clientsWithDebt = <ClientModel>[].obs;

  // Current client
  final Rx<ClientModel?> selectedClient = Rx<ClientModel?>(null);

  // Form fields
  final RxString name = ''.obs;
  final RxString contact = ''.obs;
  final RxString reference = ''.obs;
  final RxString counterNumber = ''.obs;

  // Search and filters
  final RxString searchTerm = ''.obs;
  final RxBool showOnlyActive = true.obs;
  final RxBool showOnlyWithDebt = false.obs;

  // Statistics
  final RxMap<String, int> stats = <String, int>{}.obs;

  // Pagination
  final RxInt currentPage = 0.obs;
  final RxInt itemsPerPage = 20.obs;
  final RxBool hasMoreData = true.obs;

  @override
  void onInit() {
    super.onInit();
    loadClients();
    loadStats();

    // Setup search listener
    debounce(
      searchTerm,
      (_) => filterClients(),
      time: const Duration(milliseconds: 500),
    );
  }

  // Load all clients
  Future<void> loadClients({bool refresh = false}) async {
    try {
      if (refresh) {
        currentPage.value = 0;
        clients.clear();
        hasMoreData.value = true;
      }

      showLoading('Carregando clientes...');

      final newClients = await _clientRepository.findActiveClients(
        searchTerm: searchTerm.value.isEmpty ? null : searchTerm.value,
        limit: itemsPerPage.value,
        offset: currentPage.value * itemsPerPage.value,
      );

      if (newClients.length < itemsPerPage.value) {
        hasMoreData.value = false;
      }

      if (refresh) {
        clients.assignAll(newClients);
      } else {
        clients.addAll(newClients);
      }

      filterClients();
      hideLoading();
    } catch (e) {
      handleException(e);
    }
  }

  // Filter clients
  void filterClients() {
    List<ClientModel> filtered = List.from(clients);

    if (searchTerm.value.isNotEmpty) {
      filtered =
          filtered.where((client) {
            return client.name.toLowerCase().contains(
                  searchTerm.value.toLowerCase(),
                ) ||
                client.reference.toLowerCase().contains(
                  searchTerm.value.toLowerCase(),
                ) ||
                client.counterNumber.toLowerCase().contains(
                  searchTerm.value.toLowerCase(),
                );
          }).toList();
    }

    if (showOnlyActive.value) {
      filtered = filtered.where((client) => client.isActive).toList();
    }

    if (showOnlyWithDebt.value) {
      filtered = filtered.where((client) => client.totalDebt > 0).toList();
    }

    filteredClients.assignAll(filtered);
  }

  // Load more clients (pagination)
  Future<void> loadMoreClients() async {
    if (!hasMoreData.value || isLoading) return;

    currentPage.value++;
    await loadClients();
  }

  // Load clients with debt
  Future<void> loadClientsWithDebt() async {
    try {
      showLoading('Carregando clientes com dívidas...');

      final debtors = await _clientRepository.findClientsWithDebt();
      clientsWithDebt.assignAll(debtors);

      hideLoading();
    } catch (e) {
      handleException(e);
    }
  }

  // Load statistics
  Future<void> loadStats() async {
    try {
      final clientStats = await _clientRepository.getClientStats();
      stats.assignAll(clientStats);
    } catch (e) {
      print('Error loading stats: $e');
    }
  }

  // Create client
  // Create client - MÉTODO CORRIGIDO
  Future<bool> createClient() async {
    try {
      if (!_validateForm()) return false;

      showLoading('Cadastrando cliente...');

      // Check if reference exists
      if (await _clientRepository.referenceExists(reference.value)) {
        showError('Referência já existe');
        return false;
      }

      // Check if counter number exists
      if (await _clientRepository.counterNumberExists(counterNumber.value)) {
        showError('Número do contador já existe');
        return false;
      }

      final client = ClientModel(
        name: name.value.trim(),
        contact: contact.value.trim(),
        reference: reference.value.trim().toUpperCase(),
        counterNumber: counterNumber.value.trim(),
        createdAt: DateTime.now(),
      );

      await _clientRepository.create(client);

      // Atualizar dados
      await loadClients(refresh: true);
      await loadStats();

      showSuccess('Cliente cadastrado com sucesso!');

      // Aguardar um pouco para mostrar a mensagem antes de fechar
      await Future.delayed(const Duration(milliseconds: 1500));
      Get.back();

      return true;
    } catch (e) {
      handleException(e);
      return false;
    }
  }

  // Update client - MÉTODO CORRIGIDO
  Future<bool> updateClient(String clientId) async {
    try {
      if (!_validateForm()) return false;

      showLoading('Atualizando cliente...');

      // Check if reference exists (excluding current client)
      if (await _clientRepository.referenceExists(
        reference.value,
        excludeId: clientId,
      )) {
        showError('Referência já existe');
        return false;
      }

      // Check if counter number exists (excluding current client)
      if (await _clientRepository.counterNumberExists(
        counterNumber.value,
        excludeId: clientId,
      )) {
        showError('Número do contador já existe');
        return false;
      }

      final client = selectedClient.value!.copyWith(
        name: name.value.trim(),
        contact: contact.value.trim(),
        reference: reference.value.trim().toUpperCase(),
        counterNumber: counterNumber.value.trim(),
        updatedAt: DateTime.now(),
      );

      await _clientRepository.update(clientId, client);

      // Atualizar dados
      await loadClients(refresh: true);
      await loadStats();

      showSuccess('Cliente atualizado com sucesso!');

      // Aguardar um pouco para mostrar a mensagem antes de fechar
      await Future.delayed(const Duration(milliseconds: 1500));
      Get.back();

      return true;
    } catch (e) {
      handleException(e);
      return false;
    }
  }

  // Select client
  void selectClient(ClientModel client) {
    selectedClient.value = client;
    name.value = client.name;
    contact.value = client.contact;
    reference.value = client.reference;
    counterNumber.value = client.counterNumber;
  }

  // Deactivate client
  Future<void> deactivateClient(String clientId) async {
    try {
      showLoading('Desativando cliente...');

      final success = await _clientRepository.deactivateClient(clientId);

      if (success) {
        await loadClients(refresh: true);
        await loadStats();
        showSuccess('Cliente desativado com sucesso!');
      } else {
        showError('Erro ao desativar cliente');
      }
    } catch (e) {
      handleException(e);
    }
  }

  // Get client by reference
  Future<ClientModel?> getClientByReference(String ref) async {
    try {
      return await _clientRepository.findByReference(ref);
    } catch (e) {
      handleException(e);
      return null;
    }
  }

  // Get client by counter number
  Future<ClientModel?> getClientByCounterNumber(String counterNumber) async {
    try {
      return await _clientRepository.findByCounterNumber(counterNumber);
    } catch (e) {
      handleException(e);
      return null;
    }
  }

  // Clear form
  // Clear form - MÉTODO MELHORADO
  void clearForm() {
    name.value = '';
    contact.value = '';
    reference.value = '';
    counterNumber.value = '';
    selectedClient.value = null;

    // Força a atualização dos observáveis
    name.refresh();
    contact.refresh();
    reference.refresh();
    counterNumber.refresh();
  }

  // Form validation
  bool _validateForm() {
    if (name.value.trim().isEmpty) {
      showError('Nome é obrigatório');
      return false;
    }

    if (contact.value.trim().isEmpty) {
      showError('Contacto é obrigatório');
      return false;
    }

    if (reference.value.trim().isEmpty) {
      showError('Referência é obrigatória');
      return false;
    }

    if (counterNumber.value.trim().isEmpty) {
      showError('Número do contador é obrigatório');
      return false;
    }

    return true;
  }

  // Field validators
  String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Nome é obrigatório';
    }
    if (value.trim().length < 3) {
      return 'Nome deve ter pelo menos 3 caracteres';
    }
    return null;
  }

  String? validateContact(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Contacto é obrigatório';
    }
    return null;
  }

  String? validateReference(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Referência é obrigatória';
    }
    return null;
  }

  String? validateCounterNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Número do contador é obrigatório';
    }
    return null;
  }

  // Refresh data
  Future<void> refreshData() async {
    await loadClients(refresh: true);
    await loadClientsWithDebt();
    await loadStats();
  }
}
