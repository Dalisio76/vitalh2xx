import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vitalh2x/controlers/reading_controller.dart';
import 'package:vitalh2x/controlers/auth_controller.dart';
import 'package:vitalh2x/models/leitura_model.dart';
import 'package:vitalh2x/models/cliente_model.dart';
import 'package:vitalh2x/models/metodo_pagamento_model.dart';
import 'package:vitalh2x/routs/rout.dart';
import 'package:vitalh2x/utils/app_styles.dart';

class ReadingListView extends StatefulWidget {
  ReadingListView({Key? key}) : super(key: key);

  @override
  State<ReadingListView> createState() => _ReadingListViewState();
}

class _ReadingListViewState extends State<ReadingListView> {
  final ReadingController controller = Get.find<ReadingController>();
  final Set<String> selectedReadings = <String>{};
  bool selectAll = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista de Leituras'),
        backgroundColor: AppStyles.primaryColor,
        foregroundColor: Colors.white,
        toolbarHeight: 48,
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => Get.toNamed(Routes.DASHBOARD),
          ),
          IconButton(
            icon: const Icon(Icons.search, size: 20),
            onPressed: () => _showSearchDialog(),
          ),
          IconButton(
            icon: const Icon(Icons.filter_list, size: 20),
            onPressed: () => _showFilterOptions(),
          ),
          IconButton(
            icon: const Icon(Icons.calendar_month, size: 20),
            onPressed: () => _selectMonth(),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildPeriodHeader(),
          _buildStatsBar(),
          _buildBulkActions(),
          _buildQuickFilters(),
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
          Obx(
            () => Text(
              '${_getMonthName(controller.currentMonth.value)} ${controller.currentYear.value}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            onPressed: () => _selectMonth(),
            icon: const Icon(Icons.edit_calendar),
            style: IconButton.styleFrom(backgroundColor: Colors.blue[100]),
          ),
        ],
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
                        onPressed: _printSelected,
                        icon: const Icon(Icons.print, color: Colors.white),
                        label: const Text(
                          'Imprimir Leituras',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
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
                          'Exportar Leituras',
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

  Widget _buildStatsBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.blue[100],
        border: Border(bottom: BorderSide(color: Colors.blue[200]!)),
      ),
      child: Obx(() {
        final stats = controller.monthlyStats.value;
        final totalReadings = stats['total_readings'] ?? 0;
        final totalConsumption = (stats['total_consumption'] ?? 0.0).toDouble();
        final pendingReadings = stats['pending_readings'] ?? 0;

        return Row(
          children: [
            Expanded(
              child: _buildStatItem(
                'Total Leituras',
                '$totalReadings',
                Icons.speed,
                Colors.blue,
              ),
            ),
            Container(height: 40, width: 1, color: Colors.blue[300]),
            Expanded(
              child: _buildStatItem(
                'Total Consumo',
                '${totalConsumption.toStringAsFixed(1)}m³',
                Icons.water_drop,
                Colors.cyan,
              ),
            ),
            Container(height: 40, width: 1, color: Colors.blue[300]),
            Expanded(
              child: _buildStatItem(
                'Pendentes',
                '$pendingReadings',
                Icons.pending,
                Colors.orange,
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
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildQuickFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('Todas', () => _filterAll()),
            const SizedBox(width: 8),
            _buildFilterChip('Pagas', () => _filterPaid()),
            const SizedBox(width: 8),
            _buildFilterChip('Pendentes', () => _filterPending()),
            const SizedBox(width: 8),
            _buildFilterChip('Atrasadas', () => _filterOverdue()),
            const SizedBox(width: 8),
            _buildFilterChip('Este Mês', () => _filterCurrentMonth()),
            const SizedBox(width: 8),
            _buildFilterChip('Limpar', () => _clearFilters(), isReset: true),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    VoidCallback onPressed, {
    bool isReset = false,
  }) {
    return ActionChip(
      label: Text(label),
      onPressed: onPressed,
      backgroundColor: isReset ? Colors.red[100] : Colors.blue[100],
      labelStyle: TextStyle(
        color: isReset ? Colors.red[800] : Colors.blue[800],
        fontSize: 12,
      ),
    );
  }

  Widget _buildReadingsList() {
    return Obx(() {
      if (controller.isLoading) {
        return const Center(child: CircularProgressIndicator());
      }

      final readings = controller.monthlyReadings.value;
      if (readings.isEmpty) {
        return _buildEmptyState();
      }

      return RefreshIndicator(
        onRefresh: () => controller.refreshData(),
        child: _buildReadingsDataGrid(readings),
      );
    });
  }

  Widget _buildReadingsDataGrid(List<ReadingModel> readings) {
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
                _buildReadingHeaderCell('☑', 40),
                Expanded(
                  flex: 3,
                  child: _buildReadingHeaderCellExpanded('CLIENTE'),
                ),
                Expanded(
                  flex: 2,
                  child: _buildReadingHeaderCellExpanded('LEITURA ANT.'),
                ),
                Expanded(
                  flex: 2,
                  child: _buildReadingHeaderCellExpanded('LEITURA ATUAL'),
                ),
                Expanded(
                  flex: 2,
                  child: _buildReadingHeaderCellExpanded('CONSUMO'),
                ),
                Expanded(
                  flex: 2,
                  child: _buildReadingHeaderCellExpanded('VALOR'),
                ),
                Expanded(
                  flex: 2,
                  child: _buildReadingHeaderCellExpanded('STATUS'),
                ),
              ],
            ),
          ),
          // Data Rows
          Expanded(
            child: ListView.builder(
              itemCount: readings.length,
              itemBuilder: (context, index) {
                final reading = readings[index];
                final isSelected = selectedReadings.contains(reading.id!);
                return _buildReadingDataRow(reading, index, isSelected);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadingHeaderCell(String text, double width) {
    return Container(
      width: width,
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

  Widget _buildReadingHeaderCellExpanded(String text) {
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

  Widget _buildReadingDataRow(
    ReadingModel reading,
    int index,
    bool isSelected,
  ) {
    return InkWell(
      onTap: () => _selectReadingForProcessing(reading),
      child: Container(
        height: 20,
        decoration: BoxDecoration(
          color:
              isSelected
                  ? AppStyles.primaryColor.withOpacity(0.1)
                  : (index % 2 == 0 ? Colors.white : Colors.grey[50]),
          border: Border(
            bottom: BorderSide(color: Colors.grey[200]!, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            _buildReadingDataCell(
              Checkbox(
                value: isSelected,
                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      selectedReadings.add(reading.id!);
                    } else {
                      selectedReadings.remove(reading.id!);
                      selectAll = false;
                    }
                  });
                },
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              40,
            ),
            Expanded(
              flex: 3,
              child: _buildReadingDataCellExpanded(
                FutureBuilder<String>(
                  future: controller.getClientName(reading.clientId),
                  builder: (context, snapshot) {
                    return Text(
                      snapshot.data ?? 'Carregando...',
                      style: const TextStyle(fontSize: 9),
                    );
                  },
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: _buildReadingDataCellExpanded(
                Text(
                  '${reading.previousReading.toStringAsFixed(1)}m³',
                  style: const TextStyle(fontSize: 9),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: _buildReadingDataCellExpanded(
                Text(
                  '${reading.currentReading.toStringAsFixed(1)}m³',
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: _buildReadingDataCellExpanded(
                Text(
                  '${reading.consumption.toStringAsFixed(1)}m³',
                  style: const TextStyle(fontSize: 9, color: Colors.blue),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: _buildReadingDataCellExpanded(
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
              child: _buildReadingDataCellExpanded(
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

  Widget _buildReadingDataCell(Widget child, double width) {
    return Container(
      width: width,
      height: 20,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: Colors.grey[200]!, width: 0.5)),
      ),
      child: Align(alignment: Alignment.centerLeft, child: child),
    );
  }

  Widget _buildReadingDataCellExpanded(Widget child) {
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
      case PaymentStatus.pending:
        return Colors.orange;
      case PaymentStatus.overdue:
        return Colors.red;
      case PaymentStatus.paid:
        return Colors.green;
      case PaymentStatus.partial:
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.pending:
        return 'PENDENTE';
      case PaymentStatus.overdue:
        return 'DÍVIDA';
      case PaymentStatus.paid:
        return 'PAGO';
      case PaymentStatus.partial:
        return 'PARCIAL';
      default:
        return 'N/A';
    }
  }

  void _selectReadingForProcessing(ReadingModel reading) {
    // Navegar para processamento de pagamento com dados pré-carregados
    Get.toNamed(
      Routes.PAYMENT_FORM,
      arguments: {
        'preloaded': true,
        'reading': reading,
        'client': null, // Será carregado no controller
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.speed_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Nenhuma leitura encontrada',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Obx(
            () => Text(
              'Não há leituras para ${_getMonthName(controller.currentMonth.value)} ${controller.currentYear.value}',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Get.toNamed(Routes.READING_FORM),
            icon: const Icon(Icons.add),
            label: const Text('Primeira Leitura'),
          ),
        ],
      ),
    );
  }

  Widget _buildReadingCard(ReadingModel reading, int index) {
    final readingId = reading.id!;
    final isSelected = selectedReadings.contains(readingId);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      color: isSelected ? Colors.blue[50] : null,
      child: InkWell(
        onTap: () => _showReadingActions(reading),
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
                          selectedReadings.add(readingId);
                        } else {
                          selectedReadings.remove(readingId);
                        }
                      });
                    },
                  ),
                  Hero(
                    tag: 'reading_$index',
                    child: CircleAvatar(
                      backgroundColor: Colors.blue.withOpacity(0.1),
                      child: Icon(Icons.speed, color: Colors.blue, size: 20),
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
                            ),
                            Text(
                              'Período: ${reading.month}/${reading.year}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
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
                        '${reading.consumption.toStringAsFixed(1)} m³',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'LEITURA',
                          style: TextStyle(
                            color: Colors.blue,
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
                    child: _buildReadingInfo(
                      'Anterior',
                      reading.previousReading.toStringAsFixed(0),
                      Icons.history,
                    ),
                  ),
                  Expanded(
                    child: _buildReadingInfo(
                      'Atual',
                      reading.currentReading.toStringAsFixed(0),
                      Icons.speed,
                    ),
                  ),
                  Expanded(
                    child: _buildReadingInfo(
                      'Consumo',
                      '${reading.consumption.toStringAsFixed(1)}m³',
                      Icons.water_drop,
                    ),
                  ),
                  Expanded(
                    child: _buildReadingInfo(
                      'Data',
                      _formatDate(reading.readingDate),
                      Icons.calendar_today,
                    ),
                  ),
                ],
              ),
              if (reading.notes?.isNotEmpty == true) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.note, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          reading.notes!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReadingInfo(String label, String value, IconData icon) {
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
              ListTile(
                leading: const Icon(Icons.visibility, color: Colors.blue),
                title: const Text('Ver Detalhes'),
                onTap: () {
                  Get.back();
                  _showReadingDetails(reading);
                },
              ),
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
                    _processPayment(reading);
                  },
                ),
              ],
              ListTile(
                leading: const Icon(Icons.print, color: Colors.purple),
                title: const Text('Imprimir Conta'),
                onTap: () {
                  Get.back();
                  _printBill(reading);
                },
              ),
              ListTile(
                leading: const Icon(Icons.person, color: Colors.indigo),
                title: const Text('Ver Cliente'),
                onTap: () {
                  Get.back();
                  _viewClient(reading.clientId);
                },
              ),
              // Delete option (admin only)
              FutureBuilder<bool>(
                future: _checkIfAdmin(),
                builder: (context, snapshot) {
                  if (snapshot.data == true) {
                    return ListTile(
                      leading: const Icon(Icons.delete, color: Colors.red),
                      title: const Text('Apagar Leitura'),
                      onTap: () {
                        Get.back();
                        controller.deleteReading(reading);
                      },
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSearchDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Buscar Leituras'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Nome do Cliente',
                hintText: 'Digite o nome...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                // TODO: Implement search functionality
              },
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Referência do Cliente',
                hintText: 'Digite a referência...',
                prefixIcon: Icon(Icons.tag),
              ),
              onChanged: (value) {
                // TODO: Implement reference search
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              // TODO: Execute search
            },
            child: const Text('Buscar'),
          ),
        ],
      ),
    );
  }

  void _showFilterOptions() {
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
                'Filtros Avançados',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              const Text(
                'Por Status de Pagamento:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  FilterChip(
                    label: const Text('Pagas'),
                    selected: false, // TODO: Implement selection state
                    onSelected: (selected) => _filterPaid(),
                  ),
                  FilterChip(
                    label: const Text('Pendentes'),
                    selected: false,
                    onSelected: (selected) => _filterPending(),
                  ),
                  FilterChip(
                    label: const Text('Atrasadas'),
                    selected: false,
                    onSelected: (selected) => _filterOverdue(),
                  ),
                  FilterChip(
                    label: const Text('Parciais'),
                    selected: false,
                    onSelected: (selected) => _filterPartial(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Por Consumo:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  FilterChip(
                    label: const Text('Baixo (<5m³)'),
                    selected: false,
                    onSelected: (selected) => _filterLowConsumption(),
                  ),
                  FilterChip(
                    label: const Text('Médio (5-15m³)'),
                    selected: false,
                    onSelected: (selected) => _filterMediumConsumption(),
                  ),
                  FilterChip(
                    label: const Text('Alto (>15m³)'),
                    selected: false,
                    onSelected: (selected) => _filterHighConsumption(),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Get.back();
                        _clearFilters();
                      },
                      child: const Text('Limpar Filtros'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Get.back(),
                      child: const Text('Aplicar'),
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

  void _showReadingDetails(ReadingModel reading) {
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
                    'Detalhes da Leitura',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => _printBill(reading),
                        icon: const Icon(Icons.print),
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
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildDetailCard(
                        'Informações da Leitura',
                        [
                          _buildDetailRow(
                            'Período',
                            '${reading.month}/${reading.year}',
                          ),
                          _buildDetailRow(
                            'Leitura Anterior',
                            reading.previousReading.toStringAsFixed(0),
                          ),
                          _buildDetailRow(
                            'Leitura Atual',
                            reading.currentReading.toStringAsFixed(0),
                          ),
                          _buildDetailRow(
                            'Consumo',
                            '${reading.consumption.toStringAsFixed(1)}m³',
                          ),
                          _buildDetailRow(
                            'Data da Leitura',
                            _formatDateTime(reading.readingDate),
                          ),
                          if (reading.notes?.isNotEmpty == true)
                            _buildDetailRow('Observações', reading.notes!),
                        ],
                        Icons.speed,
                        Colors.blue,
                      ),
                      const SizedBox(height: 16),
                      _buildDetailCard(
                        'Informações Financeiras',
                        [
                          _buildDetailRow(
                            'Valor da Conta',
                            '${reading.billAmount.toStringAsFixed(2)} MT',
                          ),
                          _buildDetailRow(
                            'Status do Pagamento',
                            _getStatusText(reading.paymentStatus),
                          ),
                          if (reading.paymentDate != null)
                            _buildDetailRow(
                              'Data do Pagamento',
                              _formatDateTime(reading.paymentDate!),
                            ),
                        ],
                        Icons.monetization_on,
                        _getStatusColor(reading.paymentStatus),
                      ),
                      const SizedBox(height: 16),
                      FutureBuilder<String>(
                        future: _getClientName(reading.clientId),
                        builder: (context, snapshot) {
                          final clientName = snapshot.data ?? 'Carregando...';
                          return _buildDetailCard(
                            'Informações do Cliente',
                            [
                              _buildDetailRow('Nome', clientName),
                              _buildDetailRow('ID', reading.clientId),
                            ],
                            Icons.person,
                            Colors.green,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailCard(
    String title,
    List<Widget> children,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
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
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
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

  // Filter methods
  void _filterAll() {
    controller.refreshData();
    controller.showSuccess('Mostrando todas as leituras');
  }

  void _filterPaid() {
    // TODO: Implement filter
    controller.showSuccess('Filtro aplicado: Pagas');
  }

  void _filterPending() {
    // TODO: Implement filter
    controller.showSuccess('Filtro aplicado: Pendentes');
  }

  void _filterOverdue() {
    // TODO: Implement filter
    controller.showSuccess('Filtro aplicado: Atrasadas');
  }

  void _filterPartial() {
    // TODO: Implement filter
    controller.showSuccess('Filtro aplicado: Parciais');
  }

  void _filterCurrentMonth() {
    final now = DateTime.now();
    controller.changeMonth(now.month, now.year);
  }

  void _filterLowConsumption() {
    // TODO: Implement consumption filter
    controller.showSuccess('Filtro aplicado: Baixo consumo');
  }

  void _filterMediumConsumption() {
    // TODO: Implement consumption filter
    controller.showSuccess('Filtro aplicado: Médio consumo');
  }

  void _filterHighConsumption() {
    // TODO: Implement consumption filter
    controller.showSuccess('Filtro aplicado: Alto consumo');
  }

  void _clearFilters() {
    controller.refreshData();
    controller.showSuccess('Filtros removidos');
  }

  // Action methods
  void _processPayment(ReadingModel reading) async {
    // Carregar dados do cliente e navegar para formação de pagamento
    try {
      final client = await controller.getClientById(reading.clientId);

      if (client != null) {
        final arguments = {
          'reading': reading,
          'client': client,
          'preloaded': true,
        };

        // Navegar para o formulário de pagamento com dados pré-carregados
        Get.toNamed(Routes.PAYMENT_FORM, arguments: arguments);
      } else {
        Get.snackbar(
          'Erro',
          'Cliente não encontrado',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Erro ao carregar dados do cliente: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _printBill(ReadingModel reading) {
    controller.showSuccess('Conta enviada para impressão');
    // TODO: Implement print functionality
  }

  void _viewClient(String clientId) {
    Get.toNamed(Routes.CLIENT_DETAIL, arguments: clientId);
  }

  Future<bool> _checkIfAdmin() async {
    try {
      // Import AuthController if not already imported
      final authController = Get.find<AuthController>();
      return authController.isAdmin();
    } catch (e) {
      // If AuthController not found, assume not admin
      return false;
    }
  }

  // Helper methods

  IconData _getStatusIcon(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.paid:
        return Icons.check_circle;
      case PaymentStatus.partial:
        return Icons.paid;
      case PaymentStatus.overdue:
        return Icons.warning;
      case PaymentStatus.pending:
        return Icons.pending;
    }
  }

  Future<String> _getClientName(String clientId) async {
    return await controller.getClientName(clientId);
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatDateTime(DateTime date) {
    return '${_formatDate(date)} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
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

  void _printSelected() {
    // TODO: Implementar impressão das leituras selecionadas
    Get.snackbar(
      'Impressão',
      '${selectedReadings.length} leituras selecionadas para impressão',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.purple,
      colorText: Colors.white,
    );
  }

  void _exportSelected() {
    // TODO: Implementar exportação das leituras selecionadas
    Get.snackbar(
      'Exportação',
      '${selectedReadings.length} leituras selecionadas para exportação',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.blue,
      colorText: Colors.white,
    );
  }

  void onInit() {
    // Load data when view initializes
    controller.loadMonthlyReadings();
    controller.loadMonthlyStats();
  }
}
