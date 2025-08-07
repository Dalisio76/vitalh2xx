import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:vitalh2x/controlers/client_controller.dart';
import 'package:vitalh2x/models/cliente_model.dart';

class ClientFormView extends GetView<ClientController> {
  const ClientFormView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ClientModel? client = Get.arguments as ClientModel?;
    final bool isEditing = client != null;
    final _formKey = GlobalKey<FormState>();

    // Controllers para os campos de texto
    final nameController = TextEditingController();
    final contactController = TextEditingController();
    final referenceController = TextEditingController();
    final counterNumberController = TextEditingController();

    // Inicialização e listeners
    _initializeForm(
      isEditing,
      client,
      nameController,
      contactController,
      referenceController,
      counterNumberController,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Cliente' : 'Novo Cliente'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPersonalInfoSection(nameController),
              const SizedBox(height: 20),
              _buildContactInfoSection(contactController),
              const SizedBox(height: 20),
              _buildTechnicalInfoSection(
                referenceController,
                counterNumberController,
              ),
              const SizedBox(height: 20),
              if (isEditing) ...[
                _buildStatusSection(client),
                const SizedBox(height: 20),
              ],
              _buildValidationInfo(),
              const SizedBox(height: 30),
              _buildActionButtons(
                isEditing,
                client,
                _formKey,
                nameController,
                contactController,
                referenceController,
                counterNumberController,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _initializeForm(
    bool isEditing,
    ClientModel? client,
    TextEditingController nameController,
    TextEditingController contactController,
    TextEditingController referenceController,
    TextEditingController counterNumberController,
  ) {
    if (isEditing && client != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.selectClient(client);
        nameController.text = client.name;
        contactController.text = client.contact;
        referenceController.text = client.reference;
        counterNumberController.text = client.counterNumber;
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.clearForm();
        nameController.clear();
        contactController.clear();
        referenceController.clear();
        counterNumberController.clear();
      });
    }

    // Listeners para sincronizar com o controller
    nameController.addListener(() {
      controller.name.value = nameController.text;
    });
    contactController.addListener(() {
      controller.contact.value = contactController.text;
    });
    referenceController.addListener(() {
      controller.reference.value = referenceController.text;
    });
    counterNumberController.addListener(() {
      controller.counterNumber.value = counterNumberController.text;
    });
  }

  Widget _buildPersonalInfoSection(TextEditingController nameController) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person, color: Colors.blue[600]),
                const SizedBox(width: 8),
                const Text(
                  'Informações Pessoais',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nome Completo *',
                hintText: 'Digite o nome do cliente',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_outline),
              ),
              textCapitalization: TextCapitalization.words,
              validator: controller.validateName,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactInfoSection(TextEditingController contactController) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.contact_phone, color: Colors.green[600]),
                const SizedBox(width: 8),
                const Text(
                  'Informações de Contacto',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: contactController,
              decoration: const InputDecoration(
                labelText: 'Contacto *',
                hintText: '+258 XX XXX XXXX',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s()]')),
                LengthLimitingTextInputFormatter(15),
              ],
              validator: controller.validateContact,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTechnicalInfoSection(
    TextEditingController referenceController,
    TextEditingController counterNumberController,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.engineering, color: Colors.orange[600]),
                const SizedBox(width: 8),
                const Text(
                  'Informações Técnicas',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: referenceController,
                    decoration: const InputDecoration(
                      labelText: 'Referência *',
                      hintText: 'Ex: CLI001',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.tag),
                    ),
                    textCapitalization: TextCapitalization.characters,
                    validator: controller.validateReference,
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () => _generateReference(referenceController),
                  child: const Text('Gerar'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: counterNumberController,
              decoration: const InputDecoration(
                labelText: 'Número do Contador *',
                hintText: 'Ex: 123456789',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.electrical_services),
              ),
              validator: controller.validateCounterNumber,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusSection(ClientModel client) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info, color: Colors.purple[600]),
                const SizedBox(width: 8),
                const Text(
                  'Status do Cliente',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: client.isActive ? Colors.green[50] : Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color:
                      client.isActive ? Colors.green[200]! : Colors.red[200]!,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    client.isActive ? Icons.check_circle : Icons.block,
                    color:
                        client.isActive ? Colors.green[700] : Colors.red[700],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          client.isActive ? 'Cliente Ativo' : 'Cliente Inativo',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color:
                                client.isActive
                                    ? Colors.green[700]
                                    : Colors.red[700],
                          ),
                        ),
                        Text(
                          client.isActive
                              ? 'Cliente pode realizar leituras e pagamentos'
                              : 'Cliente está desativado e não aparece nas listas',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (client.totalDebt > 0) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dívida Pendente: ${client.totalDebt.toStringAsFixed(2)} MT',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange[700],
                            ),
                          ),
                          const Text(
                            'Cliente possui contas em aberto',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed:
                          () => Get.toNamed('/payment-form', arguments: client),
                      child: const Text('Pagar'),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green[700]),
                    const SizedBox(width: 12),
                    Text(
                      'Cliente em dia com os pagamentos',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildInfoCard(
                    'Data de Cadastro',
                    _formatDate(client.createdAt),
                    Icons.calendar_today,
                  ),
                ),
                const SizedBox(width: 12),
                if (client.updatedAt != null)
                  Expanded(
                    child: _buildInfoCard(
                      'Última Atualização',
                      _formatDate(client.updatedAt!),
                      Icons.update,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.grey[600], size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 10),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildValidationInfo() {
    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                const SizedBox(width: 8),
                Text(
                  'Informações Importantes',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '• A referência deve ser única e será usada para buscar o cliente\n'
              '• O número do contador deve corresponder ao equipamento instalado\n'
              '• Todos os campos marcados com * são obrigatórios',
              style: TextStyle(fontSize: 12, color: Colors.blue[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(
    bool isEditing,
    ClientModel? client,
    GlobalKey<FormState> formKey,
    TextEditingController nameController,
    TextEditingController contactController,
    TextEditingController referenceController,
    TextEditingController counterNumberController,
  ) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 50,
          child: Obx(
            () => ElevatedButton.icon(
              onPressed:
                  controller.isLoading
                      ? null
                      : () async {
                        if (formKey.currentState!.validate()) {
                          bool success;
                          if (isEditing) {
                            success = await controller.updateClient(
                              client!.id!,
                            );
                          } else {
                            success = await controller.createClient();
                            // Limpa os campos apenas em cadastro novo e se foi bem-sucedido
                            if (success) {
                              _clearAllFields(
                                nameController,
                                contactController,
                                referenceController,
                                counterNumberController,
                              );
                            }
                          }
                        } else {
                          Get.snackbar(
                            'Atenção',
                            'Por favor, preencha todos os campos obrigatórios',
                            snackPosition: SnackPosition.TOP,
                            backgroundColor: Colors.orange[100],
                            colorText: Colors.orange[800],
                            icon: const Icon(
                              Icons.warning,
                              color: Colors.orange,
                            ),
                          );
                        }
                      },
              icon:
                  controller.isLoading
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                      : Icon(isEditing ? Icons.update : Icons.save),
              label: Text(
                controller.isLoading
                    ? controller.loadingMessage.isNotEmpty
                        ? controller.loadingMessage
                        : 'Salvando...'
                    : isEditing
                    ? 'Atualizar Cliente'
                    : 'Salvar Cliente',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  _clearAllFields(
                    nameController,
                    contactController,
                    referenceController,
                    counterNumberController,
                  );
                  controller.clearForm();
                },
                icon: const Icon(Icons.clear),
                label: const Text('Limpar'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _previewClient(isEditing, client),
                icon: const Icon(Icons.visibility),
                label: const Text('Visualizar'),
              ),
            ),
          ],
        ),
        if (isEditing) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed:
                      () => Get.toNamed('/reading-form', arguments: client),
                  icon: const Icon(Icons.speed),
                  label: const Text('Nova Leitura'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.green[600],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              if (client!.totalDebt > 0)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed:
                        () => Get.toNamed('/payment-form', arguments: client),
                    icon: const Icon(Icons.payment),
                    label: const Text('Pagamento'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange[600],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }

  void _clearAllFields(
    TextEditingController nameController,
    TextEditingController contactController,
    TextEditingController referenceController,
    TextEditingController counterNumberController,
  ) {
    nameController.clear();
    contactController.clear();
    referenceController.clear();
    counterNumberController.clear();
  }

  void _generateReference(TextEditingController referenceController) {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final reference = 'CLI${timestamp.substring(timestamp.length - 6)}';
    controller.reference.value = reference;
    referenceController.text = reference;
  }

  void _previewClient(bool isEditing, ClientModel? client) {
    final previewData = {
      'name': controller.name.value,
      'contact': controller.contact.value,
      'reference': controller.reference.value,
      'counterNumber': controller.counterNumber.value,
    };

    Get.bottomSheet(
      Container(
        height: Get.height * 0.6,
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
                    'Visualização do Cliente',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.blue[100],
                        child: Text(
                          previewData['name']!.isNotEmpty
                              ? previewData['name']![0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[800],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        previewData['name']!.isNotEmpty
                            ? previewData['name']!
                            : 'Nome não informado',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      _buildPreviewItem('Contacto', previewData['contact']!),
                      _buildPreviewItem(
                        'Referência',
                        previewData['reference']!,
                      ),
                      _buildPreviewItem(
                        'Contador',
                        previewData['counterNumber']!,
                      ),
                      if (isEditing && client != null) ...[
                        const Divider(),
                        _buildPreviewItem(
                          'Status',
                          client.isActive ? 'Ativo' : 'Inativo',
                        ),
                        _buildPreviewItem(
                          'Dívida',
                          '${client.totalDebt.toStringAsFixed(2)} MT',
                        ),
                      ],
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

  Widget _buildPreviewItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : 'Não informado',
              style: TextStyle(color: value.isEmpty ? Colors.grey : null),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
