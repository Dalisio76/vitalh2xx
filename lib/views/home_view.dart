// ===== HOME VIEW =====
// lib/app/modules/home/views/home_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vitalh2x/bidings/dependency_injection.dart';
import 'package:vitalh2x/controlers/client_controller.dart';
import 'package:vitalh2x/controlers/payment_controller.dart';
import 'package:vitalh2x/controlers/reading_controller.dart';
import 'package:vitalh2x/routs/router_helper.dart';
import 'package:vitalh2x/widgets/quick_action_card.dart';
import 'package:vitalh2x/widgets/stats_card.dart';

class HomeView extends StatelessWidget {
  const HomeView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Início'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Get.toNamed('/settings'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _showLogoutDialog(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Section
              _buildWelcomeSection(),

              const SizedBox(height: 24),

              // Stats Section
              _buildStatsSection(),

              const SizedBox(height: 24),

              // Quick Actions Section
              _buildQuickActionsSection(),

              const SizedBox(height: 24),

              // Recent Activity Section
              _buildRecentActivitySection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Get.theme.primaryColor,
            Get.theme.primaryColor.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Olá, ${DI.userName}!',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Perfil: ${DI.userRole}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Tenha um ótimo dia de trabalho!',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Estatísticas Rápidas',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 16),
        _buildStatsGrid(),
      ],
    );
  }

  Widget _buildStatsGrid() {
    return GetBuilder<ClientController>(
      init: DI.client,
      builder: (clientController) {
        return GetBuilder<ReadingController>(
          init: DI.reading,
          builder: (readingController) {
            return GetBuilder<PaymentController>(
              init: DI.payment,
              builder: (paymentController) {
                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.5,
                  children: [
                    StatsCard(
                      title: 'Clientes Ativos',
                      value: '${clientController.stats['active'] ?? 0}',
                      icon: Icons.people,
                      color: Colors.blue,
                      onTap:
                          DI.canRegisterClients
                              ? () => RouteHelper.toClients()
                              : null,
                    ),
                    StatsCard(
                      title: 'Leituras Mês',
                      value: '${readingController.monthlyStats['total'] ?? 0}',
                      icon: Icons.assessment,
                      color: Colors.green,
                      onTap: () => Get.toNamed('/readings'),
                    ),
                    StatsCard(
                      title: 'Contas Pendentes',
                      value:
                          '${readingController.monthlyStats['pending'] ?? 0}',
                      icon: Icons.pending_actions,
                      color: Colors.orange,
                      onTap:
                          DI.canRegisterPayments
                              ? () => RouteHelper.toPayments()
                              : null,
                    ),
                    StatsCard(
                      title: 'Arrecadado',
                      value:
                          '${(paymentController.paymentStats['total_amount'] ?? 0.0).toStringAsFixed(0)} MT',
                      icon: Icons.monetization_on,
                      color: Colors.purple,
                      onTap:
                          DI.canRegisterPayments
                              ? () => RouteHelper.toPayments()
                              : null,
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ações Rápidas',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 16),
        _buildQuickActionsGrid(),
      ],
    );
  }

  Widget _buildQuickActionsGrid() {
    final actions = <Map<String, dynamic>>[];

    // All users can access readings
    actions.add({
      'title': 'Nova Leitura',
      'subtitle': 'Registrar leitura do contador',
      'icon': Icons.add_chart,
      'color': Colors.blue,
      'onTap': () => Get.toNamed('/readings/form'),
    });

    // Admin and Cashier can register clients
    if (DI.canRegisterClients) {
      actions.add({
        'title': 'Novo Cliente',
        'subtitle': 'Cadastrar novo cliente',
        'icon': Icons.person_add,
        'color': Colors.green,
        'onTap': () => Get.toNamed('/clients/form'),
      });
    }

    // Admin and Cashier can process payments
    if (DI.canRegisterPayments) {
      actions.add({
        'title': 'Processar Pagamento',
        'subtitle': 'Registrar pagamento',
        'icon': Icons.payment,
        'color': Colors.orange,
        'onTap': () => Get.toNamed('/payments/form'),
      });
    }

    // Admin and Cashier can view reports
    if (!DI.canOnlyReadMeters) {
      actions.add({
        'title': 'Relatórios',
        'subtitle': 'Ver relatórios e estatísticas',
        'icon': Icons.analytics,
        'color': Colors.purple,
        'onTap': () => RouteHelper.toReports(),
      });
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.2,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        return QuickActionCard(
          title: action['title'],
          subtitle: action['subtitle'],
          icon: action['icon'],
          color: action['color'],
          onTap: action['onTap'],
        );
      },
    );
  }

  Widget _buildRecentActivitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Atividade Recente',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            TextButton(
              onPressed: () => Get.toNamed('/readings'),
              child: const Text('Ver Todas'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildRecentActivityList(),
      ],
    );
  }

  Widget _buildRecentActivityList() {
    return GetBuilder<ReadingController>(
      init: DI.reading,
      builder: (controller) {
        final recentReadings = controller.monthlyReadings.take(5).toList();

        if (recentReadings.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                'Nenhuma atividade recente',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: recentReadings.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final reading = recentReadings[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: reading.isPaid ? Colors.green : Colors.orange,
                child: Icon(
                  reading.isPaid ? Icons.check : Icons.schedule,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              title: Text(
                'Leitura ${reading.monthYear}',
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              subtitle: Text(
                'Consumo: ${reading.consumption.toStringAsFixed(1)} m³',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              trailing: Text(
                '${reading.billAmount.toStringAsFixed(0)} MT',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: reading.isPaid ? Colors.green : Colors.orange,
                  fontSize: 14,
                ),
              ),
              onTap: () {
                // Navigate to reading details
                Get.toNamed('/readings/detail', arguments: reading);
              },
            );
          },
        );
      },
    );
  }

  Future<void> _refreshData() async {
    try {
      // Refresh all data
      await DI.client.refreshData();
      await DI.reading.refreshData();
      await DI.payment.refreshData();
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Erro ao atualizar dados: $e',
        snackPosition: SnackPosition.TOP,
      );
    }
  }

  void _showLogoutDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Logout'),
        content: const Text('Tem certeza que deseja sair?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              DI.auth.logout();
            },
            child: const Text('Sair'),
          ),
        ],
      ),
    );
  }
}
