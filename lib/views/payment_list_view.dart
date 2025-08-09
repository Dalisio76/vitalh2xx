import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vitalh2x/controlers/payment_controller.dart';
import 'package:vitalh2x/models/cliente_model.dart';
import 'package:vitalh2x/models/pagamento_model.dart';
import 'package:vitalh2x/routs/rout.dart';

class PaymentListView extends GetView<PaymentController> {
  const PaymentListView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista de Pagamentos'),
        backgroundColor: Colors.green[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchDialog(),
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterOptions(),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildQuickFilters(),
          _buildStatsBar(),
          Expanded(child: _buildPaymentsList()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.toNamed(Routes.PAYMENT_FORM),
        icon: const Icon(Icons.payment),
        label: const Text('Novo Pagamento'),
        backgroundColor: Colors.green[600],
      ),
    );
  }

  Widget _buildQuickFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('Hoje', () => _filterToday()),
            const SizedBox(width: 8),
            _buildFilterChip('Esta Semana', () => _filterThisWeek()),
            const SizedBox(width: 8),
            _buildFilterChip('Este Mês', () => _filterThisMonth()),
            const SizedBox(width: 8),
            _buildFilterChip(
              'Dinheiro',
              () => _filterByMethod(PaymentMethod.cash),
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              'Transferência',
              () => _filterByMethod(PaymentMethod.bankTransfer),
            ),
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
      backgroundColor: isReset ? Colors.red[100] : Colors.green[100],
      labelStyle: TextStyle(
        color: isReset ? Colors.red[800] : Colors.green[800],
        fontSize: 12,
      ),
    );
  }

  Widget _buildStatsBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.green[50],
        border: Border(bottom: BorderSide(color: Colors.green[200]!)),
      ),
      child: Obx(() {
        final stats = controller.paymentStats.value;
        final totalPayments = stats['total_payments'] ?? 0;
        final totalAmount = stats['total_amount'] ?? 0.0;

        return Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Icon(Icons.receipt, size: 16, color: Colors.green[700]),
                  const SizedBox(width: 8),
                  Text(
                    '$totalPayments pagamentos',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.green[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                Icon(Icons.monetization_on, size: 16, color: Colors.green[700]),
                const SizedBox(width: 8),
                Text(
                  '${totalAmount.toStringAsFixed(2)} MT',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.green[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        );
      }),
    );
  }

  Widget _buildPaymentsList() {
    return Obx(() {
      if (controller.isLoading) {
        return const Center(child: CircularProgressIndicator());
      }

      final history = controller.paymentHistory.value;
      if (history.isEmpty) {
        return _buildEmptyState();
      }

      return RefreshIndicator(
        onRefresh: () => controller.refreshData(),
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: history.length,
          itemBuilder: (context, index) {
            final payment = history[index];
            return _buildPaymentCard(payment, index);
          },
        ),
      );
    });
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.payment_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Nenhum pagamento encontrado',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Os pagamentos aparecerão aqui\nquando forem processados',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Get.toNamed(Routes.PAYMENT_FORM),
            icon: const Icon(Icons.add),
            label: const Text('Primeiro Pagamento'),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(Map<String, dynamic> paymentData, int index) {
    final clientName = paymentData['client_name'] ?? 'Cliente não encontrado';
    final clientReference = paymentData['client_reference'] ?? '';
    final amount = (paymentData['amount_paid'] ?? 0.0).toDouble();
    final method = paymentData['payment_method'] ?? 0;
    final paymentDate =
        DateTime.tryParse(paymentData['payment_date'] ?? '') ?? DateTime.now();
    final receiptNumber = paymentData['receipt_number'] ?? '';
    final readingMonth = paymentData['reading_month'] ?? 0;
    final readingYear = paymentData['reading_year'] ?? 0;
    final userName = paymentData['user_name'] ?? 'Usuário';

    final paymentMethodName = PaymentMethod.values[method].displayName;
    final isToday = _isToday(paymentDate);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isToday ? 4 : 1,
      color: isToday ? Colors.green[50] : null,
      child: InkWell(
        onTap: () => _showPaymentActions(paymentData),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Hero(
                    tag: 'payment_$index',
                    child: CircleAvatar(
                      backgroundColor: _getPaymentMethodColor(
                        PaymentMethod.values[method],
                      ).withOpacity(0.1),
                      child: Icon(
                        _getPaymentMethodIcon(PaymentMethod.values[method]),
                        color: _getPaymentMethodColor(
                          PaymentMethod.values[method],
                        ),
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                clientName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (isToday)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green[600],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text(
                                  'HOJE',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        Text(
                          'Ref: $clientReference • Recibo: $receiptNumber',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${amount.toStringAsFixed(2)} MT',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                      Text(
                        _formatTime(paymentDate),
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_month,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${_getMonthName(readingMonth)} $readingYear',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          _getPaymentMethodIcon(PaymentMethod.values[method]),
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          paymentMethodName,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Icon(Icons.person, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        userName,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPaymentActions(Map<String, dynamic> paymentData) {
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
                    'Ações do Pagamento',
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
                  _showPaymentDetails(paymentData);
                },
              ),
              ListTile(
                leading: const Icon(Icons.print, color: Colors.green),
                title: const Text('Imprimir Recibo'),
                onTap: () {
                  Get.back();
                  _printReceipt(paymentData);
                },
              ),
              ListTile(
                leading: const Icon(Icons.share, color: Colors.orange),
                title: const Text('Compartilhar'),
                onTap: () {
                  Get.back();
                  _sharePayment(paymentData);
                },
              ),
              ListTile(
                leading: const Icon(Icons.person, color: Colors.purple),
                title: const Text('Ver Cliente'),
                onTap: () {
                  Get.back();
                  _viewClient(paymentData['client_id']);
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
        title: const Text('Buscar Pagamentos'),
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
                labelText: 'Número do Recibo',
                hintText: 'Digite o número...',
                prefixIcon: Icon(Icons.receipt),
              ),
              onChanged: (value) {
                // TODO: Implement receipt search
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
                'Por Forma de Pagamento:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children:
                    PaymentMethod.values
                        .map(
                          (method) => FilterChip(
                            label: Text(method.displayName),
                            selected: false, // TODO: Implement selection state
                            onSelected: (selected) => _filterByMethod(method),
                          ),
                        )
                        .toList(),
              ),
              const SizedBox(height: 16),
              const Text(
                'Por Período:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _selectDateRange(),
                      icon: const Icon(Icons.date_range),
                      label: const Text('Selecionar Período'),
                    ),
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

  void _showPaymentDetails(Map<String, dynamic> paymentData) {
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
                    'Detalhes do Pagamento',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => _printReceipt(paymentData),
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
                      _buildInfoCard(
                        'Informações do Cliente',
                        [
                          _buildInfoRow(
                            'Nome',
                            paymentData['client_name'] ?? '',
                          ),
                          _buildInfoRow(
                            'Referência',
                            paymentData['client_reference'] ?? '',
                          ),
                        ],
                        Icons.person,
                        Colors.blue,
                      ),
                      const SizedBox(height: 16),
                      _buildInfoCard(
                        'Detalhes do Pagamento',
                        [
                          _buildInfoRow(
                            'Valor Pago',
                            '${(paymentData['amount_paid'] ?? 0.0).toStringAsFixed(2)} MT',
                          ),
                          _buildInfoRow(
                            'Forma de Pagamento',
                            PaymentMethod
                                .values[paymentData['payment_method'] ?? 0]
                                .displayName,
                          ),
                          _buildInfoRow(
                            'Data',
                            _formatDateTime(
                              DateTime.parse(paymentData['payment_date']),
                            ),
                          ),
                          _buildInfoRow(
                            'Recibo Nº',
                            paymentData['receipt_number'] ?? '',
                          ),
                          if (paymentData['transaction_reference'] != null)
                            _buildInfoRow(
                              'Referência',
                              paymentData['transaction_reference'],
                            ),
                        ],
                        Icons.payment,
                        Colors.green,
                      ),
                      const SizedBox(height: 16),
                      _buildInfoCard(
                        'Informações da Conta',
                        [
                          _buildInfoRow(
                            'Período',
                            '${paymentData['reading_month']}/${paymentData['reading_year']}',
                          ),
                          _buildInfoRow(
                            'Valor da Conta',
                            '${(paymentData['bill_amount'] ?? 0.0).toStringAsFixed(2)} MT',
                          ),
                        ],
                        Icons.receipt_long,
                        Colors.orange,
                      ),
                      const SizedBox(height: 16),
                      _buildInfoCard(
                        'Informações do Sistema',
                        [
                          _buildInfoRow(
                            'Registrado por',
                            paymentData['user_name'] ?? '',
                          ),
                          if (paymentData['notes'] != null)
                            _buildInfoRow('Observações', paymentData['notes']),
                        ],
                        Icons.info,
                        Colors.purple,
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

  Widget _buildInfoCard(
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

  Widget _buildInfoRow(String label, String value) {
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

  // Filter methods
  void _filterToday() {
    final today = DateTime.now();
    controller.changeDateRange(today, today);
  }

  void _filterThisWeek() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    controller.changeDateRange(startOfWeek, endOfWeek);
  }

  void _filterThisMonth() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);
    controller.changeDateRange(startOfMonth, endOfMonth);
  }

  void _filterByMethod(PaymentMethod method) {
    // TODO: Implement method filter
    controller.showSuccess('Filtro por ${method.displayName} aplicado');
  }

  void _clearFilters() {
    final now = DateTime.now();
    controller.changeDateRange(now.subtract(const Duration(days: 30)), now);
    controller.showSuccess('Filtros removidos');
  }

  void _selectDateRange() async {
    Get.back();

    final DateTimeRange? picked = await showDateRangePicker(
      context: Get.context!,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: controller.startDate.value,
        end: controller.endDate.value,
      ),
    );

    if (picked != null) {
      controller.changeDateRange(picked.start, picked.end);
    }
  }

  // Action methods
  void _printReceipt(Map<String, dynamic> paymentData) {
    controller.showSuccess('Recibo enviado para impressão');
    // TODO: Implement print functionality
  }

  void _sharePayment(Map<String, dynamic> paymentData) {
    controller.showSuccess('Compartilhamento em desenvolvimento');
    // TODO: Implement share functionality
  }

  void _viewClient(String? clientId) {
    if (clientId != null) {
      Get.toNamed(Routes.CLIENT_DETAIL, arguments: clientId);
    }
  }

  // Helper methods
  Color _getPaymentMethodColor(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return Colors.green;
      case PaymentMethod.bankTransfer:
        return Colors.blue;
      case PaymentMethod.mobileMoney:
        return Colors.orange;
      case PaymentMethod.check:
        return Colors.purple;
      case PaymentMethod.other:
      default:
        return Colors.grey;
    }
  }

  IconData _getPaymentMethodIcon(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return Icons.money;
      case PaymentMethod.bankTransfer:
        return Icons.account_balance;
      case PaymentMethod.mobileMoney:
        return Icons.phone_android;
      case PaymentMethod.check:
        return Icons.receipt;
      case PaymentMethod.other:
      default:
        return Icons.payment;
    }
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatDateTime(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${_formatTime(date)}';
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Fev',
      'Mar',
      'Abr',
      'Mai',
      'Jun',
      'Jul',
      'Ago',
      'Set',
      'Out',
      'Nov',
      'Dez',
    ];
    return months[month - 1];
  }

  @override
  void onInit() {
    // super.onInit();
    // Load data when view initializes
    controller.loadPaymentHistory();
    controller.loadPaymentStats();
  }
}
