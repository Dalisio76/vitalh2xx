import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vitalh2x/controlers/reading_controller.dart';
import 'package:vitalh2x/models/cliente_model.dart';
import 'package:vitalh2x/models/leitura_model.dart';
import 'package:vitalh2x/models/metodo_pagamento_model.dart';

class MonthlyReadingsView extends GetView<ReadingController> {
  const MonthlyReadingsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leituras Mensais'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _selectMonth(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.refreshData(),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildHeader(),
          _buildProgressBar(),
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

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        border: Border(bottom: BorderSide(color: Colors.blue[200]!)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Obx(
                () => Text(
                  '${_getMonthName(controller.currentMonth.value)} ${controller.currentYear.value}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Obx(() {
                final stats = controller.monthlyStats.value;
                final total = stats['total_readings'] ?? 0;
                final completed = stats['completed_readings'] ?? 0;
                return Text(
                  '$completed/$total',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 12),
          Obx(() {
            final stats = controller.monthlyStats.value;
            return Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Concluídas',
                    '${stats['completed_readings'] ?? 0}',
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard(
                    'Pendentes',
                    '${stats['pending_readings'] ?? 0}',
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard(
                    'Total m³',
                    '${(stats['total_consumption'] ?? 0.0).toStringAsFixed(1)}',
                    Colors.blue,
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Obx(() {
      final stats = controller.monthlyStats.value;
      final total = stats['total_readings'] ?? 0;
      final completed = stats['completed_readings'] ?? 0;
      final progress = total > 0 ? completed / total : 0.0;

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Progresso das Leituras',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                Text(
                  '${(progress * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                progress == 1.0 ? Colors.green : Colors.blue,
              ),
              minHeight: 8,
            ),
          ],
        ),
      );
    });
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
            return _buildReadingCard(reading);
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
          Text(
            'Selecione um período diferente ou\ninicie as leituras do mês',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Get.toNamed('/reading-form'),
            icon: const Icon(Icons.add),
            label: const Text('Nova Leitura'),
          ),
        ],
      ),
    );
  }

  Widget _buildReadingCard(ReadingModel reading) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showReadingDetails(reading),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: _getStatusColor(reading).withOpacity(0.1),
                    child: Icon(
                      _getStatusIcon(reading),
                      color: _getStatusColor(reading),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FutureBuilder<ClientModel?>(
                      future: _getClientInfo(reading.clientId),
                      builder: (context, snapshot) {
                        final client = snapshot.data;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              client?.name ?? 'Carregando...',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Ref: ${client?.reference ?? 'N/A'}',
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
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(reading).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getStatusText(reading),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _getStatusColor(reading),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildReadingInfo(
                      'Leitura Atual',
                      reading.currentReading.toStringAsFixed(0),
                      Icons.speed,
                    ),
                  ),
                  Expanded(
                    child: _buildReadingInfo(
                      'Consumo',
                      controller.formattedConsumption,
                      Icons.water_drop,
                    ),
                  ),
                  Expanded(
                    child: _buildReadingInfo(
                      'Valor',
                      controller.formattedBillAmount,
                      Icons.monetization_on,
                    ),
                  ),
                ],
              ),
              if (reading.notes?.isNotEmpty == true) ...[
                const SizedBox(height: 12),
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
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Color _getStatusColor(ReadingModel reading) {
    switch (reading.paymentStatus) {
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

  IconData _getStatusIcon(ReadingModel reading) {
    switch (reading.paymentStatus) {
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

  String _getStatusText(ReadingModel reading) {
    switch (reading.paymentStatus) {
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

  Future<ClientModel?> _getClientInfo(String clientId) async {
    // Implementar busca de cliente - pode usar um controller separado ou repository
    // Por enquanto retorna null, mas deveria buscar do repository
    return null;
  }

  void _selectMonth(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
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

  void _showReadingDetails(ReadingModel reading) {
    Get.bottomSheet(
      Container(
        height: Get.height * 0.6,
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
                      if (reading.paymentStatus == PaymentStatus.pending)
                        IconButton(
                          onPressed: () {
                            Get.back();
                            controller.selectReading(reading);
                            Get.toNamed('/reading-form');
                          },
                          icon: const Icon(Icons.edit),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailItem('Mês/Ano', reading.monthYear),
                      _buildDetailItem(
                        'Leitura Anterior',
                        reading.previousReading.toStringAsFixed(0),
                      ),
                      _buildDetailItem(
                        'Leitura Atual',
                        reading.currentReading.toStringAsFixed(0),
                      ),
                      _buildDetailItem(
                        'Consumo',
                        controller.formattedConsumption,
                      ),
                      _buildDetailItem(
                        'Valor da Conta',
                        controller.formattedBillAmount,
                      ),
                      _buildDetailItem('Status', _getStatusText(reading)),
                      _buildDetailItem(
                        'Data da Leitura',
                        _formatDate(reading.readingDate),
                      ),
                      if (reading.paymentDate != null)
                        _buildDetailItem(
                          'Data do Pagamento',
                          _formatDate(reading.paymentDate!),
                        ),
                      if (reading.notes?.isNotEmpty == true)
                        _buildDetailItem('Observações', reading.notes!),
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

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
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

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
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
}
