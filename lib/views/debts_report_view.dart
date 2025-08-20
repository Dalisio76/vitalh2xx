// ===== RELATÓRIO DE DÍVIDAS =====
// Relatório de clientes com contas em atraso (após dia 5 do mês)

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:vitalh2x/controlers/reading_controller.dart';
import 'package:vitalh2x/models/leitura_model.dart';
import 'package:vitalh2x/models/metodo_pagamento_model.dart';
import 'package:vitalh2x/utils/app_styles.dart';

class DebtsReportView extends StatefulWidget {
  const DebtsReportView({Key? key}) : super(key: key);

  @override
  State<DebtsReportView> createState() => _DebtsReportViewState();
}

class _DebtsReportViewState extends State<DebtsReportView> {
  final ReadingController controller = Get.find<ReadingController>();
  final Set<String> selectedDebts = <String>{};
  bool selectAll = false;
  late List<ReadingModel> overdueReadings;
  
  @override
  void initState() {
    super.initState();
    _loadOverdueReadings();
  }

  void _loadOverdueReadings() {
    controller.loadOverdueBills();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Relatório de Dívidas'),
        backgroundColor: AppStyles.primaryColor,
        foregroundColor: Colors.white,
        toolbarHeight: 48,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: _loadOverdueReadings,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStatsBar(),
          Expanded(child: _buildDebtsList()),
        ],
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
        border: Border(bottom: BorderSide(color: AppStyles.primaryColor.withOpacity(0.3))),
      ),
      child: Obx(() {
        final overdueBills = controller.overdueBills;
        final totalAmount = overdueBills.fold<double>(0, (sum, bill) => sum + bill.billAmount);
        final uniqueClients = <String>{};
        for (var bill in overdueBills) {
          uniqueClients.add(bill.clientId);
        }

        return Row(
          children: [
            Expanded(
              child: _buildStatItem(
                'Clientes',
                '${uniqueClients.length}',
                Icons.people,
                AppStyles.primaryColor,
              ),
            ),
            Container(height: 24, width: 1, color: AppStyles.primaryColor.withOpacity(0.3)),
            Expanded(
              child: _buildStatItem(
                'Valor',
                '${totalAmount.toStringAsFixed(0)} MT',
                Icons.money_off,
                AppStyles.errorColor,
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
            Text(
              label, 
              style: AppStyles.compactCaption,
            ),
          ],
        ),
      ],
    );
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

  Widget _buildDebtCriteriaCard() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.info, color: Colors.blue[700]),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Critério de Dívida',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Contas são consideradas em dívida após o dia 5 de cada mês',
                    style: TextStyle(color: Colors.blue[600], fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
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
                        selectedDebts.addAll(
                          controller.overdueBills.map((b) => b.id!).where((id) => id != null).cast<String>(),
                        );
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
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: selectedDebts.isEmpty ? null : _markAsPaid,
                    icon: const Icon(Icons.payment, color: Colors.white),
                    label: const Text('Marcar como Pagas', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: selectedDebts.isEmpty ? null : _sendReminders,
                    icon: const Icon(Icons.notifications, color: Colors.white),
                    label: const Text('Enviar Lembretes', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
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

  Widget _buildDebtsList() {
    return Obx(() {
      if (controller.isLoading) {
        return const Center(child: CircularProgressIndicator());
      }

      final overdueBills = controller.overdueBills;
      
      if (overdueBills.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.sentiment_satisfied, size: 64, color: Colors.green),
              const SizedBox(height: 16),
              const Text(
                'Parabéns! Não há dívidas em atraso',
                style: TextStyle(fontSize: 18, color: Colors.green),
              ),
              const Text(
                'Todos os clientes estão em dia com os pagamentos',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        );
      }

      return _buildDataGrid(overdueBills);
    });
  }

  Widget _buildDataGrid(List<ReadingModel> debts) {
    final debtsByClient = <String, List<ReadingModel>>{};
    for (var debt in debts) {
      if (!debtsByClient.containsKey(debt.clientId)) {
        debtsByClient[debt.clientId] = [];
      }
      debtsByClient[debt.clientId]!.add(debt);
    }

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
                Expanded(flex: 2, child: _buildHeaderCellExpanded('CONTAS')),
                Expanded(flex: 2, child: _buildHeaderCellExpanded('VALOR')),
                Expanded(flex: 2, child: _buildHeaderCellExpanded('DIAS ATRASO')),
                Expanded(flex: 2, child: _buildHeaderCellExpanded('STATUS')),
              ],
            ),
          ),
          // Data Rows
          Expanded(
            child: ListView.builder(
              itemCount: debtsByClient.length,
              itemBuilder: (context, index) {
                final clientId = debtsByClient.keys.elementAt(index);
                final clientDebts = debtsByClient[clientId]!;
                final totalDebt = clientDebts.fold<double>(0, (sum, debt) => sum + debt.billAmount);
                final oldestDebt = clientDebts.reduce((a, b) => 
                  DateTime(a.year, a.month).isBefore(DateTime(b.year, b.month)) ? a : b);
                final daysOverdue = _calculateDaysOverdue(oldestDebt);
                return _buildDataRow(clientId, clientDebts.length, totalDebt, daysOverdue, index);
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

  Widget _buildDataRow(String clientId, int accountCount, double totalDebt, int daysOverdue, int index) {
    return InkWell(
      onTap: () {},
      child: Container(
        height: 20,
        decoration: BoxDecoration(
          color: index % 2 == 0 ? Colors.white : Colors.grey[50],
          border: Border(bottom: BorderSide(color: Colors.grey[200]!, width: 0.5)),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: _buildDataCellExpanded(
                FutureBuilder<String>(
                  future: controller.getClientName(clientId),
                  builder: (context, snapshot) {
                    return Text(
                      snapshot.data ?? 'Cliente',
                      style: const TextStyle(fontSize: 9)
                    );
                  },
                )
              ),
            ),
            Expanded(
              flex: 2,
              child: _buildDataCellExpanded(
                Text('$accountCount', style: const TextStyle(fontSize: 9))
              ),
            ),
            Expanded(
              flex: 2,
              child: _buildDataCellExpanded(
                Text(
                  '${totalDebt.toStringAsFixed(2)} MT',
                  style: const TextStyle(
                    fontSize: 9,
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                )
              ),
            ),
            Expanded(
              flex: 2,
              child: _buildDataCellExpanded(
                Text('$daysOverdue dias', 
                     style: const TextStyle(fontSize: 9, color: Colors.orange, fontWeight: FontWeight.bold))
              ),
            ),
            Expanded(
              flex: 2,
              child: _buildDataCellExpanded(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: const Text(
                    'DÍVIDA',
                    style: TextStyle(
                      fontSize: 7,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
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
      child: Align(
        alignment: Alignment.centerLeft,
        child: child,
      ),
    );
  }

  Widget _buildOldDebtsList() {
    return Obx(() {
      if (controller.isLoading) {
        return const Center(child: CircularProgressIndicator());
      }

      final overdueBills = controller.overdueBills;
      
      if (overdueBills.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.sentiment_satisfied, size: 64, color: Colors.green),
              const SizedBox(height: 16),
              const Text(
                'Parabéns! Não há dívidas em atraso',
                style: TextStyle(fontSize: 18, color: Colors.green),
              ),
              const Text(
                'Todos os clientes estão em dia com os pagamentos',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        );
      }

      final debtsByClient = <String, List<ReadingModel>>{};
      for (var bill in overdueBills) {
        if (!debtsByClient.containsKey(bill.clientId)) {
          debtsByClient[bill.clientId] = [];
        }
        debtsByClient[bill.clientId]!.add(bill);
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: debtsByClient.length,
        itemBuilder: (context, index) {
          final clientId = debtsByClient.keys.elementAt(index);
          final clientDebts = debtsByClient[clientId]!;
          final totalDebt = clientDebts.fold<double>(0, (sum, debt) => sum + debt.billAmount);
          final oldestDebt = clientDebts.reduce((a, b) => 
            DateTime(a.year, a.month).isBefore(DateTime(b.year, b.month)) ? a : b);
          final daysOverdue = _calculateDaysOverdue(oldestDebt);
          
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            color: Colors.red[50],
            child: ExpansionTile(
              leading: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Número do cliente
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Checkbox para selecionar todas as dívidas deste cliente
                  Checkbox(
                    value: clientDebts.every((debt) => selectedDebts.contains(debt.id)),
                    tristate: true,
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          selectedDebts.addAll(clientDebts.map((d) => d.id!));
                        } else {
                          selectedDebts.removeWhere((id) => clientDebts.any((d) => d.id == id));
                        }
                      });
                    },
                  ),
                ],
              ),
              title: FutureBuilder<String>(
                future: controller.getClientName(clientId),
                builder: (context, snapshot) {
                  final clientName = snapshot.data ?? 'Carregando...';
                  return Text(
                    clientName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  );
                },
              ),
              subtitle: Text(
                '${clientDebts.length} conta(s) • ${totalDebt.toStringAsFixed(2)} MT • $daysOverdue dias de atraso',
                style: TextStyle(color: Colors.red[600]),
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${totalDebt.toStringAsFixed(2)} MT',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.red,
                    ),
                  ),
                  Text(
                    '$daysOverdue dias',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
              children: clientDebts.map((debt) => _buildDebtItem(debt)).toList(),
            ),
          );
        },
      );
    });
  }

  Widget _buildDebtItem(ReadingModel debt) {
    final isSelected = selectedDebts.contains(debt.id);
    final daysOverdue = _calculateDaysOverdue(debt);

    return Container(
      color: Colors.white,
      child: ListTile(
        leading: Checkbox(
          value: isSelected,
          onChanged: (value) {
            setState(() {
              if (value == true) {
                selectedDebts.add(debt.id!);
              } else {
                selectedDebts.remove(debt.id!);
              }
            });
          },
        ),
        title: Text('Conta ${debt.month}/${debt.year}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Consumo: ${debt.consumption.toStringAsFixed(1)} m³'),
            Text('Vencimento: 05/${debt.month.toString().padLeft(2, '0')}/${debt.year}'),
            Text(
              'Atraso: $daysOverdue dias',
              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${debt.billAmount.toStringAsFixed(2)} MT',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const Icon(Icons.warning, color: Colors.red, size: 16),
          ],
        ),
      ),
    );
  }

  int _calculateDaysOverdue(ReadingModel debt) {
    final now = DateTime.now();
    final dueDate = DateTime(debt.year, debt.month, 5);
    return now.difference(dueDate).inDays;
  }

  Future<void> _markAsPaid() async {
    if (selectedDebts.isEmpty) return;

    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Marcar como Pagas'),
        content: Text('Deseja marcar ${selectedDebts.length} dívida(s) como pagas?'),
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
      // TODO: Implementar marcação como pago
      Get.snackbar(
        'Dívidas Quitadas',
        '${selectedDebts.length} dívida(s) marcadas como pagas',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      
      setState(() {
        selectedDebts.clear();
        selectAll = false;
      });
      
      _loadOverdueReadings();
    }
  }

  Future<void> _sendReminders() async {
    if (selectedDebts.isEmpty) return;

    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Enviar Lembretes'),
        content: Text('Deseja enviar lembretes para ${selectedDebts.length} dívida(s) selecionadas?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Enviar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // TODO: Implementar envio de lembretes (SMS, WhatsApp, etc.)
      Get.snackbar(
        'Lembretes Enviados',
        'Lembretes enviados para ${selectedDebts.length} cliente(s)',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      
      setState(() {
        selectedDebts.clear();
        selectAll = false;
      });
    }
  }
}