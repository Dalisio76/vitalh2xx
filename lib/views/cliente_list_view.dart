import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vitalh2x/controlers/client_controller.dart';
import 'package:vitalh2x/models/cliente_model.dart';

class ClientListView extends GetView<ClientController> {
  const ClientListView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista de Clientes'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchDialog(),
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterOptions(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.refreshData(),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildStatsBar(),
          _buildQuickFilters(),
          Expanded(child: _buildClientsList()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.toNamed('/client-form'),
        icon: const Icon(Icons.person_add),
        label: const Text('Novo Cliente'),
        backgroundColor: Colors.blue[600],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Buscar por nome, referência ou contacto...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          filled: true,
          fillColor: Colors.grey[50],
          suffixIcon: Obx(() {
            if (controller.searchTerm.value.isNotEmpty) {
              return IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () => _clearSearch(),
              );
            }
            return const SizedBox.shrink();
          }),
        ),
        onChanged: (value) => controller.searchTerm.value = value,
      ),
    );
  }

  Widget _buildStatsBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        border: Border(bottom: BorderSide(color: Colors.blue[200]!)),
      ),
      child: Obx(() {
        final stats = controller.stats.value;
        final total = stats['total'] ?? 0;
        final active = stats['active'] ?? 0;
        final withDebt = stats['with_debt'] ?? 0;

        return Row(
          children: [
            Expanded(
              child: _buildStatItem(
                'Total',
                '$total',
                Icons.people,
                Colors.blue,
              ),
            ),
            Container(height: 30, width: 1, color: Colors.blue[300]),
            Expanded(
              child: _buildStatItem(
                'Ativos',
                '$active',
                Icons.check,
                Colors.green,
              ),
            ),
            Container(height: 30, width: 1, color: Colors.blue[300]),
            Expanded(
              child: _buildStatItem(
                'Com Dívida',
                '$withDebt',
                Icons.warning,
                Colors.red,
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(label, style: const TextStyle(fontSize: 11)),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('Todos', () => _filterAll()),
            const SizedBox(width: 8),
            _buildFilterChip('Ativos', () => _filterActive()),
            const SizedBox(width: 8),
            _buildFilterChip('Com Dívida', () => _filterWithDebt()),
            const SizedBox(width: 8),
            _buildFilterChip('Limpar', () => _clearFilters(), isReset: true),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    VoidCallback onPressed, {
    bool isReset = false,
  }) {
    return ActionChip(
      label: Text(label),
      onPressed: onPressed,
      backgroundColor: isReset ? Colors.red[100] : Colors.blue[100],
      labelStyle: TextStyle(
        color: isReset ? Colors.red[800] : Colors.blue[800],
        fontSize: 12,
      ),
    );
  }

  Widget _buildClientsList() {
    return Obx(() {
      if (controller.isLoading) {
        return const Center(child: CircularProgressIndicator());
      }

      final clients = controller.filteredClients.value;
      if (clients.isEmpty) {
        return _buildEmptyState();
      }

      return RefreshIndicator(
        onRefresh: () => controller.refreshData(),
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: clients.length + (controller.hasMoreData.value ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == clients.length) {
              // Load more indicator
              controller.loadMoreClients();
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            final client = clients[index];
            return _buildClientCard(client, index);
          },
        ),
      );
    });
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Obx(() {
            if (controller.searchTerm.value.isNotEmpty) {
              return Column(
                children: [
                  Text(
                    'Nenhum cliente encontrado',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Não encontramos clientes com "${controller.searchTerm.value}"',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => _clearSearch(),
                    child: const Text('Limpar busca'),
                  ),
                ],
              );
            } else {
              return Column(
                children: [
                  Text(
                    'Nenhum cliente cadastrado',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Comece adicionando seu primeiro cliente',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              );
            }
          }),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Get.toNamed('/client-form'),
            icon: const Icon(Icons.person_add),
            label: const Text('Primeiro Cliente'),
          ),
        ],
      ),
    );
  }

  Widget _buildClientCard(ClientModel client, int index) {
    final hasDebt = client.totalDebt > 0;
    final isInactive = !client.isActive;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: hasDebt ? 3 : 1,
      color: isInactive ? Colors.grey[100] : null,
      child: InkWell(
        onTap: () => Get.toNamed('/client-detail', arguments: client),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Hero(
                    tag: 'client_avatar_$index',
                    child: CircleAvatar(
                      backgroundColor: _getClientColor(client).withOpacity(0.1),
                      child: Text(
                        client.name.isNotEmpty
                            ? client.name[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          color: _getClientColor(client),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                client.name,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isInactive ? Colors.grey[600] : null,
                                ),
                              ),
                            ),
                            if (hasDebt)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red[600],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text(
                                  'DÍVIDA',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            if (isInactive)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey[600],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text(
                                  'INATIVO',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        Text(
                          'Ref: ${client.reference}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) => _handleClientAction(value, client),
                    itemBuilder:
                        (context) => [
                          const PopupMenuItem(
                            value: 'view',
                            child: ListTile(
                              leading: Icon(Icons.visibility),
                              title: Text('Ver Detalhes'),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'edit',
                            child: ListTile(
                              leading: Icon(Icons.edit),
                              title: Text('Editar'),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'reading',
                            child: ListTile(
                              leading: Icon(Icons.speed),
                              title: Text('Nova Leitura'),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          if (hasDebt)
                            const PopupMenuItem(
                              value: 'payment',
                              child: ListTile(
                                leading: Icon(Icons.payment),
                                title: Text('Processar Pagamento'),
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          PopupMenuItem(
                            value: client.isActive ? 'deactivate' : 'activate',
                            child: ListTile(
                              leading: Icon(
                                client.isActive
                                    ? Icons.block
                                    : Icons.check_circle,
                                color:
                                    client.isActive ? Colors.red : Colors.green,
                              ),
                              title: Text(
                                client.isActive ? 'Desativar' : 'Ativar',
                              ),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildClientInfo(
                      'Contacto',
                      client.contact.isNotEmpty ? client.contact : 'N/A',
                      Icons.phone,
                    ),
                  ),
                  Expanded(
                    child: _buildClientInfo(
                      'Contador',
                      client.counterNumber,
                      Icons.electrical_services,
                    ),
                  ),
                  Expanded(
                    child: _buildClientInfo(
                      'Última Leitura',
                      client.lastReading?.toStringAsFixed(0) ?? 'N/A',
                      Icons.speed,
                    ),
                  ),
                  if (hasDebt)
                    Expanded(
                      child: _buildClientInfo(
                        'Dívida',
                        '${client.totalDebt.toStringAsFixed(2)} MT',
                        Icons.monetization_on,
                        color: Colors.red,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClientInfo(
    String label,
    String value,
    IconData icon, {
    Color? color,
  }) {
    return Column(
      children: [
        Icon(icon, size: 16, color: color ?? Colors.grey[600]),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  void _showSearchDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Buscar Clientes'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Nome do Cliente',
                hintText: 'Digite o nome...',
                prefixIcon: Icon(Icons.person_search),
              ),
              onChanged: (value) => controller.searchTerm.value = value,
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Referência',
                hintText: 'Digite a referência...',
                prefixIcon: Icon(Icons.tag),
              ),
              onChanged: (value) => controller.searchTerm.value = value,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Fechar')),
        ],
      ),
    );
  }

  void _showFilterOptions() {
    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Filtros Avançados',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              SwitchListTile(
                title: const Text('Mostrar apenas ativos'),
                value: controller.showOnlyActive.value,
                onChanged: (value) {
                  controller.showOnlyActive.value = value;
                  controller.filterClients();
                },
              ),
              SwitchListTile(
                title: const Text('Mostrar apenas com dívida'),
                value: controller.showOnlyWithDebt.value,
                onChanged: (value) {
                  controller.showOnlyWithDebt.value = value;
                  controller.filterClients();
                },
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Get.back();
                        _clearFilters();
                      },
                      child: const Text('Limpar Filtros'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Get.back(),
                      child: const Text('Aplicar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleClientAction(String action, ClientModel client) {
    switch (action) {
      case 'view':
        Get.toNamed('/client-detail', arguments: client);
        break;
      case 'edit':
        controller.selectClient(client);
        Get.toNamed('/client-form', arguments: client);
        break;
      case 'reading':
        Get.toNamed('/reading-form', arguments: client);
        break;
      case 'payment':
        Get.toNamed('/payment-form', arguments: client);
        break;
      case 'activate':
        // TODO: Implement activate method in controller
        controller.showSuccess('Ativação em desenvolvimento');
        break;
      case 'deactivate':
        _confirmDeactivateClient(client);
        break;
    }
  }

  void _confirmDeactivateClient(ClientModel client) {
    Get.dialog(
      AlertDialog(
        title: const Text('Desativar Cliente'),
        content: Text(
          'Deseja desativar o cliente ${client.name}?\n\nEle não aparecerá mais nas listas de clientes ativos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.deactivateClient(client.id!);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Desativar'),
          ),
        ],
      ),
    );
  }

  // Filter methods
  void _filterAll() {
    controller.showOnlyActive.value = false;
    controller.showOnlyWithDebt.value = false;
    controller.filterClients();
  }

  void _filterActive() {
    controller.showOnlyActive.value = true;
    controller.showOnlyWithDebt.value = false;
    controller.filterClients();
  }

  void _filterWithDebt() {
    controller.showOnlyActive.value = false;
    controller.showOnlyWithDebt.value = true;
    controller.filterClients();
  }

  void _clearFilters() {
    controller.showOnlyActive.value = true;
    controller.showOnlyWithDebt.value = false;
    controller.searchTerm.value = '';
    controller.filterClients();
  }

  void _clearSearch() {
    controller.searchTerm.value = '';
  }

  // Helper methods
  Color _getClientColor(ClientModel client) {
    if (!client.isActive) return Colors.grey;
    if (client.totalDebt > 0) return Colors.red;
    return Colors.green;
  }
}
