// ===== ÁREA EXCLUSIVA DE LEITURAS =====
// Tela focada apenas em leituras, sem funcionalidades de pagamento

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vitalh2x/controlers/reading_controller.dart';
import 'package:vitalh2x/controlers/auth_controller.dart';
import 'package:vitalh2x/models/leitura_model.dart';
import 'package:vitalh2x/models/metodo_pagamento_model.dart';
import 'package:vitalh2x/routs/rout.dart';

class ReadingsOnlyView extends StatefulWidget {
  const ReadingsOnlyView({Key? key}) : super(key: key);

  @override
  State<ReadingsOnlyView> createState() => _ReadingsOnlyViewState();
}

class _ReadingsOnlyViewState extends State<ReadingsOnlyView> {
  final ReadingController controller = Get.find<ReadingController>();
  final Set<String> selectedReadings = <String>{};
  bool selectAll = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leituras'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => Get.toNamed(Routes.DASHBOARD),
          ),
          IconButton(
            icon: const Icon(Icons.search, size: 20),
            onPressed: () => _showSearchDialog(),
          ),
          IconButton(
            icon: const Icon(Icons.calendar_month, size: 20),
            onPressed: () => _selectMonth(),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildPeriodHeader(),
          _buildReadingStats(),
          _buildBulkActions(),
          Expanded(child: _buildReadingsList()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.toNamed(Routes.READING_FORM),
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
        children: [
          Icon(Icons.speed, color: Colors.blue[700], size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Área de Leituras',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
                const SizedBox(height: 4),
                Obx(() => Text(
                  'Período: ${_getMonthName(controller.currentMonth.value)} ${controller.currentYear.value}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blue[600],
                  ),
                )),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _selectMonth(),
            icon: Icon(Icons.edit_calendar, color: Colors.blue[700]),
            style: IconButton.styleFrom(backgroundColor: Colors.blue[100]),
          ),
        ],
      ),
    );
  }

  Widget _buildReadingStats() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.blue[100],
        border: Border(bottom: BorderSide(color: Colors.blue[200]!)),
      ),
      child: Obx(() {
        final stats = controller.monthlyStats.value;
        final totalReadings = controller.monthlyReadings.length;
        final totalConsumption = controller.monthlyReadings.fold<double>(
          0.0, (sum, reading) => sum + reading.consumption,
        );

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
                'Consumo Total',
                '${totalConsumption.toStringAsFixed(1)}m³',
                Icons.water_drop,
                Colors.cyan,
              ),
            ),
            Container(height: 40, width: 1, color: Colors.blue[300]),
            Expanded(
              child: _buildStatItem(
                'Média',
                totalReadings > 0 ? '${(totalConsumption / totalReadings).toStringAsFixed(1)}m³' : '0m³',
                Icons.trending_up,
                Colors.green,
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

  Widget _buildBulkActions() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Checkbox(
                    value: selectAll,
                    onChanged: (value) {
                      setState(() {
                        selectAll = value ?? false;
                        if (selectAll) {
                          selectedReadings.addAll(
                            controller.monthlyReadings
                                .map((r) => r.id!)
                                .where((id) => id != null)
                                .cast<String>(),
                          );
                        } else {
                          selectedReadings.clear();
                        }
                      });
                    },
                  ),
                  const Text('Selecionar Todas'),
                  const Spacer(),
                  Text('${selectedReadings.length} selecionadas'),
                ],
              ),
              if (selectedReadings.isNotEmpty) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _printSelectedReadings,
                        icon: const Icon(Icons.print, color: Colors.white),
                        label: const Text(
                          'Imprimir Leituras',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _exportSelectedReadings,
                        icon: const Icon(Icons.download, color: Colors.white),
                        label: const Text(
                          'Exportar Lista',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReadingsList() {
    return Obx(() {
      if (controller.isLoading) {
        return const Center(child: CircularProgressIndicator());
      }

      // Filtrar apenas leituras (todos os status)
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
            final isSelected = selectedReadings.contains(reading.id!);
            return _buildReadingCard(reading, index, isSelected);
          },
        ),
      );
    });
  }

  Widget _buildReadingCard(ReadingModel reading, int index, bool isSelected) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      color: isSelected ? Colors.blue[50] : null,
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
                  // Checkbox
                  Checkbox(
                    value: isSelected,
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          selectedReadings.add(reading.id!);
                        } else {
                          selectedReadings.remove(reading.id!);
                          selectAll = false;
                        }
                      });
                    },
                  ),
                  // Número sequencial
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Colors.blue,
                        ),
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
                            Text(
                              clientName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
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
                        '${reading.consumption.toStringAsFixed(1)} m³',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(reading.paymentStatus).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _getStatusColor(reading.paymentStatus).withOpacity(0.3)),
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
                      reading.previousReading.toStringAsFixed(1),
                      Icons.history,
                    ),
                  ),
                  Expanded(
                    child: _buildReadingInfo(
                      'Atual',
                      reading.currentReading.toStringAsFixed(1),
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
          Obx(() => Text(
            'Não há leituras para ${_getMonthName(controller.currentMonth.value)} ${controller.currentYear.value}',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          )),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Get.toNamed(Routes.READING_FORM),
            icon: const Icon(Icons.add),
            label: const Text('Primeira Leitura'),
          ),
        ],
      ),
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
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.green),
                title: const Text('Editar Leitura'),
                onTap: () {
                  Get.back();
                  controller.selectReading(reading);
                  Get.toNamed(Routes.READING_FORM);
                },
              ),
              ListTile(
                leading: const Icon(Icons.print, color: Colors.purple),
                title: const Text('Imprimir Conta'),
                onTap: () {
                  Get.back();
                  controller.printReadingReceipt(reading);
                },
              ),
              ListTile(
                leading: const Icon(Icons.person, color: Colors.indigo),
                title: const Text('Ver Cliente'),
                onTap: () {
                  Get.back();
                  Get.toNamed(Routes.CLIENT_DETAIL, arguments: reading.clientId);
                },
              ),
              // Delete option (admin only)
              FutureBuilder<bool>(
                future: _checkIfAdmin(),
                builder: (context, snapshot) {
                  if (snapshot.data == true) {
                    return ListTile(
                      leading: const Icon(Icons.delete, color: Colors.red),
                      title: const Text('Apagar Leitura'),
                      onTap: () {
                        Get.back();
                        controller.deleteReading(reading);
                      },
                    );
                  }
                  return const SizedBox.shrink();
                },
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
                        onPressed: () => controller.printReadingReceipt(reading),
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
                          _buildDetailRow('Período', '${reading.month}/${reading.year}'),
                          _buildDetailRow('Leitura Anterior', reading.previousReading.toStringAsFixed(1)),
                          _buildDetailRow('Leitura Atual', reading.currentReading.toStringAsFixed(1)),
                          _buildDetailRow('Consumo', '${reading.consumption.toStringAsFixed(1)}m³'),
                          _buildDetailRow('Data da Leitura', _formatDateTime(reading.readingDate)),
                          if (reading.notes?.isNotEmpty == true)
                            _buildDetailRow('Observações', reading.notes!),
                        ],
                        Icons.speed,
                        Colors.blue,
                      ),
                      const SizedBox(height: 16),
                      _buildDetailCard(
                        'Status da Conta',
                        [
                          _buildDetailRow('Valor da Conta', '${reading.billAmount.toStringAsFixed(2)} MT'),
                          _buildDetailRow('Status', _getStatusText(reading.paymentStatus)),
                          if (reading.paymentDate != null)
                            _buildDetailRow('Data do Pagamento', _formatDateTime(reading.paymentDate!)),
                        ],
                        Icons.monetization_on,
                        _getStatusColor(reading.paymentStatus),
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

  void _printSelectedReadings() {
    Get.snackbar(
      'Impressão',
      '${selectedReadings.length} leituras selecionadas para impressão',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.purple,
      colorText: Colors.white,
    );
  }

  void _exportSelectedReadings() {
    Get.snackbar(
      'Exportação',
      '${selectedReadings.length} leituras exportadas com sucesso',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.blue,
      colorText: Colors.white,
    );
  }

  Future<bool> _checkIfAdmin() async {
    try {
      final authController = Get.find<AuthController>();
      return authController.isAdmin();
    } catch (e) {
      return false;
    }
  }

  Future<String> _getClientName(String clientId) async {
    return await controller.getClientName(clientId);
  }

  Color _getStatusColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.pending:
        return Colors.orange;
      case PaymentStatus.overdue:
        return Colors.red;
      case PaymentStatus.paid:
        return Colors.green;
      case PaymentStatus.partial:
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.pending:
        return 'PENDENTE';
      case PaymentStatus.overdue:
        return 'DÍVIDA';
      case PaymentStatus.paid:
        return 'PAGO';
      case PaymentStatus.partial:
        return 'PARCIAL';
      default:
        return 'N/A';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatDateTime(DateTime date) {
    return '${_formatDate(date)} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _getMonthName(int month) {
    const months = [
      'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
      'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'
    ];
    return months[month - 1];
  }
}