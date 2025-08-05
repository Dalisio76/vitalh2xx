// ===== PLACEHOLDER VIEWS =====
// lib/app/modules/home/views/settings_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vitalh2x/bidings/dependency_injection.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Configurações')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // User Profile Section
          _buildUserProfileSection(),

          const SizedBox(height: 24),

          // System Settings Section
          _buildSystemSettingsSection(),

          const SizedBox(height: 24),

          // About Section
          _buildAboutSection(),
        ],
      ),
    );
  }

  Widget _buildUserProfileSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Perfil do Usuário',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            ListTile(
              leading: CircleAvatar(
                backgroundColor: Get.theme.primaryColor,
                child: Text(
                  DI.userName.isNotEmpty ? DI.userName[0].toUpperCase() : 'U',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              title: Text(DI.userName),
              subtitle: Text(DI.userRole),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // TODO: Navigate to profile edit
                Get.snackbar('Info', 'Edição de perfil em desenvolvimento');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemSettingsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Configurações do Sistema',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            ListTile(
              leading: const Icon(Icons.backup),
              title: const Text('Backup de Dados'),
              subtitle: const Text('Fazer backup da base de dados'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showBackupDialog(),
            ),

            ListTile(
              leading: const Icon(Icons.sync),
              title: const Text('Sincronização'),
              subtitle: const Text('Sincronizar com servidor'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Get.snackbar('Info', 'Sincronização em desenvolvimento');
              },
            ),

            if (DI.isAdmin) ...[
              ListTile(
                leading: const Icon(Icons.people),
                title: const Text('Gestão de Usuários'),
                subtitle: const Text('Gerenciar usuários do sistema'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Get.snackbar('Info', 'Gestão de usuários em desenvolvimento');
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAboutSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sobre',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('Sobre o App'),
              subtitle: const Text('Informações da aplicação'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Get.toNamed('/about'),
            ),

            ListTile(
              leading: const Icon(Icons.help),
              title: const Text('Ajuda'),
              subtitle: const Text('Obter ajuda e suporte'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Get.toNamed('/help'),
            ),
          ],
        ),
      ),
    );
  }

  void _showBackupDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Backup de Dados'),
        content: const Text('Deseja fazer backup da base de dados atual?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Get.back();
              try {
                Get.snackbar('Info', 'Iniciando backup...');
                final backupPath = await DI.database.backupDatabase();
                Get.snackbar(
                  'Sucesso',
                  'Backup criado: ${backupPath.split('/').last}',
                  duration: const Duration(seconds: 5),
                );
              } catch (e) {
                Get.snackbar('Erro', 'Erro ao criar backup: $e');
              }
            },
            child: const Text('Fazer Backup'),
          ),
        ],
      ),
    );
  }
}
