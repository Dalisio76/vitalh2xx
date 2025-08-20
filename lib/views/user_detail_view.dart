import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:vitalh2x/controlers/user_controller.dart';
import 'package:vitalh2x/models/usuario_model.dart';
import 'package:vitalh2x/routs/rout.dart';
import 'package:vitalh2x/utils/app_styles.dart';

class UserDetailView extends StatefulWidget {
  const UserDetailView({Key? key}) : super(key: key);

  @override
  State<UserDetailView> createState() => _UserDetailViewState();
}

class _UserDetailViewState extends State<UserDetailView> {
  final UserController controller = Get.find<UserController>();
  late UserModel user;

  @override
  void initState() {
    super.initState();
    user = Get.arguments as UserModel;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes do Usuário'),
        backgroundColor: AppStyles.primaryColor,
        foregroundColor: Colors.white,
        toolbarHeight: 48,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) => _handleAction(value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 18),
                    SizedBox(width: 8),
                    Text('Editar'),
                  ],
                ),
              ),
              if (user.isActive)
                const PopupMenuItem(
                  value: 'deactivate',
                  child: Row(
                    children: [
                      Icon(Icons.block, size: 18),
                      SizedBox(width: 8),
                      Text('Desativar'),
                    ],
                  ),
                )
              else
                const PopupMenuItem(
                  value: 'activate',
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, size: 18),
                      SizedBox(width: 8),
                      Text('Ativar'),
                    ],
                  ),
                ),
              const PopupMenuItem(
                value: 'reset_password',
                child: Row(
                  children: [
                    Icon(Icons.lock_reset, size: 18),
                    SizedBox(width: 8),
                    Text('Redefinir Senha'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 18, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Excluir', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppStyles.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildUserHeader(),
            const SizedBox(height: AppStyles.paddingLarge),
            _buildUserInfo(),
            const SizedBox(height: AppStyles.paddingLarge),
            _buildAccountInfo(),
            const SizedBox(height: AppStyles.paddingLarge),
            _buildActivityInfo(),
            const SizedBox(height: AppStyles.paddingLarge),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildUserHeader() {
    return Container(
      padding: const EdgeInsets.all(AppStyles.paddingLarge),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getRoleColor(user.role).withOpacity(0.1),
            _getRoleColor(user.role).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getRoleColor(user.role).withOpacity(0.2)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: _getRoleColor(user.role).withOpacity(0.2),
            child: Icon(
              _getRoleIcon(user.role),
              size: 32,
              color: _getRoleColor(user.role),
            ),
          ),
          const SizedBox(width: AppStyles.paddingLarge),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: AppStyles.compactTitle.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getRoleColor(user.role),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        user.role.displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: user.isActive ? Colors.green : Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        user.isActive ? 'ATIVO' : 'INATIVO',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  user.email,
                  style: AppStyles.compactBody.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppStyles.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informações Pessoais',
              style: AppStyles.compactSubtitle.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppStyles.paddingLarge),
            
            _buildInfoRow(
              icon: Icons.person,
              label: 'Nome Completo',
              value: user.name,
            ),
            
            _buildInfoRow(
              icon: Icons.email,
              label: 'Email',
              value: user.email,
            ),
            
            _buildInfoRow(
              icon: Icons.phone,
              label: 'Telefone',
              value: user.phone ?? 'Não informado',
              isOptional: user.phone == null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppStyles.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informações da Conta',
              style: AppStyles.compactSubtitle.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppStyles.paddingLarge),
            
            _buildInfoRow(
              icon: _getRoleIcon(user.role),
              label: 'Perfil',
              value: user.role.displayName,
              valueColor: _getRoleColor(user.role),
            ),
            
            _buildInfoRow(
              icon: user.isActive ? Icons.check_circle : Icons.cancel,
              label: 'Status',
              value: user.isActive ? 'Ativo' : 'Inativo',
              valueColor: user.isActive ? Colors.green : Colors.red,
            ),
            
            _buildInfoRow(
              icon: Icons.sync,
              label: 'Sincronizado',
              value: user.isSynced ? 'Sim' : 'Não',
              valueColor: user.isSynced ? Colors.green : Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppStyles.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Atividade',
              style: AppStyles.compactSubtitle.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppStyles.paddingLarge),
            
            _buildInfoRow(
              icon: Icons.calendar_today,
              label: 'Conta Criada',
              value: DateFormat('dd/MM/yyyy HH:mm').format(user.createdAt),
            ),
            
            if (user.updatedAt != null)
              _buildInfoRow(
                icon: Icons.update,
                label: 'Última Atualização',
                value: DateFormat('dd/MM/yyyy HH:mm').format(user.updatedAt!),
              ),
            
            _buildInfoRow(
              icon: Icons.login,
              label: 'Último Login',
              value: user.lastLogin != null
                  ? DateFormat('dd/MM/yyyy HH:mm').format(user.lastLogin!)
                  : 'Nunca fez login',
              isOptional: user.lastLogin == null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    bool isOptional = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppStyles.paddingMedium),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: valueColor ?? Colors.grey[600],
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: AppStyles.compactBody.copyWith(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: AppStyles.compactBody.copyWith(
                color: isOptional
                    ? Colors.grey[500]
                    : (valueColor ?? Colors.black87),
                fontStyle: isOptional ? FontStyle.italic : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _handleAction('edit'),
            icon: const Icon(Icons.edit, size: 18),
            label: const Text('Editar'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(width: AppStyles.paddingMedium),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: user.isActive
                ? () => _handleAction('deactivate')
                : () => _handleAction('activate'),
            icon: Icon(
              user.isActive ? Icons.block : Icons.check_circle,
              size: 18,
            ),
            label: Text(user.isActive ? 'Desativar' : 'Ativar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: user.isActive ? Colors.orange : Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  void _handleAction(String action) {
    switch (action) {
      case 'edit':
        Get.toNamed(Routes.USER_FORM, arguments: user);
        break;
      case 'activate':
        _confirmActivate();
        break;
      case 'deactivate':
        _confirmDeactivate();
        break;
      case 'reset_password':
        _showResetPasswordDialog();
        break;
      case 'delete':
        _confirmDelete();
        break;
    }
  }

  void _confirmActivate() {
    Get.dialog(
      AlertDialog(
        title: const Text('Ativar Usuário'),
        content: Text('Deseja ativar o usuário ${user.name}?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.activateUser(user.id!);
              Get.back(); // Return to previous screen
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Ativar'),
          ),
        ],
      ),
    );
  }

  void _confirmDeactivate() {
    Get.dialog(
      AlertDialog(
        title: const Text('Desativar Usuário'),
        content: Text(
          'Deseja desativar o usuário ${user.name}?\n\nEle não poderá mais acessar o sistema.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.deactivateUser(user.id!);
              Get.back(); // Return to previous screen
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Desativar'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete() {
    Get.dialog(
      AlertDialog(
        title: const Text('Excluir Usuário'),
        content: Text(
          'ATENÇÃO: Esta ação não pode ser desfeita!\n\nDeseja realmente excluir o usuário ${user.name}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.deleteUser(user.id!);
              Get.back(); // Return to previous screen
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  void _showResetPasswordDialog() {
    final TextEditingController passwordController = TextEditingController();
    final TextEditingController confirmPasswordController = TextEditingController();
    bool obscurePassword = true;
    bool obscureConfirmPassword = true;

    Get.dialog(
      StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Redefinir Senha'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Definir nova senha para ${user.name}:'),
                const SizedBox(height: 16),
                TextFormField(
                  controller: passwordController,
                  decoration: InputDecoration(
                    labelText: 'Nova Senha',
                    hintText: 'Digite a nova senha',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscurePassword ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setDialogState(() {
                          obscurePassword = !obscurePassword;
                        });
                      },
                    ),
                  ),
                  obscureText: obscurePassword,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: confirmPasswordController,
                  decoration: InputDecoration(
                    labelText: 'Confirmar Nova Senha',
                    hintText: 'Digite a senha novamente',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setDialogState(() {
                          obscureConfirmPassword = !obscureConfirmPassword;
                        });
                      },
                    ),
                  ),
                  obscureText: obscureConfirmPassword,
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
                  final password = passwordController.text;
                  final confirmPassword = confirmPasswordController.text;

                  if (password.isEmpty) {
                    Get.snackbar('Erro', 'Senha não pode estar vazia');
                    return;
                  }

                  if (password.length < 6) {
                    Get.snackbar('Erro', 'Senha deve ter pelo menos 6 caracteres');
                    return;
                  }

                  if (password != confirmPassword) {
                    Get.snackbar('Erro', 'Confirmação de senha não confere');
                    return;
                  }

                  Get.back();
                  controller.resetPassword(user.id!, password);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppStyles.primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Redefinir'),
              ),
            ],
          );
        },
      ),
    );
  }

  IconData _getRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return Icons.admin_panel_settings;
      case UserRole.cashier:
        return Icons.point_of_sale;
      case UserRole.fieldOperator:
        return Icons.engineering;
    }
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return Colors.red;
      case UserRole.cashier:
        return Colors.blue;
      case UserRole.fieldOperator:
        return Colors.green;
    }
  }
}