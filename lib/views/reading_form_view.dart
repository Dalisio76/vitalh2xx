import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:vitalh2x/controlers/reading_controller.dart';
import 'package:vitalh2x/models/cliente_model.dart';
import 'package:vitalh2x/models/leitura_model.dart';
import 'package:vitalh2x/models/metodo_pagamento_model.dart';

class ReadingFormView extends GetView<ReadingController> {
  const ReadingFormView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ClientModel? client = Get.arguments as ClientModel?;
    final bool isEditing = controller.selectedReading.value != null;

    // Se veio com um cliente como argumento, define no controller
    if (client != null) {
      controller.selectedClient.value = client;
      controller.clientReference.value = client.reference;
      controller.findClientByReference();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Leitura' : 'Nova Leitura'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _confirmDelete(),
            ),
        ],
      ),
      body: Form(
        //  key: controller.formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPeriodCard(),
              const SizedBox(height: 20),
              _buildClientSearch(),
              const SizedBox(height: 20),
              Obx(() {
                if (controller.selectedClient.value != null) {
                  return Column(
                    children: [
                      _buildClientInfo(),
                      const SizedBox(height: 20),
                      _buildReadingForm(),
                      const SizedBox(height: 20),
                      _buildCalculationCard(),
                      const SizedBox(height: 30),
                      _buildActionButtons(isEditing),
                    ],
                  );
                }
                return const SizedBox.shrink();
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Período da Leitura',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.calendar_month, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        Obx(
                          () => Text(
                            '${_getMonthName(controller.currentMonth.value)} ${controller.currentYear.value}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: () => _selectMonth(),
                  icon: const Icon(Icons.edit_calendar),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.blue[100],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClientSearch() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Buscar Cliente',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: controller.clientReference.value,
                    decoration: const InputDecoration(
                      labelText: 'Referência do Cliente *',
                      hintText: 'Digite a referência...',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.search),
                    ),
                    validator: controller.validateClientReference,
                    onChanged:
                        (value) => controller.clientReference.value = value,
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () => controller.findClientByReference(),
                  child: const Text('Buscar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClientInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Obx(() {
          final client = controller.selectedClient.value!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Informações do Cliente',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.blue[100],
                    child: Text(
                      client.name.isNotEmpty
                          ? client.name[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        color: Colors.blue[800],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          client.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Ref: ${client.reference}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'Contador: ${client.counterNumber}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color:
                          client.isActive ? Colors.green[100] : Colors.red[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      client.isActive ? 'ATIVO' : 'INATIVO',
                      style: TextStyle(
                        color:
                            client.isActive
                                ? Colors.green[800]
                                : Colors.red[800],
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.history, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      'Última leitura: ${client.lastReading?.toStringAsFixed(0) ?? 'N/A'}',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    const Spacer(),
                    if (client.totalDebt > 0) ...[
                      Icon(Icons.warning, size: 16, color: Colors.orange[600]),
                      const SizedBox(width: 4),
                      Text(
                        'Dívida: ${client.totalDebt.toStringAsFixed(2)} MT',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.orange[600],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildReadingForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dados da Leitura',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'Leitura Anterior',
                      border: const OutlineInputBorder(),
                      suffixText: 'm³',
                      fillColor: Colors.grey[100],
                      filled: true,
                    ),
                    controller: TextEditingController(
                      text: controller.previousReading.value.toStringAsFixed(0),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Leitura Atual *',
                      hintText: '0',
                      border: OutlineInputBorder(),
                      suffixText: 'm³',
                      suffixIcon: Icon(Icons.speed),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d{0,1}'),
                      ),
                    ],
                    validator: controller.validateCurrentReading,
                    onChanged: (value) {
                      controller.currentReading.value =
                          double.tryParse(value) ?? 0.0;
                    },
                    controller: TextEditingController(
                      text:
                          controller.currentReading.value > 0
                              ? controller.currentReading.value.toStringAsFixed(
                                0,
                              )
                              : '',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Observações',
                hintText: 'Informações adicionais (opcional)',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.note),
              ),
              maxLines: 3,
              onChanged: (value) => controller.notes.value = value,
              controller: TextEditingController(text: controller.notes.value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalculationCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cálculos Automáticos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Obx(() {
              final consumption = controller.consumption.value;
              final billAmount = controller.billAmount.value;
              final hasValidReading =
                  controller.currentReading.value >
                  controller.previousReading.value;

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: hasValidReading ? Colors.green[50] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color:
                        hasValidReading
                            ? Colors.green[200]!
                            : Colors.grey[300]!,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Consumo:'),
                        Text(
                          controller.formattedConsumption,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color:
                                hasValidReading
                                    ? Colors.green[700]
                                    : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Valor da Conta:'),
                        Text(
                          controller.formattedBillAmount,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color:
                                hasValidReading
                                    ? Colors.green[800]
                                    : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    if (hasValidReading) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green[100],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info,
                              color: Colors.green[800],
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Cálculo: Consumo × 50 MT/m³',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (!hasValidReading &&
                        controller.currentReading.value > 0) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red[100],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.warning,
                              color: Colors.red[800],
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Leitura atual deve ser maior que a anterior',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(bool isEditing) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed:
                () =>
                    isEditing
                        ? controller.updateReading(
                          controller.selectedReading.value!.id!,
                        )
                        : controller.createReading(),
            icon: Icon(isEditing ? Icons.update : Icons.save),
            label: Text(isEditing ? 'Atualizar Leitura' : 'Salvar Leitura'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showReadingHistory(),
                icon: const Icon(Icons.history),
                label: const Text('Histórico'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => controller.clearForm(),
                icon: const Icon(Icons.clear),
                label: const Text('Limpar'),
              ),
            ),
          ],
        ),
        if (isEditing) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () => _confirmDelete(),
              icon: const Icon(Icons.delete),
              label: const Text('Excluir Leitura'),
              style: TextButton.styleFrom(foregroundColor: Colors.red[600]),
            ),
          ),
        ],
      ],
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

  void _showReadingHistory() {
    if (controller.selectedClient.value == null) {
      controller.showError('Selecione um cliente primeiro');
      return;
    }

    Get.bottomSheet(
      Container(
        height: Get.height * 0.7,
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
                    'Histórico de Leituras',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Obx(() {
                  final readings = controller.readings.value;
                  if (readings.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'Nenhuma leitura encontrada',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: readings.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final reading = readings[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getStatusColor(
                            reading.paymentStatus,
                          ).withOpacity(0.1),
                          child: Text(
                            '${reading.month}',
                            style: TextStyle(
                              color: _getStatusColor(reading.paymentStatus),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          '${_getMonthName(reading.month)} ${reading.year}',
                        ),
                        subtitle: Text(
                          'Consumo: ${reading.consumption.toStringAsFixed(1)}m³ • ${reading.billAmount.toStringAsFixed(2)} MT',
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
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
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );

    // Load client readings when showing
    controller.loadClientReadings(controller.selectedClient.value!.id!);
  }

  void _confirmDelete() {
    Get.dialog(
      AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: const Text(
          'Tem certeza que deseja excluir esta leitura?\n\nEsta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              _deleteReading();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  void _deleteReading() {
    // TODO: Implement delete functionality
    controller.showSuccess('Leitura excluída com sucesso');
    Get.back();
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
      default:
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
      default:
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

  @override
  void onInit() {
    // super.onInit();
    // Clear form when initializing
    if (Get.arguments == null) {
      controller.clearForm();
    }
  }
}
