import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vitalh2x/controlers/client_controller.dart';
import 'package:vitalh2x/models/cliente_model.dart';
import 'package:vitalh2x/utils/app_styles.dart';

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
              expandedHeight: 160.0,
              floating: false,
              pinned: true,
              backgroundColor: AppStyles.primaryColor,
              foregroundColor: Colors.white,
              toolbarHeight: 48,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  client.name,
                  style: AppStyles.compactTitle.copyWith(
                    color: Colors.white,
                    fontSize: AppStyles.fontSizeTitle,
                  ),
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [AppStyles.primaryColor, AppStyles.primaryColor.withOpacity(0.8)],
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 30),
                      Hero(
                        tag: 'client_avatar_${client.id}',
                        child: CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.white,
                          child: Text(
                            client.name.isNotEmpty
                                ? client.name[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppStyles.primaryColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: client.isActive ? AppStyles.secondaryColor : AppStyles.errorColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          client.isActive ? 'ATIVO' : 'INATIVO',
                          style: AppStyles.compactCaption.copyWith(
                            color: Colors.white,
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
          padding: const EdgeInsets.all(AppStyles.paddingLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildClientInfo(client),
              const SizedBox(height: AppStyles.paddingXLarge),
              _buildQuickActions(client),
              const SizedBox(height: AppStyles.paddingXLarge),
              _buildStatsCards(client),
              const SizedBox(height: AppStyles.paddingXLarge),
              _buildTabSection(client),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClientInfo(ClientModel client) {
    return Card(
      margin: const EdgeInsets.all(AppStyles.paddingSmall),
      child: Padding(
        padding: const EdgeInsets.all(AppStyles.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informações do Cliente',
              style: AppStyles.compactTitle,
            ),
            const SizedBox(height: AppStyles.paddingLarge),
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
      padding: const EdgeInsets.symmetric(vertical: AppStyles.paddingSmall),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: AppStyles.paddingMedium),
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: AppStyles.compactSubtitle,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppStyles.compactBody,
            ),
          ),
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
            icon: const Icon(Icons.speed, size: 16),
            label: const Text('Nova Leitura'),
            style: AppStyles.compactButtonStyle(
              backgroundColor: AppStyles.primaryColor,
            ),
          ),
        ),
        const SizedBox(width: AppStyles.paddingMedium),
        Expanded(
          child: ElevatedButton.icon(
            onPressed:
                client.totalDebt > 0
                    ? () => Get.toNamed('/payment-form', arguments: client)
                    : null,
            icon: const Icon(Icons.payment, size: 16),
            label: const Text('Pagamento'),
            style: AppStyles.compactButtonStyle(
              backgroundColor:
                  client.totalDebt > 0 ? AppStyles.secondaryColor : Colors.grey,
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
        const SizedBox(width: AppStyles.paddingMedium),
        Expanded(
          child: _buildStatCard(
            'Total Leituras',
            '0', // TODO: Implementar contagem real
            Icons.speed,
            AppStyles.primaryColor,
          ),
        ),
        const SizedBox(width: AppStyles.paddingMedium),
        Expanded(
          child: _buildStatCard(
            'Pagamentos',
            '0', // TODO: Implementar contagem real
            Icons.payment,
            AppStyles.secondaryColor,
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
      margin: const EdgeInsets.all(AppStyles.paddingSmall),
      child: Padding(
        padding: const EdgeInsets.all(AppStyles.paddingMedium),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: AppStyles.paddingSmall),
            Text(
              value,
              style: AppStyles.compactSubtitle.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: AppStyles.compactCaption,
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
            height: 320,
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
          Icon(Icons.speed_outlined, size: 40, color: Colors.grey[400]),
          const SizedBox(height: AppStyles.paddingLarge),
          Text(
            'Leituras do Cliente',
            style: AppStyles.compactTitle.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: AppStyles.paddingSmall),
          Text(
            'As leituras deste cliente aparecerão aqui',
            style: AppStyles.compactCaption.copyWith(
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: AppStyles.paddingLarge),
          ElevatedButton.icon(
            onPressed: () => Get.toNamed('/reading-form', arguments: client),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Nova Leitura'),
            style: AppStyles.compactButtonStyle(),
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
          Icon(Icons.payment_outlined, size: 40, color: Colors.grey[400]),
          const SizedBox(height: AppStyles.paddingLarge),
          Text(
            'Pagamentos do Cliente',
            style: AppStyles.compactTitle.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: AppStyles.paddingSmall),
          Text(
            'O histórico de pagamentos aparecerá aqui',
            style: AppStyles.compactCaption.copyWith(
              color: Colors.grey[500],
            ),
          ),
          if (client.totalDebt > 0) ...[
            const SizedBox(height: AppStyles.paddingLarge),
            ElevatedButton.icon(
              onPressed: () => Get.toNamed('/payment-form', arguments: client),
              icon: const Icon(Icons.payment, size: 16),
              label: const Text('Processar Pagamento'),
              style: AppStyles.compactButtonStyle(
                backgroundColor: AppStyles.secondaryColor,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHistoryTab(ClientModel client) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppStyles.paddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resumo da Atividade',
            style: AppStyles.compactSubtitle,
          ),
          const SizedBox(height: AppStyles.paddingLarge),
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
          const SizedBox(height: AppStyles.paddingXLarge),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _generateClientReport(client),
                  icon: const Icon(Icons.summarize, size: 16),
                  label: const Text('Relatório'),
                  style: AppStyles.compactButtonStyle(),
                ),
              ),
              const SizedBox(width: AppStyles.paddingMedium),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _exportClientData(client),
                  icon: const Icon(Icons.download, size: 16),
                  label: const Text('Exportar'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    minimumSize: const Size(80, AppStyles.buttonHeightMedium),
                    side: BorderSide(color: AppStyles.primaryColor),
                    textStyle: const TextStyle(
                      fontSize: AppStyles.fontSizeMedium,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
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
      margin: const EdgeInsets.only(bottom: AppStyles.paddingSmall),
      child: ListTile(
        leading: CircleAvatar(
          radius: 16,
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color, size: 16),
        ),
        title: Text(
          title,
          style: AppStyles.compactSubtitle,
        ),
        subtitle: Text(
          subtitle,
          style: AppStyles.compactCaption,
        ),
        dense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppStyles.paddingLarge,
          vertical: AppStyles.paddingSmall,
        ),
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
