// ===== RELATÓRIO DE PAGAMENTOS =====
// Relatório com checkbox e numeração para pagamentos

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:vitalh2x/controlers/payment_controller.dart';
import 'package:vitalh2x/models/pagamento_model.dart';
import 'package:vitalh2x/models/cliente_model.dart';

class PaymentsReportView extends StatefulWidget {
  const PaymentsReportView({Key? key}) : super(key: key);

  @override
  State<PaymentsReportView> createState() => _PaymentsReportViewState();
}

class _PaymentsReportViewState extends State<PaymentsReportView> {
  final PaymentController controller = Get.find<PaymentController>();
  final Set<String> selectedPayments = <String>{};
  bool selectAll = false;
  
  @override
  void initState() {
    super.initState();
    controller.loadPaymentHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Relatório de Pagamentos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.loadPaymentHistory(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Header com filtros de data
          _buildDateFilter(),
          
          // Ações em lote
          _buildBulkActions(),
          
          // Lista de pagamentos
          Expanded(
            child: _buildPaymentsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDateFilter() {
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
                  const Text('Data Início', style: TextStyle(fontSize: 12)),
                  Obx(() => Text(
                    DateFormat('dd/MM/yyyy').format(controller.startDate.value),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  )),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.calendar_today),
              onPressed: () => _selectStartDate(),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Data Fim', style: TextStyle(fontSize: 12)),
                  Obx(() => Text(
                    DateFormat('dd/MM/yyyy').format(controller.endDate.value),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  )),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.calendar_today),
              onPressed: () => _selectEndDate(),
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
                    selectedPayments.addAll(
                      controller.paymentHistory.map((p) => p['id']?.toString() ?? '').where((id) => id.isNotEmpty),
                    );
                  } else {
                    selectedPayments.clear();
                  }
                });
              },
            ),
            const Text('Selecionar Todos'),
            const Spacer(),
            Text('${selectedPayments.length} selecionados'),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              onPressed: selectedPayments.isEmpty ? null : _exportSelected,
              icon: const Icon(Icons.download),
              label: const Text('Exportar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentsList() {
    return Obx(() {
      if (controller.isLoading) {
        return const Center(child: CircularProgressIndicator());
      }

      final payments = controller.paymentHistory;
      
      if (payments.isEmpty) {
        return const Center(
          child: Text('Nenhum pagamento encontrado no período'),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: payments.length,
        itemBuilder: (context, index) {
          final payment = payments[index];
          final paymentId = payment['id']?.toString() ?? '';
          final isSelected = selectedPayments.contains(paymentId);
          
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Número do pagamento
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Center(
                      child: Text(
                        '${payment['payment_number'] ?? index + 1}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Colors.blue,
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
                          selectedPayments.add(paymentId);
                        } else {
                          selectedPayments.remove(paymentId);
                        }
                      });
                    },
                  ),
                ],
              ),
              title: Text(
                'Cliente: ${payment['client_name'] ?? 'Nome não encontrado'}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Referência: ${payment['client_reference'] ?? 'N/A'}'),
                  Text('Método: ${_getPaymentMethodName(payment['payment_method'] ?? 0)}'),
                  Text('Data: ${DateFormat('dd/MM/yyyy').format(DateTime.tryParse(payment['payment_date']?.toString() ?? '') ?? DateTime.now())}'),
                  if (payment['receipt_number'] != null)
                    Text('Recibo: ${payment['receipt_number']}'),
                ],
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${(payment['amount_paid']?.toDouble() ?? 0.0).toStringAsFixed(2)} MT',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.green,
                    ),
                  ),
                  const Icon(Icons.check_circle, color: Colors.green, size: 16),
                ],
              ),
            ),
          );
        },
      );
    });
  }

  String _getPaymentMethodName(dynamic method) {
    final methodInt = method is int ? method : (method is String ? int.tryParse(method) ?? 0 : 0);
    switch (methodInt) {
      case 0: return 'Dinheiro';
      case 1: return 'Transferência';
      case 2: return 'Mobile Money';
      case 3: return 'Cheque';
      default: return 'Outros';
    }
  }

  Future<void> _selectStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: controller.startDate.value,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      controller.startDate.value = date;
      controller.loadPaymentHistory();
    }
  }

  Future<void> _selectEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: controller.endDate.value,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      controller.endDate.value = date;
      controller.loadPaymentHistory();
    }
  }

  void _exportSelected() {
    // TODO: Implementar exportação dos pagamentos selecionados
    Get.snackbar(
      'Exportação',
      '${selectedPayments.length} pagamentos selecionados para exportação',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}