// ===== ÁREA EXCLUSIVA DE DÍVIDAS =====
// Tela focada apenas em dívidas e contas em atraso

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:vitalh2x/controlers/reading_controller.dart';
import 'package:vitalh2x/models/leitura_model.dart';
import 'package:vitalh2x/models/metodo_pagamento_model.dart';
import 'package:vitalh2x/routs/rout.dart';

class DebtsManagementView extends StatefulWidget {
  const DebtsManagementView({Key? key}) : super(key: key);

  @override
  State<DebtsManagementView> createState() => _DebtsManagementViewState();
}

class _DebtsManagementViewState extends State<DebtsManagementView> {
  final ReadingController controller = Get.find<ReadingController>();
  final Set<String> selectedDebts = <String>{};
  bool selectAll = false;

  @override
  void initState() {
    super.initState();
    _loadDebts();
  }

  Future<void> _loadDebts() async {
    await controller.loadOverdueBills();
    await controller.loadPendingBills();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestão de Dívidas'),
        backgroundColor: Colors.red[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => Get.toNamed(Routes.DASHBOARD),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadDebts(),
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'update_status',
                child: Row(
                  children: [
                    Icon(Icons.update, size: 20),
                    SizedBox(width: 8),
                    Text('Atualizar Status'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.download, size: 20),
                    SizedBox(width: 8),
                    Text('Exportar Lista'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _buildHeader(),
          _buildSummaryCards(),
          _buildFilterTabs(),
          _buildBulkActions(),
          Expanded(child: _buildDebtsList()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => controller.forceUpdateOverdueReadings(),
        icon: const Icon(Icons.update),
        label: const Text('Atualizar Status'),
        backgroundColor: Colors.orange[600],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        border: Border(bottom: BorderSide(color: Colors.red[200]!)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning, color: Colors.red[700], size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Área de Dívidas',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.red[700],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Gestão de contas pendentes e em atraso',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.red[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Obx(() {
        final pendingCount = controller.pendingBills.length;
        final overdueCount = controller.overdueBills.length;
        
        final pendingAmount = controller.pendingBills.fold<double>(
          0.0, (sum, reading) => sum + reading.billAmount,
        );
        
        final overdueAmount = controller.overdueBills.fold<double>(
          0.0, (sum, reading) => sum + reading.billAmount,
        );

        return Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Contas Pendentes',
                '$pendingCount',
                '${pendingAmount.toStringAsFixed(2)} MT',
                Icons.pending,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                'Contas em Atraso',
                '$overdueCount',
                '${overdueAmount.toStringAsFixed(2)} MT',
                Icons.error,
                Colors.red,
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String count,
    String amount,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              count,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              amount,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTabs() {
    return DefaultTabController(
      length: 2,
      child: Container(
        color: Colors.grey[100],
        child: TabBar(
          labelColor: Colors.black87,
          indicatorColor: Colors.red[700],
          tabs: const [
            Tab(
              icon: Icon(Icons.pending, size: 20),
              text: 'Pendentes',
            ),
            Tab(
              icon: Icon(Icons.error, size: 20),
              text: 'Em Atraso',
            ),
          ],
        ),
      ),
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
                          selectedDebts.addAll([
                            ...controller.pendingBills.map((r) => r.id!).where((id) => id != null).cast<String>(),
                            ...controller.overdueBills.map((r) => r.id!).where((id) => id != null).cast<String>(),
                          ]);
                        } else {
                          selectedDebts.clear();
                        }
                      });
                    },
                  ),
                  const Text('Selecionar Todas'),
                  const Spacer(),
                  Text('${selectedDebts.length} selecionadas'),
                ],
              ),
              if (selectedDebts.isNotEmpty) ...[
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
                        onPressed: _sendReminders,
                        icon: const Icon(Icons.message, color: Colors.white),
                        label: const Text(
                          'Enviar Lembretes',
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

  Widget _buildDebtsList() {
    return DefaultTabController(
      length: 2,
      child: TabBarView(
        children: [
          _buildPendingBillsList(),
          _buildOverdueBillsList(),
        ],
      ),
    );
  }

  Widget _buildPendingBillsList() {
    return Obx(() {
      final bills = controller.pendingBills;
      
      if (bills.isEmpty) {
        return _buildEmptyState(
          'Nenhuma conta pendente',
          'Todas as contas estão em dia!',
          Icons.check_circle,
          Colors.green,
        );
      }

      return RefreshIndicator(
        onRefresh: () => controller.loadPendingBills(),
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: bills.length,
          itemBuilder: (context, index) {
            final reading = bills[index];
            final isSelected = selectedDebts.contains(reading.id!);
            return _buildDebtCard(reading, index, isSelected, Colors.orange);
          },
        ),
      );
    });
  }

  Widget _buildOverdueBillsList() {
    return Obx(() {
      final bills = controller.overdueBills;
      
      if (bills.isEmpty) {
        return _buildEmptyState(
          'Nenhuma conta em atraso',
          'Parabéns! Não há contas atrasadas.',
          Icons.celebration,
          Colors.green,
        );
      }

      return RefreshIndicator(
        onRefresh: () => controller.loadOverdueBills(),
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: bills.length,
          itemBuilder: (context, index) {
            final reading = bills[index];
            final isSelected = selectedDebts.contains(reading.id!);
            return _buildDebtCard(reading, index, isSelected, Colors.red);
          },
        ),
      );
    });
  }

  Widget _buildDebtCard(ReadingModel reading, int index, bool isSelected, Color statusColor) {
    final daysSinceReading = DateTime.now().difference(reading.readingDate).inDays;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      color: isSelected ? statusColor.withOpacity(0.1) : null,
      child: InkWell(
        onTap: () => _showDebtActions(reading),
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
                          selectedDebts.add(reading.id!);
                        } else {
                          selectedDebts.remove(reading.id!);
                          selectAll = false;
                        }
                      });
                    },
                  ),
                  // Urgency indicator
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: _getUrgencyColor(daysSinceReading).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(
                      _getUrgencyIcon(daysSinceReading),
                      color: _getUrgencyColor(daysSinceReading),
                      size: 16,
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
                            Text(
                              '$daysSinceReading dias desde a leitura',
                              style: TextStyle(
                                fontSize: 11,
                                color: _getUrgencyColor(daysSinceReading),
                                fontWeight: FontWeight.w500,
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
                          color: statusColor,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: statusColor.withOpacity(0.3)),
                        ),
                        child: Text(
                          reading.paymentStatus == PaymentStatus.pending ? 'PENDENTE' : 'EM ATRASO',
                          style: TextStyle(
                            color: statusColor,
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
                    child: _buildDebtInfo(
                      'Consumo',
                      '${reading.consumption.toStringAsFixed(1)}m³',
                      Icons.water_drop,
                    ),
                  ),
                  Expanded(
                    child: _buildDebtInfo(
                      'Leitura',
                      _formatDate(reading.readingDate),
                      Icons.calendar_today,
                    ),
                  ),
                  Expanded(
                    child: _buildDebtInfo(
                      'Vencimento',
                      _getDeadlineText(reading),
                      Icons.alarm,
                    ),
                  ),
                  // Botão de pagamento rápido
                  ElevatedButton.icon(
                    onPressed: () => _quickPayment(reading),
                    icon: const Icon(Icons.payment, size: 16),
                    label: const Text('Pagar', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      minimumSize: const Size(0, 32),
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

  Widget _buildDebtInfo(String label, String value, IconData icon) {
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

  Widget _buildEmptyState(String title, String subtitle, IconData icon, Color color) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: color),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(fontSize: 18, color: color, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  void _showDebtActions(ReadingModel reading) {
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
                    'Ações da Dívida',
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
                leading: const Icon(Icons.payment, color: Colors.green),
                title: const Text('Processar Pagamento'),
                onTap: () {
                  Get.back();
                  _quickPayment(reading);
                },
              ),
              ListTile(
                leading: const Icon(Icons.visibility, color: Colors.blue),
                title: const Text('Ver Detalhes'),
                onTap: () {
                  Get.back();
                  _showDebtDetails(reading);
                },
              ),
              ListTile(
                leading: const Icon(Icons.message, color: Colors.orange),
                title: const Text('Enviar Lembrete'),
                onTap: () {
                  Get.back();
                  _sendSingleReminder(reading);
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
            ],
          ),
        ),
      ),
    );
  }

  void _showDebtDetails(ReadingModel reading) {
    // Similar to reading details but focused on debt information
    // TODO: Implement debt details view
    Get.snackbar('Detalhes', 'Mostrando detalhes da dívida');
  }

  void _quickPayment(ReadingModel reading) async {
    try {
      final client = await controller.getClientById(reading.clientId);
      if (client != null) {
        Get.toNamed(Routes.PAYMENT_FORM, arguments: {
          'preloaded': true,
          'reading': reading,
          'client': client,
        });
      }
    } catch (e) {
      Get.snackbar('Erro', 'Erro ao carregar dados do cliente');
    }
  }

  void _processSelectedPayments() {
    if (selectedDebts.isEmpty) return;
    
    Get.snackbar(
      'Pagamentos',
      '${selectedDebts.length} contas selecionadas para processamento',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
  }

  void _sendReminders() {
    if (selectedDebts.isEmpty) return;
    
    Get.snackbar(
      'Lembretes',
      '${selectedDebts.length} lembretes enviados',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.blue,
      colorText: Colors.white,
    );
  }

  void _sendSingleReminder(ReadingModel reading) {
    Get.snackbar(
      'Lembrete',
      'Lembrete enviado para o cliente',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.blue,
      colorText: Colors.white,
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'update_status':
        controller.forceUpdateOverdueReadings();
        break;
      case 'export':
        Get.snackbar('Exportar', 'Lista de dívidas exportada');
        break;
    }
  }

  Color _getUrgencyColor(int daysSinceReading) {
    if (daysSinceReading <= 5) return Colors.orange;
    if (daysSinceReading <= 15) return Colors.red;
    if (daysSinceReading <= 30) return Colors.red[700]!;
    return Colors.red[900]!;
  }

  IconData _getUrgencyIcon(int daysSinceReading) {
    if (daysSinceReading <= 5) return Icons.schedule;
    if (daysSinceReading <= 15) return Icons.warning;
    if (daysSinceReading <= 30) return Icons.error;
    return Icons.dangerous;
  }

  String _getDeadlineText(ReadingModel reading) {
    final deadline = DateTime(reading.year, reading.month + 1, 5);
    final now = DateTime.now();
    final difference = deadline.difference(now).inDays;
    
    if (difference > 0) {
      return '$difference dias';
    } else if (difference == 0) {
      return 'Hoje';
    } else {
      return '${difference.abs()} dias atraso';
    }
  }

  Future<String> _getClientName(String clientId) async {
    return await controller.getClientName(clientId);
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }
}