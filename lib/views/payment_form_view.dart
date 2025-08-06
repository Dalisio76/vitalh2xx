import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:vitalh2x/controlers/payment_controller.dart';
import 'package:vitalh2x/models/cliente_model.dart';
import 'package:vitalh2x/models/metodo_pagamento_model.dart';

class PaymentFormView extends GetView<PaymentController> {
  const PaymentFormView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Processar Pagamento'),
        backgroundColor: Colors.green[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => _showPaymentHistory(),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildClientSearch(),
              const SizedBox(height: 20),
              if (controller.selectedClient.value != null) ...[
                _buildClientInfo(),
                const SizedBox(height: 20),
                _buildPendingBills(),
                const SizedBox(height: 20),
                _buildPaymentForm(),
                const SizedBox(height: 20),
                _buildCalculator(),
                const SizedBox(height: 30),
                _buildActionButtons(),
              ],
            ],
          ),
        );
      }),
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
                    onChanged:
                        (value) => controller.clientReference.value = value,
                    decoration: const InputDecoration(
                      labelText: 'Referência do Cliente',
                      hintText: 'Digite a referência...',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.search),
                    ),
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
                            fontSize: 18,
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
                        if (client.contact.isNotEmpty)
                          Text(
                            'Contacto: ${client.contact}',
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
            ],
          );
        }),
      ),
    );
  }

  Widget _buildPendingBills() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Contas Pendentes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Obx(() {
              final pendingBills = controller.pendingBills.value;
              final clientBills =
                  pendingBills
                      .where(
                        (bill) =>
                            bill.clientId ==
                            controller.selectedClient.value?.id,
                      )
                      .toList();

              if (clientBills.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(20),
                  child: const Center(
                    child: Column(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 48),
                        SizedBox(height: 8),
                        Text(
                          'Nenhuma conta pendente',
                          style: TextStyle(color: Colors.green),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Column(
                children: [
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: clientBills.length,
                    separatorBuilder:
                        (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final bill = clientBills[index];
                      final isSelected =
                          controller.selectedReading.value?.id == bill.id;

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.orange[100],
                          child: Text(
                            '${bill.month}',
                            style: TextStyle(
                              color: Colors.orange[800],
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          '${_getMonthName(bill.month)} ${bill.year}',
                        ),
                        subtitle: Text(
                          'Consumo: ${bill.consumption.toStringAsFixed(1)}m³',
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${bill.billAmount.toStringAsFixed(2)} MT',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'PENDENTE',
                                style: TextStyle(
                                  color: Colors.orange[800],
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        selected: isSelected,
                        onTap: () {
                          controller.selectedReading.value = bill;
                          controller.amountToPay.value = bill.billAmount;
                          controller.amountPaid.value = bill.billAmount;
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Selecionado:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Obx(
                          () => Text(
                            controller.formattedAmountToPay,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[800],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Detalhes do Pagamento',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              decoration: const InputDecoration(
                labelText: 'Valor Pago *',
                hintText: '0.00',
                prefixText: 'MT ',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.monetization_on),
              ),
              onChanged: (value) {
                controller.amountPaid.value = double.tryParse(value) ?? 0.0;
              },
            ),
            const SizedBox(height: 16),
            Obx(
              () => DropdownButtonFormField<PaymentMethod>(
                value: controller.paymentMethod.value,
                decoration: const InputDecoration(
                  labelText: 'Forma de Pagamento *',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.payment),
                ),
                items:
                    PaymentMethod.values
                        .map(
                          (method) => DropdownMenuItem(
                            value: method,
                            child: Text(method.displayName),
                          ),
                        )
                        .toList(),
                onChanged:
                    (value) =>
                        controller.paymentMethod.value =
                            value ?? PaymentMethod.cash,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Referência da Transação',
                hintText: 'Opcional',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.receipt),
              ),
              onChanged:
                  (value) => controller.transactionReference.value = value,
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalculator() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Calculadora de Troco',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Obx(() {
              final totalToPay = controller.amountToPay.value;
              final amountPaid = controller.amountPaid.value;
              final change = amountPaid - totalToPay;

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: change >= 0 ? Colors.green[50] : Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: change >= 0 ? Colors.green[200]! : Colors.red[200]!,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total a Pagar:'),
                        Text(
                          controller.formattedAmountToPay,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Valor Pago:'),
                        Text(
                          controller.formattedAmountPaid,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          change >= 0 ? 'Troco:' : 'Falta:',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${change.abs().toStringAsFixed(2)} MT',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color:
                                change >= 0
                                    ? Colors.green[800]
                                    : Colors.red[800],
                          ),
                        ),
                      ],
                    ),
                    if (change < 0) ...[
                      const SizedBox(height: 8),
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
                                'Valor insuficiente para quitar a conta',
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

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: () => controller.processPayment(),
            icon: const Icon(Icons.payment),
            label: const Text('Processar Pagamento'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[600],
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
                onPressed: () => _generateReceipt(),
                icon: const Icon(Icons.receipt_long),
                label: const Text('Gerar Recibo'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showPaymentHistory(),
                label: const Text('Histórico'),
                icon: const Icon(Icons.history),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: TextButton.icon(
            onPressed: () => _showQuickPaymentOptions(),
            icon: const Icon(Icons.flash_on),
            label: const Text('Pagamento Rápido'),
            style: TextButton.styleFrom(foregroundColor: Colors.blue[600]),
          ),
        ),
      ],
    );
  }

  void _generateReceipt() {
    if (controller.selectedClient.value == null ||
        controller.selectedReading.value == null) {
      controller.showError('Selecione um cliente e conta primeiro');
      return;
    }

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
                    'Recibo de Pagamento',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {}, // TODO: Implement print
                        icon: const Icon(Icons.print),
                      ),
                      IconButton(
                        onPressed: () {}, // TODO: Implement share
                        icon: const Icon(Icons.share),
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
                child: SingleChildScrollView(child: _buildReceiptContent()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptContent() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Obx(() {
        final client = controller.selectedClient.value!;
        final reading = controller.selectedReading.value!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Column(
                children: [
                  Text(
                    'VITALH2O',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  Text('Sistema de Gestão de Água'),
                  SizedBox(height: 10),
                  Text(
                    'RECIBO DE PAGAMENTO',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildReceiptRow('Recibo Nº:', controller.receiptNumber.value),
            _buildReceiptRow('Data:', _formatDate(DateTime.now())),
            _buildReceiptRow('Hora:', _formatTime(DateTime.now())),
            const Divider(),
            _buildReceiptRow('Cliente:', client.name),
            _buildReceiptRow('Referência:', client.reference),
            if (client.contact.isNotEmpty)
              _buildReceiptRow('Contacto:', client.contact),
            const Divider(),
            const Text(
              'DETALHES DO PAGAMENTO:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _buildReceiptRow(
              'Período:',
              '${_getMonthName(reading.month)} ${reading.year}',
            ),
            _buildReceiptRow(
              'Consumo:',
              '${reading.consumption.toStringAsFixed(1)}m³',
            ),
            _buildReceiptRow(
              'Valor da Conta:',
              '${reading.billAmount.toStringAsFixed(2)} MT',
            ),
            const Divider(),
            _buildReceiptRow('Total Pago:', controller.formattedAmountPaid),
            _buildReceiptRow(
              'Forma de Pagamento:',
              controller.paymentMethod.value.displayName,
            ),
            if (controller.transactionReference.value.isNotEmpty)
              _buildReceiptRow(
                'Referência:',
                controller.transactionReference.value,
              ),
            if (controller.notes.value.isNotEmpty)
              _buildReceiptRow('Observações:', controller.notes.value),
            const SizedBox(height: 30),
            const Center(
              child: Column(
                children: [
                  Text('_________________________'),
                  SizedBox(height: 5),
                  Text('Assinatura do Responsável'),
                  SizedBox(height: 20),
                  Text(
                    'Obrigado pela preferência!',
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildReceiptRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
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

  void _showPaymentHistory() {
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
                    'Histórico de Pagamentos',
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
                  final payments = controller.payments.value;
                  if (payments.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'Nenhum pagamento encontrado',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: payments.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final payment = payments[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.green[100],
                          child: Icon(Icons.check, color: Colors.green[800]),
                        ),
                        title: Text(
                          '${payment.amountPaid.toStringAsFixed(2)} MT',
                        ),
                        subtitle: Text(
                          '${_formatDate(payment.paymentDate)} • ${payment.paymentMethod.displayName}',
                        ),
                        trailing: Text(
                          payment.receiptNumber,
                          style: const TextStyle(fontSize: 12),
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

    // Load payment history when showing
    controller.loadClientPayments(controller.selectedClient.value!.id!);
  }

  void _showQuickPaymentOptions() {
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
                'Pagamento Rápido',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.payment, color: Colors.green),
                title: const Text('Pagar Valor Exato'),
                subtitle: Text(controller.formattedAmountToPay),
                onTap: () {
                  controller.amountPaid.value = controller.amountToPay.value;
                  Get.back();
                },
              ),
              ListTile(
                leading: const Icon(Icons.money, color: Colors.blue),
                title: const Text('Valores Comuns'),
                subtitle: const Text('50, 100, 200, 500 MT'),
                onTap: () => _showCommonAmounts(),
              ),
              ListTile(
                leading: const Icon(Icons.clear, color: Colors.red),
                title: const Text('Limpar Formulário'),
                onTap: () {
                  controller.clearForm();
                  Get.back();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCommonAmounts() {
    Get.back();
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
                'Valores Comuns',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children:
                    [50, 100, 200, 500, 1000]
                        .map(
                          (amount) => ElevatedButton(
                            onPressed: () {
                              controller.amountPaid.value = amount.toDouble();
                              Get.back();
                            },
                            child: Text('$amount MT'),
                          ),
                        )
                        .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
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
