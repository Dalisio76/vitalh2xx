// ===== RELATÓRIO DE CONTAS PAGAS =====
// Relatório com checkbox e numeração para contas pagas

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:vitalh2x/controlers/reading_controller.dart';

class PaidBillsReportView extends StatefulWidget {
  const PaidBillsReportView({Key? key}) : super(key: key);

  @override
  State<PaidBillsReportView> createState() => _PaidBillsReportViewState();
}

class _PaidBillsReportViewState extends State<PaidBillsReportView> {
  final ReadingController controller = Get.find<ReadingController>();
  final Set<String> selectedBills = <String>{};
  bool selectAll = false;
  DateTime? startDate; // Null = mostrar todos por padrão
  DateTime? endDate; // Null = mostrar todos por padrão
  final RxList<Map<String, dynamic>> paidBills = <Map<String, dynamic>>[].obs;
  
  @override
  void initState() {
    super.initState();
    _loadPaidBills();
  }

  Future<void> _loadPaidBills() async {
    try {
      final bills = await controller.loadPaidBillsWithClientInfo(
        startDate: startDate,
        endDate: endDate,
      );
      paidBills.assignAll(bills);
    } catch (e) {
      print('Error loading paid bills: $e');
      paidBills.clear();
    }
  }

  List<Map<String, dynamic>> get filteredPaidBills {
    return paidBills.toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contas Pagas'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async => await _loadPaidBills(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtro de período
          _buildDateFilter(),
          
          // Resumo de contas pagas
          _buildSummaryCard(),
          
          // Ações em lote
          _buildBulkActions(),
          
          // Lista de contas pagas
          Expanded(
            child: _buildPaidBillsList(),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filtrar por Período de Pagamento',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Data Início', style: TextStyle(fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(
                        startDate != null ? DateFormat('dd/MM/yyyy').format(startDate!) : 'Todas',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
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
                      const SizedBox(height: 4),
                      Text(
                        endDate != null ? DateFormat('dd/MM/yyyy').format(endDate!) : 'Todas',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () => _selectEndDate(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      setState(() {
                        startDate = null;
                        endDate = null;
                      });
                      await _loadPaidBills();
                    },
                    icon: const Icon(Icons.clear_all, color: Colors.white),
                    label: const Text('Mostrar Todos', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      setState(() {
                        startDate = DateTime.now().subtract(const Duration(days: 30));
                        endDate = DateTime.now();
                      });
                      await _loadPaidBills();
                    },
                    icon: const Icon(Icons.date_range, color: Colors.white),
                    label: const Text('Últimos 30 dias', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
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

  Widget _buildSummaryCard() {
    return Obx(() {
      final paidBills = filteredPaidBills;
      final totalAmount = paidBills.fold<double>(0, (sum, bill) => sum + (bill['bill_amount'] as double? ?? 0.0));
      final totalCount = paidBills.length;
      
      // Agrupar por cliente
      final uniqueClients = <String>{};
      for (var bill in paidBills) {
        uniqueClients.add(bill['client_id'] as String? ?? '');
      }

      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        color: Colors.green[50],
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green[700], size: 32),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Relatório de Contas Pagas',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          startDate != null && endDate != null 
                            ? 'Período: ${DateFormat('dd/MM/yyyy').format(startDate!)} - ${DateFormat('dd/MM/yyyy').format(endDate!)}'
                            : 'Período: Todas as datas',
                          style: TextStyle(color: Colors.green[600]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryItem(
                      'Clientes',
                      '${uniqueClients.length}',
                      Icons.people,
                      Colors.blue,
                    ),
                  ),
                  Expanded(
                    child: _buildSummaryItem(
                      'Contas Pagas',
                      '$totalCount',
                      Icons.receipt_long,
                      Colors.green,
                    ),
                  ),
                  Expanded(
                    child: _buildSummaryItem(
                      'Total Recebido',
                      '${totalAmount.toStringAsFixed(2)} MT',
                      Icons.attach_money,
                      Colors.green[800]!,
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

  Widget _buildSummaryItem(String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ],
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
                        selectedBills.addAll(
                          paidBills.map((b) => b['id'] as String).where((id) => id.isNotEmpty),
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
                    onPressed: selectedBills.isEmpty ? null : _exportSelected,
                    icon: const Icon(Icons.download, color: Colors.white),
                    label: const Text('Exportar PDF', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: selectedBills.isEmpty ? null : _generateReport,
                    icon: const Icon(Icons.summarize, color: Colors.white),
                    label: const Text('Gerar Relatório', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
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

  Widget _buildPaidBillsList() {
    return Obx(() {
      final paidBillsList = filteredPaidBills;
      
      if (paidBillsList.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.receipt, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'Nenhuma conta paga encontrada',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
              Text(
                startDate != null && endDate != null 
                  ? 'Período: ${DateFormat('dd/MM/yyyy').format(startDate!)} - ${DateFormat('dd/MM/yyyy').format(endDate!)}'
                  : 'Período: Todas as datas',
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: paidBillsList.length,
        itemBuilder: (context, index) {
          final bill = paidBillsList[index];
          final billId = bill['id'] as String;
          final isSelected = selectedBills.contains(billId);
          
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            color: Colors.green[50],
            child: ListTile(
              leading: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Número da conta
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Colors.green,
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
                    child: Text(
                      'Cliente: ${bill['client_name'] ?? 'N/A'}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, size: 12, color: Colors.green),
                        SizedBox(width: 4),
                        Text(
                          'PAGO',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Ref: ${bill['client_reference'] ?? 'N/A'}'),
                  Text('Período: ${bill['month']}/${bill['year']}'),
                  Text('Consumo: ${(bill['consumption'] as double? ?? 0.0).toStringAsFixed(1)} m³'),
                  Text('Data do Pagamento: ${bill['payment_date'] != null ? DateFormat('dd/MM/yyyy').format(DateTime.parse(bill['payment_date'])) : 'N/A'}'),
                ],
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${(bill['bill_amount'] as double? ?? 0.0).toStringAsFixed(2)} MT',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.green,
                    ),
                  ),
                  const Icon(Icons.verified, color: Colors.green, size: 16),
                ],
              ),
              onTap: () {
                _showBillDetails(bill);
              },
            ),
          );
        },
      );
    });
  }

  // Método removido - não mais necessário

  Future<void> _selectStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: startDate ?? DateTime.now().subtract(const Duration(days: 30)),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() {
        startDate = date;
      });
      await _loadPaidBills();
    }
  }

  Future<void> _selectEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: endDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() {
        endDate = date;
      });
      await _loadPaidBills();
    }
  }

  void _exportSelected() {
    // TODO: Implementar exportação PDF das contas pagas selecionadas
    Get.snackbar(
      'Exportação',
      '${selectedBills.length} contas pagas selecionadas para exportação em PDF',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.blue,
      colorText: Colors.white,
    );
  }

  void _generateReport() {
    // TODO: Implementar geração de relatório consolidado
    final totalAmount = paidBills.where((bill) => selectedBills.contains(bill['id']))
        .fold<double>(0, (sum, bill) => sum + (bill['bill_amount'] as double? ?? 0.0));

    Get.snackbar(
      'Relatório Gerado',
      'Relatório de ${selectedBills.length} contas pagas (Total: ${totalAmount.toStringAsFixed(2)} MT)',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
  }

  void _showBillDetails(Map<String, dynamic> bill) {
    Get.dialog(
      AlertDialog(
        title: const Text('Detalhes da Conta Paga'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Cliente:', bill['client_name'] ?? 'N/A'),
              _buildDetailRow('Referência:', bill['client_reference'] ?? 'N/A'),
              _buildDetailRow('Período:', '${bill['month']}/${bill['year']}'),
              _buildDetailRow('Leitura Anterior:', (bill['previous_reading'] as double? ?? 0.0).toStringAsFixed(1)),
              _buildDetailRow('Leitura Atual:', (bill['current_reading'] as double? ?? 0.0).toStringAsFixed(1)),
              _buildDetailRow('Consumo:', '${(bill['consumption'] as double? ?? 0.0).toStringAsFixed(1)} m³'),
              _buildDetailRow('Valor:', '${(bill['bill_amount'] as double? ?? 0.0).toStringAsFixed(2)} MT'),
              _buildDetailRow('Data da Leitura:', bill['reading_date'] != null ? DateFormat('dd/MM/yyyy').format(DateTime.parse(bill['reading_date'])) : 'N/A'),
              if (bill['payment_date'] != null)
                _buildDetailRow('Data do Pagamento:', DateFormat('dd/MM/yyyy').format(DateTime.parse(bill['payment_date']))),
              _buildDetailRow('Status:', 'PAGO ✓'),
              if (bill['notes'] != null && (bill['notes'] as String).isNotEmpty)
                _buildDetailRow('Observações:', bill['notes']),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Fechar'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              // TODO: Implementar impressão do recibo individual
              Get.snackbar('Imprimir', 'Funcionalidade em desenvolvimento');
            },
            child: const Text('Imprimir Recibo'),
          ),
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
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}