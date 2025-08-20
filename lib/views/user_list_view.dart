import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vitalh2x/controlers/user_controller.dart';
import 'package:vitalh2x/models/usuario_model.dart';
import 'package:vitalh2x/routs/rout.dart';
import 'package:vitalh2x/utils/app_styles.dart';

class UserListView extends StatefulWidget {
  const UserListView({Key? key}) : super(key: key);

  @override
  State<UserListView> createState() => _UserListViewState();
}

class _UserListViewState extends State<UserListView> {
  final UserController controller = Get.put(UserController());
  final Set<String> selectedUsers = <String>{};
  bool selectAll = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Usuários'),
        backgroundColor: AppStyles.primaryColor,
        foregroundColor: Colors.white,
        toolbarHeight: 48,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchDialog(),
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterOptions(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.refreshData(),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildStatsBar(),
          _buildBulkActions(),
          _buildQuickFilters(),
          Expanded(child: _buildUsersList()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.toNamed(Routes.USER_FORM),
        backgroundColor: AppStyles.primaryColor,
        child: const Icon(Icons.person_add),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(AppStyles.paddingLarge),
      child: TextField(
        decoration: AppStyles.compactInputDecoration(
          hintText: 'Buscar por nome, email ou telefone...',
          prefixIcon: Icons.search,
          suffixIcon: Obx(() {
            if (controller.searchTerm.value.isNotEmpty) {
              return IconButton(
                icon: const Icon(Icons.clear, size: 18),
                onPressed: () => _clearSearch(),
              );
            }
            return const SizedBox.shrink();
          }),
        ),
        style: AppStyles.compactBody,
        onChanged: (value) => controller.searchTerm.value = value,
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
        border: Border(
          bottom: BorderSide(color: AppStyles.primaryColor.withOpacity(0.3)),
        ),
      ),
      child: Obx(() {
        final stats = controller.stats;
        final total = stats['total'] ?? 0;
        final active = stats['active'] ?? 0;
        final admins = stats['admins'] ?? 0;

        return Row(
          children: [
            Expanded(
              child: _buildStatItem(
                'Total',
                '$total',
                Icons.people,
                AppStyles.primaryColor,
              ),
            ),
            Container(
              height: 24,
              width: 1,
              color: AppStyles.primaryColor.withOpacity(0.3),
            ),
            Expanded(
              child: _buildStatItem(
                'Ativos',
                '$active',
                Icons.check,
                AppStyles.secondaryColor,
              ),
            ),
            Container(
              height: 24,
              width: 1,
              color: AppStyles.primaryColor.withOpacity(0.3),
            ),
            Expanded(
              child: _buildStatItem(
                'Admins',
                '$admins',
                Icons.admin_panel_settings,
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
            Text(label, style: AppStyles.compactCaption),
          ],
        ),
      ],
    );
  }

  Widget _buildBulkActions() {
    return Container(
      margin: const EdgeInsets.all(AppStyles.paddingLarge),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppStyles.paddingLarge),
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
                          selectedUsers.addAll(
                            controller.filteredUsers
                                .map((u) => u.id!)
                                .where((id) => id.isNotEmpty),
                          );
                        } else {
                          selectedUsers.clear();
                        }
                      });
                    },
                  ),
                  const Text('Selecionar Todos'),
                  const Spacer(),
                  Text('${selectedUsers.length} selecionados'),
                ],
              ),
              if (selectedUsers.isNotEmpty) ...[ 
                const SizedBox(height: AppStyles.paddingLarge),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _deactivateSelected,
                        icon: const Icon(Icons.block, size: 16),
                        label: const Text('Desativar'),
                        style: AppStyles.compactButtonStyle(
                          backgroundColor: AppStyles.errorColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppStyles.paddingMedium),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _exportSelected,
                        icon: const Icon(Icons.download, size: 16),
                        label: const Text('Exportar'),
                        style: AppStyles.compactButtonStyle(
                          backgroundColor: AppStyles.primaryColor,
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

  Widget _buildQuickFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppStyles.paddingLarge,
        vertical: AppStyles.paddingMedium,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('Todos', () => _filterAll()),
            const SizedBox(width: AppStyles.paddingMedium),
            _buildFilterChip('Ativos', () => _filterActive()),
            const SizedBox(width: AppStyles.paddingMedium),
            _buildFilterChip('Admins', () => _filterAdmins()),
            const SizedBox(width: AppStyles.paddingMedium),
            _buildFilterChip('Caixa', () => _filterCashiers()),
            const SizedBox(width: AppStyles.paddingMedium),
            _buildFilterChip('Campo', () => _filterFieldOperators()),
            const SizedBox(width: AppStyles.paddingMedium),
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
      backgroundColor:
          isReset
              ? AppStyles.errorColor.withOpacity(0.1)
              : AppStyles.primaryColor.withOpacity(0.1),
      labelStyle: AppStyles.compactCaption.copyWith(
        color: isReset ? AppStyles.errorColor : AppStyles.primaryColor,
        fontWeight: FontWeight.w500,
      ),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildUsersList() {
    return Obx(() {
      if (controller.isLoading) {
        return const Center(child: CircularProgressIndicator());
      }

      final users = controller.filteredUsers;
      if (users.isEmpty) {
        return _buildEmptyState();
      }

      return RefreshIndicator(
        onRefresh: () => controller.refreshData(),
        child: _buildDataGrid(users),
      );
    });
  }

  Widget _buildDataGrid(List<UserModel> users) {
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
                _buildHeaderCell('☑', 40),
                Expanded(flex: 3, child: _buildHeaderCellExpanded('NOME')),
                Expanded(flex: 3, child: _buildHeaderCellExpanded('EMAIL')),
                Expanded(flex: 2, child: _buildHeaderCellExpanded('TELEFONE')),
                Expanded(flex: 2, child: _buildHeaderCellExpanded('PERFIL')),
                Expanded(flex: 1, child: _buildHeaderCellExpanded('STATUS')),
              ],
            ),
          ),
          // Data Rows
          Expanded(
            child: ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                final isSelected = selectedUsers.contains(user.id!);
                return _buildDataRow(user, index, isSelected);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String text, double width) {
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

  Widget _buildDataRow(UserModel user, int index, bool isSelected) {
    return InkWell(
      onTap: () => Get.toNamed(Routes.USER_DETAIL, arguments: user),
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
            _buildDataCell(
              Checkbox(
                value: isSelected,
                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      selectedUsers.add(user.id!);
                    } else {
                      selectedUsers.remove(user.id!);
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
              child: _buildDataCellExpanded(
                Text(user.name, style: const TextStyle(fontSize: 9)),
              ),
            ),
            Expanded(
              flex: 3,
              child: _buildDataCellExpanded(
                Text(user.email, style: const TextStyle(fontSize: 9)),
              ),
            ),
            Expanded(
              flex: 2,
              child: _buildDataCellExpanded(
                Text(
                  user.phone ?? 'N/A',
                  style: const TextStyle(fontSize: 9),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: _buildDataCellExpanded(
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 3,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: _getRoleColor(user.role),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Text(
                    _getRoleShortName(user.role),
                    style: const TextStyle(
                      fontSize: 7,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: _buildDataCellExpanded(
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 3,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: user.isActive ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Text(
                    user.isActive ? 'ATIVO' : 'INATIVO',
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

  Widget _buildDataCell(Widget child, double width) {
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

  Widget _buildDataCellExpanded(Widget child) {
    return Container(
      height: 20,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: Colors.grey[200]!, width: 0.5)),
      ),
      child: Align(alignment: Alignment.centerLeft, child: child),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 48, color: Colors.grey[400]),
          const SizedBox(height: AppStyles.paddingLarge),
          Obx(() {
            if (controller.searchTerm.value.isNotEmpty) {
              return Column(
                children: [
                  Text(
                    'Nenhum usuário encontrado',
                    style: AppStyles.compactTitle.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: AppStyles.paddingMedium),
                  Text(
                    'Não encontramos usuários com "${controller.searchTerm.value}"',
                    textAlign: TextAlign.center,
                    style: AppStyles.compactBody.copyWith(
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: AppStyles.paddingLarge),
                  TextButton(
                    onPressed: () => _clearSearch(),
                    child: const Text('Limpar busca'),
                  ),
                ],
              );
            } else {
              return Column(
                children: [
                  Text(
                    'Nenhum usuário cadastrado',
                    style: AppStyles.compactTitle.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: AppStyles.paddingMedium),
                  Text(
                    'Comece adicionando o primeiro usuário',
                    textAlign: TextAlign.center,
                    style: AppStyles.compactBody.copyWith(
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              );
            }
          }),
          const SizedBox(height: AppStyles.paddingXLarge),
          ElevatedButton.icon(
            onPressed: () => Get.toNamed(Routes.USER_FORM),
            icon: const Icon(Icons.person_add, size: 16),
            label: const Text('Primeiro Usuário'),
            style: AppStyles.compactButtonStyle(),
          ),
        ],
      ),
    );
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

  String _getRoleShortName(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'ADM';
      case UserRole.cashier:
        return 'CAIXA';
      case UserRole.fieldOperator:
        return 'CAMPO';
    }
  }

  void _showSearchDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Buscar Usuários'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Nome do Usuário',
                hintText: 'Digite o nome...',
                prefixIcon: Icon(Icons.person_search),
              ),
              onChanged: (value) => controller.searchTerm.value = value,
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'Digite o email...',
                prefixIcon: Icon(Icons.email),
              ),
              onChanged: (value) => controller.searchTerm.value = value,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Fechar')),
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
              SwitchListTile(
                title: const Text('Mostrar apenas ativos'),
                value: controller.showOnlyActive.value,
                onChanged: (value) {
                  controller.showOnlyActive.value = value;
                },
              ),
              const SizedBox(height: 10),
              const Text('Filtrar por Perfil:'),
              Obx(() => DropdownButton<UserRole?>(
                value: controller.filterRole.value,
                isExpanded: true,
                hint: const Text('Selecione um perfil'),
                items: [
                  const DropdownMenuItem<UserRole?>(
                    value: null,
                    child: Text('Todos os perfis'),
                  ),
                  ...UserRole.values.map((role) => DropdownMenuItem(
                    value: role,
                    child: Text(role.displayName),
                  )),
                ],
                onChanged: (value) {
                  controller.filterRole.value = value;
                },
              )),
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

  // Filter methods
  void _filterAll() {
    controller.filterRole.value = null;
    controller.showOnlyActive.value = false;
  }

  void _filterActive() {
    controller.filterRole.value = null;
    controller.showOnlyActive.value = true;
  }

  void _filterAdmins() {
    controller.filterRole.value = UserRole.admin;
    controller.showOnlyActive.value = true;
  }

  void _filterCashiers() {
    controller.filterRole.value = UserRole.cashier;
    controller.showOnlyActive.value = true;
  }

  void _filterFieldOperators() {
    controller.filterRole.value = UserRole.fieldOperator;
    controller.showOnlyActive.value = true;
  }

  void _clearFilters() {
    controller.filterRole.value = null;
    controller.showOnlyActive.value = true;
    controller.searchTerm.value = '';
  }

  void _clearSearch() {
    controller.searchTerm.value = '';
  }

  // Bulk action methods
  void _deactivateSelected() {
    if (selectedUsers.isEmpty) return;

    Get.dialog(
      AlertDialog(
        title: const Text('Desativar Usuários'),
        content: Text(
          'Deseja desativar ${selectedUsers.length} usuários selecionados?',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              _confirmDeactivateSelected();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Desativar'),
          ),
        ],
      ),
    );
  }

  void _confirmDeactivateSelected() async {
    try {
      for (String userId in selectedUsers) {
        await controller.deactivateUser(userId);
      }
      setState(() {
        selectedUsers.clear();
        selectAll = false;
      });
      Get.snackbar(
        'Sucesso',
        'Usuários desativados com sucesso',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Erro ao desativar usuários: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _exportSelected() {
    if (selectedUsers.isEmpty) return;

    Get.snackbar(
      'Exportação',
      '${selectedUsers.length} usuários selecionados para exportação',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.blue,
      colorText: Colors.white,
    );
  }
}