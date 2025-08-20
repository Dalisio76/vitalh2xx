import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vitalh2x/controlers/user_controller.dart';
import 'package:vitalh2x/models/usuario_model.dart';
import 'package:vitalh2x/utils/app_styles.dart';

class UserFormView extends StatefulWidget {
  const UserFormView({Key? key}) : super(key: key);

  @override
  State<UserFormView> createState() => _UserFormViewState();
}

class _UserFormViewState extends State<UserFormView> {
  final UserController controller = Get.find<UserController>();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    
    // Check if we're editing an existing user
    final user = Get.arguments as UserModel?;
    if (user != null) {
      controller.selectUser(user);
    } else {
      controller.clearForm();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text(controller.formTitle)),
        backgroundColor: AppStyles.primaryColor,
        foregroundColor: Colors.white,
        toolbarHeight: 48,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveUser,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppStyles.paddingLarge),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFormHeader(),
              const SizedBox(height: AppStyles.paddingLarge),
              _buildPersonalInfoSection(),
              const SizedBox(height: AppStyles.paddingLarge),
              _buildAccountInfoSection(),
              const SizedBox(height: AppStyles.paddingLarge),
              _buildPasswordSection(),
              const SizedBox(height: AppStyles.paddingXLarge),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormHeader() {
    return Container(
      padding: const EdgeInsets.all(AppStyles.paddingLarge),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppStyles.primaryColor.withOpacity(0.1),
            AppStyles.primaryColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppStyles.primaryColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(
            controller.isEditing.value ? Icons.edit : Icons.person_add,
            color: AppStyles.primaryColor,
            size: 32,
          ),
          const SizedBox(width: AppStyles.paddingLarge),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Obx(() => Text(
                  controller.formTitle,
                  style: AppStyles.compactTitle.copyWith(
                    color: AppStyles.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                )),
                const SizedBox(height: 4),
                Text(
                  controller.isEditing.value
                      ? 'Edite as informações do usuário'
                      : 'Preencha os dados do novo usuário',
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

  Widget _buildPersonalInfoSection() {
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
            
            // Nome
            TextFormField(
              initialValue: controller.name.value,
              decoration: AppStyles.compactInputDecoration(
                labelText: 'Nome Completo *',
                hintText: 'Digite o nome completo',
                prefixIcon: Icons.person,
              ),
              style: AppStyles.compactBody,
              validator: controller.validateName,
              onChanged: (value) => controller.name.value = value,
            ),
            
            const SizedBox(height: AppStyles.paddingLarge),
            
            // Email
            TextFormField(
              initialValue: controller.email.value,
              decoration: AppStyles.compactInputDecoration(
                labelText: 'Email *',
                hintText: 'Digite o email',
                prefixIcon: Icons.email,
              ),
              style: AppStyles.compactBody,
              keyboardType: TextInputType.emailAddress,
              validator: controller.validateEmail,
              onChanged: (value) => controller.email.value = value,
            ),
            
            const SizedBox(height: AppStyles.paddingLarge),
            
            // Telefone
            TextFormField(
              initialValue: controller.phone.value,
              decoration: AppStyles.compactInputDecoration(
                labelText: 'Telefone',
                hintText: 'Digite o telefone (opcional)',
                prefixIcon: Icons.phone,
              ),
              style: AppStyles.compactBody,
              keyboardType: TextInputType.phone,
              onChanged: (value) => controller.phone.value = value,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountInfoSection() {
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
            
            // Perfil/Role
            Text(
              'Perfil do Usuário *',
              style: AppStyles.compactBody.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Obx(() => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(4),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<UserRole>(
                  value: controller.role.value,
                  isExpanded: true,
                  style: AppStyles.compactBody,
                  items: UserRole.values.map((role) => DropdownMenuItem(
                    value: role,
                    child: Row(
                      children: [
                        Icon(_getRoleIcon(role), size: 16, color: _getRoleColor(role)),
                        const SizedBox(width: 8),
                        Text(role.displayName),
                      ],
                    ),
                  )).toList(),
                  onChanged: (role) {
                    if (role != null) {
                      controller.role.value = role;
                    }
                  },
                ),
              ),
            )),
            
            const SizedBox(height: AppStyles.paddingLarge),
            
            // Status Ativo
            Obx(() => SwitchListTile(
              title: Text(
                'Usuário Ativo',
                style: AppStyles.compactBody.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(
                controller.isActive.value
                    ? 'Usuário pode acessar o sistema'
                    : 'Usuário não pode acessar o sistema',
                style: AppStyles.compactCaption,
              ),
              value: controller.isActive.value,
              onChanged: (value) => controller.isActive.value = value,
              activeColor: AppStyles.primaryColor,
              contentPadding: EdgeInsets.zero,
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppStyles.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Senha',
                  style: AppStyles.compactSubtitle.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (controller.isEditing.value) ...[
                  const SizedBox(width: 8),
                  Text(
                    '(Deixe em branco para manter a atual)',
                    style: AppStyles.compactCaption.copyWith(
                      color: Colors.orange[700],
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppStyles.paddingLarge),
            
            // Senha
            Obx(() => TextFormField(
              initialValue: controller.password.value,
              decoration: AppStyles.compactInputDecoration(
                labelText: controller.isEditing.value ? 'Nova Senha' : 'Senha *',
                hintText: 'Digite a senha',
                prefixIcon: Icons.lock,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                    size: 18,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
              style: AppStyles.compactBody,
              obscureText: _obscurePassword,
              validator: controller.validatePassword,
              onChanged: (value) => controller.password.value = value,
            )),
            
            const SizedBox(height: AppStyles.paddingLarge),
            
            // Confirmar Senha
            Obx(() => TextFormField(
              initialValue: controller.confirmPassword.value,
              decoration: AppStyles.compactInputDecoration(
                labelText: 'Confirmar Senha',
                hintText: 'Digite a senha novamente',
                prefixIcon: Icons.lock_outline,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                    size: 18,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
                ),
              ),
              style: AppStyles.compactBody,
              obscureText: _obscureConfirmPassword,
              validator: controller.validateConfirmPassword,
              onChanged: (value) => controller.confirmPassword.value = value,
            )),
            
            if (!controller.isEditing.value) ...[
              const SizedBox(height: 8),
              Text(
                'A senha deve ter pelo menos 6 caracteres',
                style: AppStyles.compactCaption.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _cancelForm,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: Colors.grey[400]!),
            ),
            child: const Text('Cancelar'),
          ),
        ),
        const SizedBox(width: AppStyles.paddingLarge),
        Expanded(
          flex: 2,
          child: Obx(() => ElevatedButton(
            onPressed: controller.isLoading ? null : _saveUser,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppStyles.primaryColor,
              minimumSize: const Size(double.infinity, 48),
            ),
            child: controller.isLoading
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        controller.isEditing.value ? 'Atualizando...' : 'Salvando...',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        controller.isEditing.value ? Icons.update : Icons.save,
                        size: 18,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        controller.saveButtonText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
          )),
        ),
      ],
    );
  }

  void _saveUser() {
    if (_formKey.currentState!.validate()) {
      controller.saveUser();
    }
  }

  void _cancelForm() {
    Get.dialog(
      AlertDialog(
        title: const Text('Cancelar'),
        content: const Text(
          'Deseja realmente cancelar? As alterações não salvas serão perdidas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Continuar Editando'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back(); // Close dialog
              controller.clearForm();
              Get.back(); // Close form
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cancelar'),
          ),
        ],
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