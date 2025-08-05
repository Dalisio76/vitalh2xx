// ===== ABOUT VIEW =====
// lib/app/modules/home/views/about_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vitalh2x/services/app_config.dart';

class AboutView extends StatelessWidget {
  const AboutView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Sobre')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // App Logo and Info
            _buildAppInfo(),

            const SizedBox(height: 32),

            // Features Section
            _buildFeaturesSection(),

            const SizedBox(height: 32),

            // Developer Info
            _buildDeveloperInfo(),

            const SizedBox(height: 32),

            // Version Info
            _buildVersionInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildAppInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Get.theme.primaryColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.water_drop,
                size: 50,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 16),

            Text(
              AppConfig.appName,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            const Text(
              'Sistema completo para gestão de clientes de água',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturesSection() {
    final features = [
      {
        'icon': Icons.people,
        'title': 'Gestão de Clientes',
        'desc': 'Cadastro e controle completo',
      },
      {
        'icon': Icons.assessment,
        'title': 'Leituras Mensais',
        'desc': 'Registro automático de consumo',
      },
      {
        'icon': Icons.payment,
        'title': 'Processamento de Pagamentos',
        'desc': 'Múltiplas formas de pagamento',
      },
      {
        'icon': Icons.analytics,
        'title': 'Relatórios Detalhados',
        'desc': 'Análises e estatísticas completas',
      },
      {
        'icon': Icons.print,
        'title': 'Impressão',
        'desc': 'Contas e recibos profissionais',
      },
      {
        'icon': Icons.sync,
        'title': 'Sincronização',
        'desc': 'Trabalho offline e online',
      },
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Funcionalidades',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            ...features
                .map(
                  (feature) => ListTile(
                    leading: Icon(
                      feature['icon'] as IconData,
                      color: Get.theme.primaryColor,
                    ),
                    title: Text(feature['title'] as String),
                    subtitle: Text(feature['desc'] as String),
                  ),
                )
                .toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildDeveloperInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Desenvolvido por',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            const ListTile(
              leading: Icon(Icons.code, color: Colors.blue),
              title: Text('Equipe de Desenvolvimento'),
              subtitle: Text('Sistema desenvolvido com Flutter e GetX'),
            ),

            ListTile(
              leading: const Icon(Icons.location_on, color: Colors.red),
              title: const Text('Localização'),
              subtitle: const Text('Maputo, Moçambique'),
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVersionInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informações da Versão',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            ListTile(
              leading: const Icon(Icons.info, color: Colors.blue),
              title: const Text('Versão'),
              subtitle: Text(AppConfig.appVersion),
            ),

            const ListTile(
              leading: Icon(Icons.build, color: Colors.green),
              title: Text('Build'),
              subtitle: Text('Release'),
            ),

            ListTile(
              leading: const Icon(Icons.calendar_today, color: Colors.orange),
              title: const Text('Data de Compilação'),
              subtitle: Text(_getBuildDate()),
            ),
          ],
        ),
      ),
    );
  }

  String _getBuildDate() {
    final now = DateTime.now();
    return '${now.day}/${now.month}/${now.year}';
  }
}
