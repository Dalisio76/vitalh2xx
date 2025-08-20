// ===== RELATÓRIO DE LEITURAS =====
// Relatório com checkbox e numeração para leituras

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:vitalh2x/controlers/reading_controller.dart';
import 'package:vitalh2x/models/leitura_model.dart';
import 'package:vitalh2x/models/metodo_pagamento_model.dart';
import 'package:vitalh2x/utils/app_styles.dart';

class ReadingsReportView extends StatefulWidget {
  const ReadingsReportView({Key? key}) : super(key: key);

  @override
  State<ReadingsReportView> createState() => _ReadingsReportViewState();
}

class _ReadingsReportViewState extends State<ReadingsReportView> {
  final ReadingController controller = Get.find<ReadingController>();
  final Set<String> selectedReadings = <String>{};
  bool selectAll = false;

  @override
  void initState() {
    super.initState();
    controller.loadMonthlyReadings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Relatório de Leituras'),
        backgroundColor: AppStyles.primaryColor,
        foregroundColor: Colors.white,
        toolbarHeight: 48,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: () => controller.loadMonthlyReadings(),
          ),
        ],
      ),
      body: Column(
        children: [_buildStatsBar(), Expanded(child: _buildReadingsList())],
      ),
    );
  }

  Widget _buildStatsBar() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppStyles.paddingLarge,
        vertical: AppStyles.paddingMedium,
      ),
      decoration: BoxDecoration(
        color: AppStyles.primaryColor.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(color: AppStyles.primaryColor.withOpacity(0.3)),
        ),
      ),
      child: Obx(() {
        final readings = controller.monthlyReadings;
        final totalReadings = readings.length;
        final totalConsumption = readings.fold(
          0.0,
          (sum, r) => sum + r.consumption,
        );

        return Row(
          children: [
            Expanded(
              child: _buildStatItem(
                'Total',
                '$totalReadings',
                Icons.speed,
                AppStyles.primaryColor,
              ),
            ),
            Container(
              height: 24,
              width: 1,
              color: AppStyles.primaryColor.withOpacity(0.3),
            ),
            Expanded(
              child: _buildStatItem(
                'Consumo',
                '${totalConsumption.toStringAsFixed(0)} m³',
                Icons.water_drop,
                AppStyles.secondaryColor,
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
        Icon(icon, color: color, size: 14),
        const SizedBox(width: AppStyles.paddingSmall),
        Column(
          children: [
            Text(
              value,
              style: AppStyles.compactSubtitle.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(label, style: AppStyles.compactCaption),
          ],
        ),
      ],
    );
  }

  Widget _buildMonthYearFilter() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Mês/Ano', style: TextStyle(fontSize: 12)),
                  Obx(
                    () => Text(
                      '${controller.currentMonth.value}/${controller.currentYear.value}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => _changeMonth(-1),
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward),
              onPressed: () => _changeMonth(1),
            ),
            IconButton(
              icon: const Icon(Icons.calendar_today),
              onPressed: () => _selectMonthYear(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBulkActions() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
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
            const SizedBox(width: 16),
            ElevatedButton.icon(
              onPressed: selectedReadings.isEmpty ? null : _exportSelected,
              icon: const Icon(Icons.download),
              label: const Text('Exportar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadingsList() {
    return Obx(() {
      if (controller.isLoading) {
        return const Center(child: CircularProgressIndicator());
      }

      final readings = controller.monthlyReadings;

      if (readings.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.inbox, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'Nenhuma leitura encontrada para ${controller.currentMonth.value}/${controller.currentYear.value}',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        );
      }

      return _buildDataGrid(readings);
    });
  }

  Widget _buildDataGrid(List<ReadingModel> readings) {
    return Container(
      margin: const EdgeInsets.all(AppStyles.paddingSmall),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Column(
        children: [
          // Header Row
          Container(
            height: 24,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(bottom: BorderSide(color: Colors.grey[400]!)),
            ),
            child: Row(
              children: [
                Expanded(flex: 3, child: _buildHeaderCellExpanded('CLIENTE')),
                Expanded(
                  flex: 2,
                  child: _buildHeaderCellExpanded('LEIT. ANT.'),
                ),
                Expanded(
                  flex: 2,
                  child: _buildHeaderCellExpanded('LEIT. ATUAL'),
                ),
                Expanded(flex: 2, child: _buildHeaderCellExpanded('CONSUMO')),
                Expanded(flex: 2, child: _buildHeaderCellExpanded('VALOR')),
                Expanded(flex: 2, child: _buildHeaderCellExpanded('STATUS')),
              ],
            ),
          ),
          // Data Rows
          Expanded(
            child: ListView.builder(
              itemCount: readings.length,
              itemBuilder: (context, index) {
                final reading = readings[index];
                return _buildDataRow(reading, index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCellExpanded(String text) {
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: Colors.grey[300]!, width: 0.5)),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildDataRow(ReadingModel reading, int index) {
    return InkWell(
      onTap: () {},
      child: Container(
        height: 20,
        decoration: BoxDecoration(
          color: index % 2 == 0 ? Colors.white : Colors.grey[50],
          border: Border(
            bottom: BorderSide(color: Colors.grey[200]!, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: _buildDataCellExpanded(
                FutureBuilder<String>(
                  future: controller.getClientName(reading.clientId),
                  builder: (context, snapshot) {
                    return Text(
                      snapshot.data ?? 'Cliente',
                      style: const TextStyle(fontSize: 9),
                    );
                  },
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: _buildDataCellExpanded(
                Text(
                  '${reading.previousReading.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 9),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: _buildDataCellExpanded(
                Text(
                  '${reading.currentReading.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 9),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: _buildDataCellExpanded(
                Text(
                  '${reading.consumption.toStringAsFixed(1)} m³',
                  style: const TextStyle(
                    fontSize: 9,
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: _buildDataCellExpanded(
                Text(
                  '${reading.billAmount.toStringAsFixed(2)} MT',
                  style: const TextStyle(
                    fontSize: 9,
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: _buildDataCellExpanded(
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 3,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(reading.paymentStatus),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Text(
                    _getStatusText(reading.paymentStatus),
                    style: const TextStyle(
                      fontSize: 7,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataCellExpanded(Widget child) {
    return Container(
      height: 20,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: Colors.grey[200]!, width: 0.5)),
      ),
      child: Align(alignment: Alignment.centerLeft, child: child),
    );
  }

  Color _getStatusColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.paid:
        return Colors.green;
      case PaymentStatus.pending:
        return Colors.orange;
      case PaymentStatus.overdue:
        return Colors.red;
      case PaymentStatus.partial:
        return Colors.blue;
    }
  }

  String _getStatusText(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.paid:
        return 'PAGO';
      case PaymentStatus.pending:
        return 'PEND';
      case PaymentStatus.overdue:
        return 'ATRASO';
      case PaymentStatus.partial:
        return 'PARC';
    }
  }

  Widget _buildOldReadingsList() {
    return Obx(() {
      if (controller.isLoading) {
        return const Center(child: CircularProgressIndicator());
      }

      final readings = controller.monthlyReadings;

      if (readings.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.inbox, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'Nenhuma leitura encontrada para ${controller.currentMonth.value}/${controller.currentYear.value}',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: readings.length,
        itemBuilder: (context, index) {
          final reading = readings[index];
          final readingId = reading.id!;
          final isSelected = selectedReadings.contains(readingId);

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Center(
                      child: Text(
                        '${reading.readingNumber ?? index + 1}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Colors.green,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Checkbox(
                    value: isSelected,
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          selectedReadings.add(readingId);
                        } else {
                          selectedReadings.remove(readingId);
                        }
                      });
                    },
                  ),
                ],
              ),
              title: Row(
                children: [
                  Expanded(
                    child: FutureBuilder<String>(
                      future: controller.getClientName(reading.clientId),
                      builder: (context, snapshot) {
                        final clientName = snapshot.data ?? 'Carregando...';
                        return Text(
                          clientName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        );
                      },
                    ),
                  ),
                  _buildPaymentStatusBadge(reading.paymentStatus),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Leitura: ${reading.previousReading} → ${reading.currentReading}',
                  ),
                  Text('Consumo: ${reading.consumption.toStringAsFixed(1)} m³'),
                  Text('Valor: ${reading.billAmount.toStringAsFixed(2)} MT'),
                  Text(
                    'Data: ${DateFormat('dd/MM/yyyy').format(reading.readingDate)}',
                  ),
                ],
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${reading.consumption.toStringAsFixed(1)} m³',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '${reading.billAmount.toStringAsFixed(2)} MT',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
              onTap: () {},
            ),
          );
        },
      );
    });
  }

  Widget _buildPaymentStatusBadge(PaymentStatus status) {
    Color color;
    String text;
    IconData icon;

    switch (status) {
      case PaymentStatus.paid:
        color = Colors.green;
        text = 'Pago';
        icon = Icons.check_circle;
        break;
      case PaymentStatus.pending:
        color = Colors.orange;
        text = 'Pendente';
        icon = Icons.pending;
        break;
      case PaymentStatus.overdue:
        color = Colors.red;
        text = 'Atrasado';
        icon = Icons.warning;
        break;
      case PaymentStatus.partial:
        color = Colors.blue;
        text = 'Parcial';
        icon = Icons.payment;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _changeMonth(int delta) {
    int newMonth = controller.currentMonth.value + delta;
    int newYear = controller.currentYear.value;

    if (newMonth > 12) {
      newMonth = 1;
      newYear++;
    } else if (newMonth < 1) {
      newMonth = 12;
      newYear--;
    }

    controller.changeMonth(newMonth, newYear);
  }

  Future<void> _selectMonthYear() async {
    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Selecionar Mês/Ano'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // TODO: Implementar seletor de mês/ano
                const Text('Funcionalidade em desenvolvimento'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
            ],
          ),
    );
  }

  void _exportSelected() {
    // TODO: Implementar exportação das leituras selecionadas
    Get.snackbar(
      'Exportação',
      '${selectedReadings.length} leituras selecionadas para exportação',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}
