// ===== RELATÓRIO DE LEITURAS NÃO FEITAS =====
// Relatório de clientes cadastrados sem leitura no mês

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:vitalh2x/controlers/reports_controller.dart';
import 'package:vitalh2x/routs/rout.dart';

class MissingReadingsReportView extends StatelessWidget {
  const MissingReadingsReportView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ReportsController controller = Get.put(ReportsController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leituras Não Feitas'),
        backgroundColor: Colors.red[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () => _selectPeriod(controller),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.loadMissingReadingsReport(),
          ),
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenuAction(value, controller),
            itemBuilder: (context) => [
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
              const PopupMenuItem(
                value: 'print',
                child: Row(
                  children: [
                    Icon(Icons.print, size: 20),
                    SizedBox(width: 8),
                    Text('Imprimir Lista'),
                  ],
                ),
              ),
            ],
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
              _buildPeriodHeader(controller),
              const SizedBox(height: 20),
              _buildSummaryCards(controller),
              const SizedBox(height: 20),
              _buildCompletionChart(controller),
              const SizedBox(height: 20),
              _buildMissingClientsList(controller),
              const SizedBox(height: 20),
              _buildActionButtons(controller),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildPeriodHeader(ReportsController controller) {
    return Card(
      color: Colors.red[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.warning, color: Colors.red[700], size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Relatório de Leituras Não Feitas',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Obx(() => Text(
                    'Período: ${controller.currentPeriodText}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.red[600],
                    ),
                  )),
                ],
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => _selectPeriod(controller),
              icon: const Icon(Icons.edit_calendar, size: 20),
              label: const Text('Alterar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards(ReportsController controller) {
    return Obx(() {
      final summary = controller.missingReadingsSummary;
      if (summary.isEmpty) return const SizedBox.shrink();

      final totalClients = summary['total_active_clients'] as int;
      final clientsWithReadings = summary['clients_with_readings'] as int;
      final clientsWithoutReadings = summary['clients_without_readings_count'] as int;
      final completionPercentage = summary['completion_percentage'] as double;

      return Column(
        children: [
          // Cards de estatísticas
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Total de Clientes',
                  '$totalClients',
                  Icons.people,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  'Leituras Feitas',
                  '$clientsWithReadings',
                  Icons.check_circle,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  'Não Feitas',
                  '$clientsWithoutReadings',
                  Icons.cancel,
                  Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Card de percentual de conclusão
          Card(
            color: completionPercentage >= 90 ? Colors.green[50] : 
                  completionPercentage >= 70 ? Colors.orange[50] : Colors.red[50],
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    completionPercentage >= 90 ? Icons.check_circle : 
                    completionPercentage >= 70 ? Icons.warning : Icons.error,
                    color: completionPercentage >= 90 ? Colors.green[700] : 
                           completionPercentage >= 70 ? Colors.orange[700] : Colors.red[700],
                    size: 32,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Percentual de Conclusão',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: completionPercentage >= 90 ? Colors.green[700] : 
                                   completionPercentage >= 70 ? Colors.orange[700] : Colors.red[700],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${completionPercentage.toStringAsFixed(1)}% das leituras foram realizadas',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${completionPercentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: completionPercentage >= 90 ? Colors.green[700] : 
                             completionPercentage >= 70 ? Colors.orange[700] : Colors.red[700],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
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
        ),
      ),
    );
  }

  Widget _buildCompletionChart(ReportsController controller) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.analytics, color: Colors.indigo),
                const SizedBox(width: 8),
                const Text(
                  'Progresso das Leituras',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Obx(() {
              final summary = controller.missingReadingsSummary;
              if (summary.isEmpty) return const SizedBox.shrink();

              final completionPercentage = summary['completion_percentage'] as double;
              final missingPercentage = summary['missing_percentage'] as double;

              return Column(
                children: [
                  // Barra de progresso das leituras feitas
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Leituras Concluídas',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        '${completionPercentage.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: completionPercentage / 100,
                    backgroundColor: Colors.grey[200],
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                    minHeight: 12,
                  ),
                  const SizedBox(height: 16),
                  
                  // Barra de progresso das leituras não feitas
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Leituras Pendentes',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        '${missingPercentage.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: missingPercentage / 100,
                    backgroundColor: Colors.grey[200],
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.red),
                    minHeight: 12,
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildMissingClientsList(ReportsController controller) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.list, color: Colors.red),
                    const SizedBox(width: 8),
                    const Text(
                      'Clientes sem Leitura',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Obx(() {
                  final clients = controller.clientsWithoutReadings;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.red[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${clients.length} clientes',
                      style: TextStyle(
                        color: Colors.red[800],
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  );
                }),
              ],
            ),
            const SizedBox(height: 16),
            Obx(() {
              final clients = controller.clientsWithoutReadings;
              
              if (clients.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(Icons.check_circle, size: 48, color: Colors.green),
                        SizedBox(height: 16),
                        Text(
                          'Parabéns! Todas as leituras foram realizadas!',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Column(
                children: [
                  // Limitar a 10 itens inicialmente
                  ...clients.take(10).map((client) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.red[100],
                          child: Text(
                            (client['name'] as String).isNotEmpty
                                ? (client['name'] as String)[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              color: Colors.red[800],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          client['name'] ?? 'Nome não informado',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Ref: ${client['reference'] ?? 'N/A'}'),
                            if (client['contact'] != null && (client['contact'] as String).isNotEmpty)
                              Text('Tel: ${client['contact']}'),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.warning, color: Colors.red, size: 20),
                            const SizedBox(height: 4),
                            Text(
                              'Pendente',
                              style: TextStyle(
                                color: Colors.red[800],
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        onTap: () => _navigateToClient(client['id']),
                      ),
                    );
                  }).toList(),
                  
                  // Mostrar botão para ver mais se houver mais de 10 clientes
                  if (clients.length > 10)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Center(
                        child: TextButton(
                          onPressed: () => _showAllMissingClients(controller),
                          child: Text('Ver todos os ${clients.length} clientes'),
                        ),
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

  Widget _buildActionButtons(ReportsController controller) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => controller.exportMissingReadingsReport(),
            icon: const Icon(Icons.download, color: Colors.white),
            label: const Text('Exportar Lista', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _generateReadingRoute(controller),
            icon: const Icon(Icons.route, color: Colors.white),
            label: const Text('Rota de Leituras', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  void _handleMenuAction(String action, ReportsController controller) {
    switch (action) {
      case 'export':
        controller.exportMissingReadingsReport();
        break;
      case 'print':
        // TODO: Implement print functionality
        Get.snackbar('Imprimir', 'Funcionalidade em desenvolvimento');
        break;
    }
  }

  void _selectPeriod(ReportsController controller) async {
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
      controller.changePeriod(picked.month, picked.year);
    }
  }

  void _navigateToClient(String clientId) {
    Get.toNamed(Routes.CLIENT_DETAIL, arguments: clientId);
  }

  void _showAllMissingClients(ReportsController controller) {
    // TODO: Navigate to full list view or show in a dialog
    Get.snackbar(
      'Lista Completa',
      'Funcionalidade em desenvolvimento - mostrará todos os clientes sem leitura',
    );
  }

  void _generateReadingRoute(ReportsController controller) {
    // TODO: Generate optimal route for field operators
    Get.snackbar(
      'Rota de Leituras',
      'Funcionalidade em desenvolvimento - gerará rota otimizada para os leituristas',
    );
  }
}