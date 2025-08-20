// ===== READING LIST VIEW COM CHECKBOX =====
// Lista de leituras com checkbox para seleção múltipla

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:vitalh2x/controlers/reading_controller.dart';
import 'package:vitalh2x/models/leitura_model.dart';
import 'package:vitalh2x/models/metodo_pagamento_model.dart';
import 'package:vitalh2x/routs/rout.dart';

class ReadingListEnhancedView extends StatefulWidget {
  const ReadingListEnhancedView({Key? key}) : super(key: key);

  @override
  State<ReadingListEnhancedView> createState() =>
      _ReadingListEnhancedViewState();
}

class _ReadingListEnhancedViewState extends State<ReadingListEnhancedView> {
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
        title: const Text('Lista de Leituras'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.loadMonthlyReadings(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Período selecionado
          _buildPeriodHeader(),

          // Ações em lote
          _buildBulkActions(),

          // Lista de leituras
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Período Atual', style: TextStyle(fontSize: 12)),
              Obx(
                () => Text(
                  '${_getMonthName(controller.currentMonth.value)} ${controller.currentYear.value}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => _changeMonth(-1),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward),
                onPressed: () => _changeMonth(1),
              ),
              IconButton(
                onPressed: () => _selectMonth(),
                icon: const Icon(Icons.edit_calendar),
                style: IconButton.styleFrom(backgroundColor: Colors.blue[100]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBulkActions() {
    return Card(
      margin: const EdgeInsets.all(16),
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
                      onPressed: _processSelectedPayments,
                      icon: const Icon(Icons.payment, color: Colors.white),
                      label: const Text(
                        'Processar Pagamentos',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _exportSelected,
                      icon: const Icon(Icons.download, color: Colors.white),
                      label: const Text(
                        'Exportar',
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
                textAlign: TextAlign.center,
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
            color:
                reading.paymentStatus == PaymentStatus.overdue
                    ? Colors.red[50]
                    : null,
            child: ListTile(
              leading: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Número da leitura
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: _getStatusColor(
                        reading.paymentStatus,
                      ).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Center(
                      child: Text(
                        '${reading.readingNumber ?? index + 1}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: _getStatusColor(reading.paymentStatus),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Checkbox
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
                  Text('Período: ${reading.month}/${reading.year}'),
                  Text(
                    'Leitura: ${reading.previousReading.toInt()} → ${reading.currentReading.toInt()}',
                  ),
                  Text('Consumo: ${reading.consumption.toStringAsFixed(1)} m³'),
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
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: _getStatusColor(reading.paymentStatus),
                    ),
                  ),
                ],
              ),
              onTap: () {
                _showReadingActions(reading);
              },
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

    // Limpar seleções quando mudar de mês
    setState(() {
      selectedReadings.clear();
      selectAll = false;
    });
  }

  void _selectMonth() async {
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
      setState(() {
        selectedReadings.clear();
        selectAll = false;
      });
    }
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
              if (reading.paymentStatus == PaymentStatus.pending) ...[
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
                  leading: const Icon(Icons.payment, color: Colors.orange),
                  title: const Text('Processar Pagamento'),
                  onTap: () {
                    Get.back();
                    Get.toNamed(Routes.PAYMENT_FORM, arguments: reading);
                  },
                ),
              ],
              ListTile(
                leading: const Icon(Icons.visibility, color: Colors.blue),
                title: const Text('Ver Detalhes'),
                onTap: () {
                  Get.back();
                  _showReadingDetails(reading);
                },
              ),
              ListTile(
                leading: const Icon(Icons.print, color: Colors.purple),
                title: const Text('Imprimir Conta'),
                onTap: () {
                  Get.back();
                  Get.snackbar('Imprimir', 'Conta enviada para impressão');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showReadingDetails(ReadingModel reading) {
    Get.dialog(
      AlertDialog(
        title: const Text('Detalhes da Leitura'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FutureBuilder<String>(
                future: controller.getClientName(reading.clientId),
                builder: (context, snapshot) {
                  final clientName = snapshot.data ?? 'Carregando...';
                  return _buildDetailRow('Cliente:', clientName);
                },
              ),
              _buildDetailRow('Período:', '${reading.month}/${reading.year}'),
              _buildDetailRow(
                'Leitura Anterior:',
                reading.previousReading.toStringAsFixed(1),
              ),
              _buildDetailRow(
                'Leitura Atual:',
                reading.currentReading.toStringAsFixed(1),
              ),
              _buildDetailRow(
                'Consumo:',
                '${reading.consumption.toStringAsFixed(1)} m³',
              ),
              _buildDetailRow(
                'Valor:',
                '${reading.billAmount.toStringAsFixed(2)} MT',
              ),
              _buildDetailRow(
                'Data:',
                DateFormat('dd/MM/yyyy').format(reading.readingDate),
              ),
              _buildDetailRow('Status:', _getStatusText(reading.paymentStatus)),
              if (reading.notes != null && reading.notes!.isNotEmpty)
                _buildDetailRow('Observações:', reading.notes!),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Fechar')),
        ],
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
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _processSelectedPayments() {
    // TODO: Implementar processamento de pagamentos em lote
    Get.snackbar(
      'Pagamentos',
      '${selectedReadings.length} leituras selecionadas para processamento',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
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

  Color _getStatusColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.paid:
        return Colors.green;
      case PaymentStatus.partial:
        return Colors.blue;
      case PaymentStatus.overdue:
        return Colors.red;
      case PaymentStatus.pending:
        return Colors.orange;
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
        return 'PENDENTE';
    }
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
