// ===== RELATÓRIO DE CONTAS PENDENTES =====
// Relatório com checkbox e ações em lote para pagamento ou cancelamento

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:vitalh2x/controlers/payment_controller.dart';
import 'package:vitalh2x/controlers/reading_controller.dart';
import 'package:vitalh2x/models/leitura_model.dart';
import 'package:vitalh2x/models/metodo_pagamento_model.dart';

class PendingBillsReportView extends StatefulWidget {
  const PendingBillsReportView({Key? key}) : super(key: key);

  @override
  State<PendingBillsReportView> createState() => _PendingBillsReportViewState();
}

class _PendingBillsReportViewState extends State<PendingBillsReportView> {
  final PaymentController paymentController = Get.find<PaymentController>();
  final ReadingController readingController = Get.find<ReadingController>();
  final Set<String> selectedBills = <String>{};
  bool selectAll = false;
  
  @override
  void initState() {
    super.initState();
    paymentController.loadPendingBills();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contas Pendentes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => paymentController.loadPendingBills(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Resumo de contas pendentes
          _buildSummaryCard(),
          
          // Ações em lote
          _buildBulkActions(),
          
          // Lista de contas pendentes
          Expanded(
            child: _buildPendingBillsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Obx(() {
      final pendingBills = paymentController.pendingBills;
      final totalAmount = pendingBills.fold<double>(0, (sum, bill) => sum + bill.billAmount);
      final totalCount = pendingBills.length;

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
                    const Text(
                      'Total de Contas Pendentes',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$totalCount contas',
                      style: const TextStyle(fontSize: 24, color: Colors.orange),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Valor Total'),
                  const SizedBox(height: 8),
                  Text(
                    '${totalAmount.toStringAsFixed(2)} MT',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildBulkActions() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
                        selectedBills.addAll(
                          paymentController.pendingBills.map((b) => b.id!).where((id) => id != null).cast<String>(),
                        );
                      } else {
                        selectedBills.clear();
                      }
                    });
                  },
                ),
                const Text('Selecionar Todas'),
                const Spacer(),
                Text('${selectedBills.length} selecionadas'),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: selectedBills.isEmpty ? null : _paySelectedBills,
                    icon: const Icon(Icons.payment, color: Colors.white),
                    label: const Text('Pagar Selecionadas', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: selectedBills.isEmpty ? null : _cancelSelectedBills,
                    icon: const Icon(Icons.cancel, color: Colors.white),
                    label: const Text('Cancelar Selecionadas', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingBillsList() {
    return Obx(() {
      if (paymentController.isLoading) {
        return const Center(child: CircularProgressIndicator());
      }

      final pendingBills = paymentController.pendingBills;
      
      if (pendingBills.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, size: 64, color: Colors.green),
              const SizedBox(height: 16),
              const Text(
                'Não há contas pendentes!',
                style: TextStyle(fontSize: 18, color: Colors.green),
              ),
              const Text(
                'Todas as contas estão em dia',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: pendingBills.length,
        itemBuilder: (context, index) {
          final bill = pendingBills[index];
          final billId = bill.id!;
          final isSelected = selectedBills.contains(billId);
          final isOverdue = _isOverdue(bill);
          
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            color: isOverdue ? Colors.red.withOpacity(0.05) : null,
            child: ListTile(
              leading: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Número da conta
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: isOverdue 
                        ? Colors.red.withOpacity(0.1)
                        : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: isOverdue ? Colors.red : Colors.orange,
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
                          selectedBills.add(billId);
                        } else {
                          selectedBills.remove(billId);
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
                      future: readingController.getClientName(bill.clientId),
                      builder: (context, snapshot) {
                        final clientName = snapshot.data ?? 'Carregando...';
                        return Text(
                          clientName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        );
                      },
                    ),
                  ),
                  if (isOverdue)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: const Text(
                        'EM ATRASO',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Período: ${bill.month}/${bill.year}'),
                  Text('Consumo: ${bill.consumption.toStringAsFixed(1)} m³'),
                  Text('Vencimento: ${_getPaymentDueDate(bill)}'),
                  if (isOverdue)
                    Text(
                      'Atraso: ${_getDaysOverdue(bill)} dias',
                      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                ],
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${bill.billAmount.toStringAsFixed(2)} MT',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isOverdue ? Colors.red : Colors.orange,
                    ),
                  ),
                  Icon(
                    isOverdue ? Icons.warning : Icons.pending,
                    color: isOverdue ? Colors.red : Colors.orange,
                    size: 16,
                  ),
                ],
              ),
              onTap: () {
                // TODO: Abrir detalhes da conta ou processar pagamento individual
                _showBillDetails(bill);
              },
            ),
          );
        },
      );
    });
  }

  bool _isOverdue(ReadingModel bill) {
    final now = DateTime.now();
    final dueDate = DateTime(bill.year, bill.month, 5); // Dia 5 do mês como vencimento
    return now.isAfter(dueDate) && bill.paymentStatus == PaymentStatus.pending;
  }

  String _getPaymentDueDate(ReadingModel bill) {
    final dueDate = DateTime(bill.year, bill.month, 5);
    return DateFormat('dd/MM/yyyy').format(dueDate);
  }

  int _getDaysOverdue(ReadingModel bill) {
    final now = DateTime.now();
    final dueDate = DateTime(bill.year, bill.month, 5);
    return now.difference(dueDate).inDays;
  }

  Future<void> _paySelectedBills() async {
    if (selectedBills.isEmpty) return;

    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Confirmar Pagamentos'),
        content: Text('Deseja marcar ${selectedBills.length} contas como pagas?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // TODO: Implementar pagamento em lote
      Get.snackbar(
        'Pagamentos Processados',
        '${selectedBills.length} contas marcadas como pagas',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      
      setState(() {
        selectedBills.clear();
        selectAll = false;
      });
      
      paymentController.loadPendingBills();
    }
  }

  Future<void> _cancelSelectedBills() async {
    if (selectedBills.isEmpty) return;

    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Cancelar Contas'),
        content: Text('Deseja cancelar ${selectedBills.length} contas pendentes?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Não'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Cancelar Contas', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // TODO: Implementar cancelamento em lote
      Get.snackbar(
        'Contas Canceladas',
        '${selectedBills.length} contas foram canceladas',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      
      setState(() {
        selectedBills.clear();
        selectAll = false;
      });
      
      paymentController.loadPendingBills();
    }
  }

  void _showBillDetails(ReadingModel bill) {
    Get.dialog(
      AlertDialog(
        title: const Text('Detalhes da Conta'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cliente: ${bill.clientId}'),
            Text('Período: ${bill.month}/${bill.year}'),
            Text('Consumo: ${bill.consumption.toStringAsFixed(1)} m³'),
            Text('Valor: ${bill.billAmount.toStringAsFixed(2)} MT'),
            Text('Vencimento: ${_getPaymentDueDate(bill)}'),
            if (_isOverdue(bill))
              Text(
                'Atraso: ${_getDaysOverdue(bill)} dias',
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Fechar'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              // TODO: Abrir tela de pagamento individual
            },
            child: const Text('Pagar Agora'),
          ),
        ],
      ),
    );
  }
}