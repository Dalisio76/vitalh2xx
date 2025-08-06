import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vitalh2x/controlers/reading_controller.dart';
import 'package:vitalh2x/models/leitura_model.dart';
import 'package:vitalh2x/models/cliente_model.dart';
import 'package:vitalh2x/models/metodo_pagamento_model.dart';

class ReadingListView extends GetView<ReadingController> {
  const ReadingListView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista de Leituras'),
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
            icon: const Icon(Icons.calendar_month),
            onPressed: () => _selectMonth(),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildPeriodHeader(),
          _buildStatsBar(),
          _buildQuickFilters(),
          Expanded(child: _buildReadingsList()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.toNamed('/reading-form'),
        icon: const Icon(Icons.speed),
        label: const Text('Nova Leitura'),
        backgroundColor: Colors.blue[600],
      ),
    );
  }

  Widget _buildPeriodHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        border: Border(bottom: BorderSide(color: Colors.blue[200]!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Obx(
            () => Text(
              '${_getMonthName(controller.currentMonth.value)} ${controller.currentYear.value}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            onPressed: () => _selectMonth(),
            icon: const Icon(Icons.edit_calendar),
            style: IconButton.styleFrom(backgroundColor: Colors.blue[100]),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.blue[100],
        border: Border(bottom: BorderSide(color: Colors.blue[200]!)),
      ),
      child: Obx(() {
        final stats = controller.monthlyStats.value;
        final totalReadings = stats['total_readings'] ?? 0;
        final totalConsumption = (stats['total_consumption'] ?? 0.0).toDouble();
        final pendingReadings = stats['pending_readings'] ?? 0;

        return Row(
          children: [
            Expanded(
              child: _buildStatItem(
                'Total Leituras',
                '$totalReadings',
                Icons.speed,
                Colors.blue,
              ),
            ),
            Container(height: 40, width: 1, color: Colors.blue[300]),
            Expanded(
              child: _buildStatItem(
                'Total Consumo',
                '${totalConsumption.toStringAsFixed(1)}m³',
                Icons.water_drop,
                Colors.cyan,
              ),
            ),
            Container(height: 40, width: 1, color: Colors.blue[300]),
            Expanded(
              child: _buildStatItem(
                'Pendentes',
                '$pendingReadings',
                Icons.pending,
                Colors.orange,
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
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
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
    );
  }

  Widget _buildQuickFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('Todas', () => _filterAll()),
            const SizedBox(width: 8),
            _buildFilterChip('Pagas', () => _filterPaid()),
            const SizedBox(width: 8),
            _buildFilterChip('Pendentes', () => _filterPending()),
            const SizedBox(width: 8),
            _buildFilterChip('Atrasadas', () => _filterOverdue()),
            const SizedBox(width: 8),
            _buildFilterChip('Este Mês', () => _filterCurrentMonth()),
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

  Widget _buildReadingsList() {
    return Obx(() {
      if (controller.isLoading) {
        return const Center(child: CircularProgressIndicator());
      }

      final readings = controller.monthlyReadings.value;
      if (readings.isEmpty) {
        return _buildEmptyState();
      }

      return RefreshIndicator(
        onRefresh: () => controller.refreshData(),
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: readings.length,
          itemBuilder: (context, index) {
            final reading = readings[index];
            return _buildReadingCard(reading, index);
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
          Icon(Icons.speed_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Nenhuma leitura encontrada',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Obx(
            () => Text(
              'Não há leituras para ${_getMonthName(controller.currentMonth.value)} ${controller.currentYear.value}',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Get.toNamed('/reading-form'),
            icon: const Icon(Icons.add),
            label: const Text('Primeira Leitura'),
          ),
        ],
      ),
    );
  }

  Widget _buildReadingCard(ReadingModel reading, int index) {
    final isOverdue = reading.paymentStatus == PaymentStatus.overdue;
    final isPaid = reading.paymentStatus == PaymentStatus.paid;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isOverdue ? 4 : 1,
      color: isOverdue ? Colors.red[50] : null,
      child: InkWell(
        onTap: () => _showReadingActions(reading),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Hero(
                    tag: 'reading_$index',
                    child: CircleAvatar(
                      backgroundColor: _getStatusColor(
                        reading.paymentStatus,
                      ).withOpacity(0.1),
                      child: Icon(
                        _getStatusIcon(reading.paymentStatus),
                        color: _getStatusColor(reading.paymentStatus),
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FutureBuilder<String>(
                      future: _getClientName(reading.clientId),
                      builder: (context, snapshot) {
                        final clientName = snapshot.data ?? 'Carregando...';
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    clientName,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                if (isOverdue)
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
                                      'ATRASO',
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
                              'Período: ${reading.month}/${reading.year}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${reading.billAmount.toStringAsFixed(2)} MT',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _getStatusColor(reading.paymentStatus),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(
                            reading.paymentStatus,
                          ).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _getStatusText(reading.paymentStatus),
                          style: TextStyle(
                            color: _getStatusColor(reading.paymentStatus),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
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
                    child: _buildReadingInfo(
                      'Anterior',
                      reading.previousReading.toStringAsFixed(0),
                      Icons.history,
                    ),
                  ),
                  Expanded(
                    child: _buildReadingInfo(
                      'Atual',
                      reading.currentReading.toStringAsFixed(0),
                      Icons.speed,
                    ),
                  ),
                  Expanded(
                    child: _buildReadingInfo(
                      'Consumo',
                      '${reading.consumption.toStringAsFixed(1)}m³',
                      Icons.water_drop,
                    ),
                  ),
                  Expanded(
                    child: _buildReadingInfo(
                      'Data',
                      _formatDate(reading.readingDate),
                      Icons.calendar_today,
                    ),
                  ),
                ],
              ),
              if (reading.notes?.isNotEmpty == true) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.note, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          reading.notes!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReadingInfo(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
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

  void _showReadingActions(ReadingModel reading) {
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Ações da Leitura',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.visibility, color: Colors.blue),
                title: const Text('Ver Detalhes'),
                onTap: () {
                  Get.back();
                  _showReadingDetails(reading);
                },
              ),
              if (reading.paymentStatus == PaymentStatus.pending) ...[
                ListTile(
                  leading: const Icon(Icons.edit, color: Colors.green),
                  title: const Text('Editar Leitura'),
                  onTap: () {
                    Get.back();
                    controller.selectReading(reading);
                    Get.toNamed('/reading-form');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.payment, color: Colors.orange),
                  title: const Text('Processar Pagamento'),
                  onTap: () {
                    Get.back();
                    _processPayment(reading);
                  },
                ),
              ],
              ListTile(
                leading: const Icon(Icons.print, color: Colors.purple),
                title: const Text('Imprimir Conta'),
                onTap: () {
                  Get.back();
                  _printBill(reading);
                },
              ),
              ListTile(
                leading: const Icon(Icons.person, color: Colors.indigo),
                title: const Text('Ver Cliente'),
                onTap: () {
                  Get.back();
                  _viewClient(reading.clientId);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSearchDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Buscar Leituras'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Nome do Cliente',
                hintText: 'Digite o nome...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                // TODO: Implement search functionality
              },
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Referência do Cliente',
                hintText: 'Digite a referência...',
                prefixIcon: Icon(Icons.tag),
              ),
              onChanged: (value) {
                // TODO: Implement reference search
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              // TODO: Execute search
            },
            child: const Text('Buscar'),
          ),
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
              const Text(
                'Por Status de Pagamento:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  FilterChip(
                    label: const Text('Pagas'),
                    selected: false, // TODO: Implement selection state
                    onSelected: (selected) => _filterPaid(),
                  ),
                  FilterChip(
                    label: const Text('Pendentes'),
                    selected: false,
                    onSelected: (selected) => _filterPending(),
                  ),
                  FilterChip(
                    label: const Text('Atrasadas'),
                    selected: false,
                    onSelected: (selected) => _filterOverdue(),
                  ),
                  FilterChip(
                    label: const Text('Parciais'),
                    selected: false,
                    onSelected: (selected) => _filterPartial(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Por Consumo:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  FilterChip(
                    label: const Text('Baixo (<5m³)'),
                    selected: false,
                    onSelected: (selected) => _filterLowConsumption(),
                  ),
                  FilterChip(
                    label: const Text('Médio (5-15m³)'),
                    selected: false,
                    onSelected: (selected) => _filterMediumConsumption(),
                  ),
                  FilterChip(
                    label: const Text('Alto (>15m³)'),
                    selected: false,
                    onSelected: (selected) => _filterHighConsumption(),
                  ),
                ],
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

  void _showReadingDetails(ReadingModel reading) {
    Get.bottomSheet(
      Container(
        height: Get.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Detalhes da Leitura',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => _printBill(reading),
                        icon: const Icon(Icons.print),
                      ),
                      IconButton(
                        onPressed: () => Get.back(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildDetailCard(
                        'Informações da Leitura',
                        [
                          _buildDetailRow(
                            'Período',
                            '${reading.month}/${reading.year}',
                          ),
                          _buildDetailRow(
                            'Leitura Anterior',
                            reading.previousReading.toStringAsFixed(0),
                          ),
                          _buildDetailRow(
                            'Leitura Atual',
                            reading.currentReading.toStringAsFixed(0),
                          ),
                          _buildDetailRow(
                            'Consumo',
                            '${reading.consumption.toStringAsFixed(1)}m³',
                          ),
                          _buildDetailRow(
                            'Data da Leitura',
                            _formatDateTime(reading.readingDate),
                          ),
                          if (reading.notes?.isNotEmpty == true)
                            _buildDetailRow('Observações', reading.notes!),
                        ],
                        Icons.speed,
                        Colors.blue,
                      ),
                      const SizedBox(height: 16),
                      _buildDetailCard(
                        'Informações Financeiras',
                        [
                          _buildDetailRow(
                            'Valor da Conta',
                            '${reading.billAmount.toStringAsFixed(2)} MT',
                          ),
                          _buildDetailRow(
                            'Status do Pagamento',
                            _getStatusText(reading.paymentStatus),
                          ),
                          if (reading.paymentDate != null)
                            _buildDetailRow(
                              'Data do Pagamento',
                              _formatDateTime(reading.paymentDate!),
                            ),
                        ],
                        Icons.monetization_on,
                        _getStatusColor(reading.paymentStatus),
                      ),
                      const SizedBox(height: 16),
                      FutureBuilder<String>(
                        future: _getClientName(reading.clientId),
                        builder: (context, snapshot) {
                          final clientName = snapshot.data ?? 'Carregando...';
                          return _buildDetailCard(
                            'Informações do Cliente',
                            [
                              _buildDetailRow('Nome', clientName),
                              _buildDetailRow('ID', reading.clientId),
                            ],
                            Icons.person,
                            Colors.green,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailCard(
    String title,
    List<Widget> children,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _selectMonth() async {
    final DateTime? picked = await showDatePicker(
      context: Get.context!,
      initialDate: DateTime(
        controller.currentYear.value,
        controller.currentMonth.value,
      ),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      controller.changeMonth(picked.month, picked.year);
    }
  }

  // Filter methods
  void _filterAll() {
    controller.refreshData();
    controller.showSuccess('Mostrando todas as leituras');
  }

  void _filterPaid() {
    // TODO: Implement filter
    controller.showSuccess('Filtro aplicado: Pagas');
  }

  void _filterPending() {
    // TODO: Implement filter
    controller.showSuccess('Filtro aplicado: Pendentes');
  }

  void _filterOverdue() {
    // TODO: Implement filter
    controller.showSuccess('Filtro aplicado: Atrasadas');
  }

  void _filterPartial() {
    // TODO: Implement filter
    controller.showSuccess('Filtro aplicado: Parciais');
  }

  void _filterCurrentMonth() {
    final now = DateTime.now();
    controller.changeMonth(now.month, now.year);
  }

  void _filterLowConsumption() {
    // TODO: Implement consumption filter
    controller.showSuccess('Filtro aplicado: Baixo consumo');
  }

  void _filterMediumConsumption() {
    // TODO: Implement consumption filter
    controller.showSuccess('Filtro aplicado: Médio consumo');
  }

  void _filterHighConsumption() {
    // TODO: Implement consumption filter
    controller.showSuccess('Filtro aplicado: Alto consumo');
  }

  void _clearFilters() {
    controller.refreshData();
    controller.showSuccess('Filtros removidos');
  }

  // Action methods
  void _processPayment(ReadingModel reading) {
    // Navigate to payment form with pre-selected reading
    Get.toNamed('/payment-form', arguments: reading);
  }

  void _printBill(ReadingModel reading) {
    controller.showSuccess('Conta enviada para impressão');
    // TODO: Implement print functionality
  }

  void _viewClient(String clientId) {
    Get.toNamed('/client-detail', arguments: clientId);
  }

  // Helper methods
  Color _getStatusColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.paid:
        return Colors.green;
      case PaymentStatus.partial:
        return Colors.blue;
      case PaymentStatus.overdue:
        return Colors.red;
      case PaymentStatus.pending:
      default:
        return Colors.orange;
    }
  }

  IconData _getStatusIcon(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.paid:
        return Icons.check_circle;
      case PaymentStatus.partial:
        return Icons.paid;
      case PaymentStatus.overdue:
        return Icons.warning;
      case PaymentStatus.pending:
      default:
        return Icons.pending;
    }
  }

  String _getStatusText(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.paid:
        return 'PAGO';
      case PaymentStatus.partial:
        return 'PARCIAL';
      case PaymentStatus.overdue:
        return 'ATRASADO';
      case PaymentStatus.pending:
      default:
        return 'PENDENTE';
    }
  }

  Future<String> _getClientName(String clientId) async {
    // TODO: Implement client name lookup
    // This should use a client repository or controller to get client name
    return 'Cliente $clientId';
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatDateTime(DateTime date) {
    return '${_formatDate(date)} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _getMonthName(int month) {
    const months = [
      'Janeiro',
      'Fevereiro',
      'Março',
      'Abril',
      'Maio',
      'Junho',
      'Julho',
      'Agosto',
      'Setembro',
      'Outubro',
      'Novembro',
      'Dezembro',
    ];
    return months[month - 1];
  }

  @override
  void onInit() {
    // super.onInit();
    // Load data when view initializes
    controller.loadMonthlyReadings();
    controller.loadMonthlyStats();
  }
}
