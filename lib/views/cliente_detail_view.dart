import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vitalh2x/controlers/client_controller.dart';
import 'package:vitalh2x/models/cliente_model.dart';
import 'package:vitalh2x/models/leitura_model.dart';
import 'package:vitalh2x/models/pagamento_model.dart';

class ClientDetailView extends GetView<ClientController> {
  const ClientDetailView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ClientModel client = Get.arguments as ClientModel;

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            SliverAppBar(
              expandedHeight: 200.0,
              floating: false,
              pinned: true,
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  client.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.blue[600]!, Colors.blue[800]!],
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      Hero(
                        tag: 'client_avatar_${client.id}',
                        child: CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.white,
                          child: Text(
                            client.name.isNotEmpty
                                ? client.name[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[800],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: client.isActive ? Colors.green : Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          client.isActive ? 'ATIVO' : 'INATIVO',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                PopupMenuButton<String>(
                  onSelected: (value) => _handleAction(value, client),
                  itemBuilder:
                      (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: ListTile(
                            leading: Icon(Icons.edit),
                            title: Text('Editar'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'new_reading',
                          child: ListTile(
                            leading: Icon(Icons.speed),
                            title: Text('Nova Leitura'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        if (client.totalDebt > 0)
                          const PopupMenuItem(
                            value: 'payment',
                            child: ListTile(
                              leading: Icon(Icons.payment),
                              title: Text('Processar Pagamento'),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        const PopupMenuItem(
                          value: 'print',
                          child: ListTile(
                            leading: Icon(Icons.print),
                            title: Text('Imprimir Ficha'),
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
          ];
        },
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildClientInfo(client),
              const SizedBox(height: 20),
              _buildQuickActions(client),
              const SizedBox(height: 20),
              _buildStatsCards(client),
              const SizedBox(height: 20),
              _buildTabSection(client),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClientInfo(ClientModel client) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informações do Cliente',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Nome Completo', client.name, Icons.person),
            _buildInfoRow('Referência', client.reference, Icons.tag),
            _buildInfoRow(
              'Contacto',
              client.contact.isNotEmpty ? client.contact : 'Não informado',
              Icons.phone,
            ),
            _buildInfoRow(
              'Número do Contador',
              client.counterNumber,
              Icons.electrical_services,
            ),
            _buildInfoRow(
              'Última Leitura',
              client.lastReading != null
                  ? '${client.lastReading!.toStringAsFixed(1)}m³'
                  : 'Nenhuma leitura',
              Icons.speed,
            ),
            _buildInfoRow(
              'Data de Cadastro',
              _formatDate(client.createdAt),
              Icons.calendar_today,
            ),
            if (client.updatedAt != null)
              _buildInfoRow(
                'Última Atualização',
                _formatDate(client.updatedAt!),
                Icons.update,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildQuickActions(ClientModel client) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => Get.toNamed('/reading-form', arguments: client),
            icon: const Icon(Icons.speed),
            label: const Text('Nova Leitura'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed:
                client.totalDebt > 0
                    ? () => Get.toNamed('/payment-form', arguments: client)
                    : null,
            icon: const Icon(Icons.payment),
            label: const Text('Pagamento'),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  client.totalDebt > 0 ? Colors.green[600] : Colors.grey,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsCards(ClientModel client) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Dívida Total',
            '${client.totalDebt.toStringAsFixed(2)} MT',
            Icons.monetization_on,
            client.totalDebt > 0 ? Colors.red : Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Total Leituras',
            '0', // TODO: Implementar contagem real
            Icons.speed,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Pagamentos',
            '0', // TODO: Implementar contagem real
            Icons.payment,
            Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabSection(ClientModel client) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'Leituras', icon: Icon(Icons.speed)),
              Tab(text: 'Pagamentos', icon: Icon(Icons.payment)),
              Tab(text: 'Histórico', icon: Icon(Icons.history)),
            ],
          ),
          SizedBox(
            height: 400,
            child: TabBarView(
              children: [
                _buildReadingsTab(client),
                _buildPaymentsTab(client),
                _buildHistoryTab(client),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadingsTab(ClientModel client) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.speed_outlined, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Leituras do Cliente',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'As leituras deste cliente aparecerão aqui',
            style: TextStyle(color: Colors.grey[500]),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => Get.toNamed('/reading-form', arguments: client),
            icon: const Icon(Icons.add),
            label: const Text('Nova Leitura'),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentsTab(ClientModel client) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.payment_outlined, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Pagamentos do Cliente',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'O histórico de pagamentos aparecerá aqui',
            style: TextStyle(color: Colors.grey[500]),
          ),
          if (client.totalDebt > 0) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => Get.toNamed('/payment-form', arguments: client),
              icon: const Icon(Icons.payment),
              label: const Text('Processar Pagamento'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHistoryTab(ClientModel client) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resumo da Atividade',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildActivityCard(
            'Cliente Cadastrado',
            _formatDateTime(client.createdAt),
            Icons.person_add,
            Colors.blue,
          ),
          if (client.lastReading != null && client.lastReading! > 0)
            _buildActivityCard(
              'Leitura Inicial',
              'Leitura inicial: ${client.lastReading!.toStringAsFixed(1)}m³',
              Icons.speed,
              Colors.green,
            ),
          if (client.updatedAt != null)
            _buildActivityCard(
              'Última Atualização',
              _formatDateTime(client.updatedAt!),
              Icons.update,
              Colors.orange,
            ),
          if (client.totalDebt > 0)
            _buildActivityCard(
              'Situação Atual',
              'Dívida pendente: ${client.totalDebt.toStringAsFixed(2)} MT',
              Icons.warning,
              Colors.red,
            )
          else
            _buildActivityCard(
              'Situação Atual',
              'Cliente em dia com os pagamentos',
              Icons.check_circle,
              Colors.green,
            ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _generateClientReport(client),
                  icon: const Icon(Icons.summarize),
                  label: const Text('Relatório Completo'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _exportClientData(client),
                  icon: const Icon(Icons.download),
                  label: const Text('Exportar Dados'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
      ),
    );
  }

  void _handleAction(String action, ClientModel client) {
    switch (action) {
      case 'edit':
        controller.selectClient(client);
        Get.toNamed('/client-form', arguments: client);
        break;
      case 'new_reading':
        Get.toNamed('/reading-form', arguments: client);
        break;
      case 'payment':
        Get.toNamed('/payment-form', arguments: client);
        break;
      case 'print':
        _printClientSheet(client);
        break;
      case 'activate':
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
              Get.back(); // Volta para a lista
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

  void _printClientSheet(ClientModel client) {
    controller.showSuccess('Ficha do cliente enviada para impressão');
    // TODO: Implement print functionality
  }

  void _generateClientReport(ClientModel client) {
    controller.showSuccess('Gerando relatório completo do cliente...');
    // TODO: Implement report generation
  }

  void _exportClientData(ClientModel client) {
    controller.showSuccess('Exportando dados do cliente...');
    // TODO: Implement data export
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatDateTime(DateTime date) {
    return '${_formatDate(date)} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
