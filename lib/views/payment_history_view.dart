import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vitalh2x/controlers/payment_controller.dart';
import 'package:vitalh2x/models/cliente_model.dart';
import 'package:vitalh2x/models/pagamento_model.dart';

class PaymentHistoryView extends GetView<PaymentController> {
  const PaymentHistoryView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String? clientId = Get.arguments as String?;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico de Pagamentos'),
        backgroundColor: Colors.green[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showDateFilter(),
          ),
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () => _printHistory(),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildDateFilterBar(),
          _buildStatsCard(),
          Expanded(child: _buildHistoryList()),
        ],
      ),
    );
  }

  Widget _buildDateFilterBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        border: Border(bottom: BorderSide(color: Colors.green[200]!)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Obx(
              () => Text(
                'Período: ${_formatDate(controller.startDate.value)} - ${_formatDate(controller.endDate.value)}',
                style: TextStyle(fontSize: 14, color: Colors.green[700]),
              ),
            ),
          ),
          TextButton.icon(
            onPressed: () => _showDateFilter(),
            icon: const Icon(Icons.date_range),
            label: const Text('Alterar'),
            style: TextButton.styleFrom(foregroundColor: Colors.green[700]),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Obx(() {
          final stats = controller.paymentStats.value;
          final totalPayments = stats['total_payments'] ?? 0;
          final totalAmount = stats['total_amount'] ?? 0.0;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Resumo do Período',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      'Total Pagamentos',
                      '$totalPayments',
                      Icons.receipt,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatItem(
                      'Valor Total',
                      '${totalAmount.toStringAsFixed(2)} MT',
                      Icons.monetization_on,
                      Colors.green,
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

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(label, style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList() {
    return Obx(() {
      if (controller.isLoading) {
        return const Center(child: CircularProgressIndicator());
      }

      final history = controller.paymentHistory.value;
      if (history.isEmpty) {
        return _buildEmptyState();
      }

      return RefreshIndicator(
        onRefresh: () => controller.loadPaymentHistory(),
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: history.length,
          itemBuilder: (context, index) {
            final payment = history[index];
            return _buildPaymentCard(payment);
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
            'Não há pagamentos registrados\npara o período selecionado',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Get.toNamed('/payment-form'),
            icon: const Icon(Icons.add),
            label: const Text('Novo Pagamento'),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(Map<String, dynamic> paymentData) {
    final clientName = paymentData['client_name'] ?? 'Cliente não encontrado';
    final clientReference = paymentData['client_reference'] ?? '';
    final amount = (paymentData['amount_paid'] ?? 0.0).toDouble();
    final method = paymentData['payment_method'] ?? 0;
    final paymentDate =
        DateTime.tryParse(paymentData['payment_date'] ?? '') ?? DateTime.now();
    final receiptNumber = paymentData['receipt_number'] ?? '';
    final readingMonth = paymentData['reading_month'] ?? 0;
    final readingYear = paymentData['reading_year'] ?? 0;
    final billAmount = (paymentData['bill_amount'] ?? 0.0).toDouble();
    final userName = paymentData['user_name'] ?? 'Usuário';

    final paymentMethodName = PaymentMethod.values[method].displayName;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showPaymentDetails(paymentData),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.green[100],
                    child: Icon(
                      Icons.check,
                      color: Colors.green[800],
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
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
                          'Ref: $clientReference',
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
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[800],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'PAGO',
                          style: TextStyle(
                            color: Colors.green[800],
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
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildDetailItem(
                      'Período',
                      '$readingMonth/$readingYear',
                      Icons.calendar_month,
                    ),
                  ),
                  Expanded(
                    child: _buildDetailItem(
                      'Data',
                      _formatDate(paymentDate),
                      Icons.today,
                    ),
                  ),
                  Expanded(
                    child: _buildDetailItem(
                      'Método',
                      paymentMethodName,
                      Icons.payment,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recibo: $receiptNumber',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  Text(
                    'Por: $userName',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon) {
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

  void _showDateFilter() {
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
                'Filtrar por Período',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.today),
                title: const Text('Hoje'),
                onTap: () => _setDateRange(DateTime.now(), DateTime.now()),
              ),
              ListTile(
                leading: const Icon(Icons.view_week),
                title: const Text('Esta Semana'),
                onTap: () => _setWeekRange(),
              ),
              ListTile(
                leading: const Icon(Icons.calendar_month),
                title: const Text('Este Mês'),
                onTap: () => _setMonthRange(),
              ),
              ListTile(
                leading: const Icon(Icons.date_range),
                title: const Text('Período Personalizado'),
                onTap: () => _showCustomDatePicker(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _setDateRange(DateTime start, DateTime end) {
    controller.changeDateRange(start, end);
    Get.back();
  }

  void _setWeekRange() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    _setDateRange(startOfWeek, endOfWeek);
  }

  void _setMonthRange() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);
    _setDateRange(startOfMonth, endOfMonth);
  }

  void _showCustomDatePicker() async {
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

  void _showPaymentDetails(Map<String, dynamic> paymentData) {
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow(
                        'Cliente',
                        paymentData['client_name'] ?? '',
                      ),
                      _buildDetailRow(
                        'Referência',
                        paymentData['client_reference'] ?? '',
                      ),
                      _buildDetailRow(
                        'Período',
                        '${paymentData['reading_month']}/${paymentData['reading_year']}',
                      ),
                      const Divider(),
                      _buildDetailRow(
                        'Valor da Conta',
                        '${(paymentData['bill_amount'] ?? 0.0).toStringAsFixed(2)} MT',
                      ),
                      _buildDetailRow(
                        'Valor Pago',
                        '${(paymentData['amount_paid'] ?? 0.0).toStringAsFixed(2)} MT',
                      ),
                      _buildDetailRow(
                        'Forma de Pagamento',
                        PaymentMethod
                            .values[paymentData['payment_method'] ?? 0]
                            .displayName,
                      ),
                      _buildDetailRow(
                        'Data do Pagamento',
                        _formatDate(
                          DateTime.parse(paymentData['payment_date']),
                        ),
                      ),
                      _buildDetailRow(
                        'Recibo Nº',
                        paymentData['receipt_number'] ?? '',
                      ),
                      if (paymentData['transaction_reference'] != null)
                        _buildDetailRow(
                          'Referência da Transação',
                          paymentData['transaction_reference'],
                        ),
                      if (paymentData['notes'] != null)
                        _buildDetailRow('Observações', paymentData['notes']),
                      const Divider(),
                      _buildDetailRow(
                        'Registrado por',
                        paymentData['user_name'] ?? '',
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _printHistory() {
    controller.showSuccess('Histórico enviado para impressão');
    // TODO: Implement print functionality
  }

  void _printReceipt(Map<String, dynamic> paymentData) {
    controller.showSuccess('Recibo enviado para impressão');
    // TODO: Implement receipt print functionality
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  void onInit() {
    // super.onInit();
    // Load payment history when view initializes
    controller.loadPaymentHistory();
    controller.loadPaymentStats();
  }
}
