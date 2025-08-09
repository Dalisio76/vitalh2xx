// ===== READING FORM VIEW COMPLETA =====
// lib/app/views/reading_form_view.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:vitalh2x/controlers/reading_controller.dart';
import 'package:vitalh2x/models/cliente_model.dart';

class ReadingFormView extends GetView<ReadingController> {
  const ReadingFormView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Verificar se veio com cliente como argumento
    final ClientModel? argumentClient = Get.arguments as ClientModel?;

    // Se veio com cliente, configurar automaticamente
    if (argumentClient != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.selectedClient.value = argumentClient;
        controller.clientReference.value = argumentClient.reference;
        controller.findClientByReference();
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text(controller.formTitle)),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        actions: [
          // Indicador de modo (novo/edição)
          Obx(
            () => Padding(
              padding: const EdgeInsets.all(8.0),
              child: Chip(
                label: Text(
                  controller.isEditing.value ? 'EDIÇÃO' : 'NOVO',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                backgroundColor:
                    controller.isEditing.value ? Colors.orange : Colors.green,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildClientSection(),
            const SizedBox(height: 20),
            _buildReadingSection(),
            const SizedBox(height: 20),
            _buildCalculationSection(),
            const SizedBox(height: 20),
            _buildNotesSection(),
            const SizedBox(height: 30),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildClientSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person_search, color: Colors.blue[600]),
                const SizedBox(width: 8),
                const Text(
                  'Cliente',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Campo de referência
            Obx(
              () => TextFormField(
                initialValue: controller.clientReference.value,
                decoration: const InputDecoration(
                  labelText: 'Referência do Cliente *',
                  hintText: 'Digite a referência (ex: CLI001)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.tag),
                ),
                textCapitalization: TextCapitalization.characters,
                onChanged: (value) => controller.clientReference.value = value,
                onFieldSubmitted: (_) => controller.findClientByReference(),
              ),
            ),

            const SizedBox(height: 12),

            // Botão de busca
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: controller.findClientByReference,
                icon: const Icon(Icons.search),
                label: const Text('Buscar Cliente'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                ),
              ),
            ),

            // Informações do cliente encontrado
            Obx(() {
              final client = controller.selectedClient.value;
              if (client == null) return const SizedBox.shrink();

              return Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green[700]),
                        const SizedBox(width: 8),
                        Text(
                          'Cliente Encontrado',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Nome: ${client.name}'),
                    Text('Contacto: ${client.contact}'),
                    Text('Contador: ${client.counterNumber}'),
                    if (client.lastReading != null)
                      Text(
                        'Última leitura: ${client.lastReading!.toStringAsFixed(1)} m³',
                      ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildReadingSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.speed, color: Colors.orange[600]),
                const SizedBox(width: 8),
                const Text(
                  'Leituras',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Leitura anterior (readonly)
            Obx(
              () => TextFormField(
                initialValue: controller.previousReading.value.toStringAsFixed(
                  1,
                ),
                decoration: const InputDecoration(
                  labelText: 'Leitura Anterior',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.history),
                  suffixText: 'm³',
                ),
                enabled: false,
              ),
            ),

            const SizedBox(height: 16),

            // Leitura atual
            Obx(
              () => TextFormField(
                key: ValueKey(
                  'current_reading_${controller.currentReading.value}',
                ),
                initialValue:
                    controller.currentReading.value > 0
                        ? controller.currentReading.value.toString()
                        : '',
                decoration: const InputDecoration(
                  labelText: 'Leitura Atual *',
                  hintText: 'Digite a leitura atual',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.speed),
                  suffixText: 'm³',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                validator: controller.validateCurrentReading,
                onChanged: (value) {
                  final reading = double.tryParse(value) ?? 0.0;
                  controller.currentReading.value = reading;
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalculationSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calculate, color: Colors.green[600]),
                const SizedBox(width: 8),
                const Text(
                  'Cálculos Automáticos',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.water_drop, color: Colors.blue[700]),
                        const SizedBox(height: 4),
                        const Text('Consumo', style: TextStyle(fontSize: 12)),
                        Obx(
                          () => Text(
                            controller.formattedConsumption,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.attach_money, color: Colors.green[700]),
                        const SizedBox(height: 4),
                        const Text(
                          'Valor da Conta',
                          style: TextStyle(fontSize: 12),
                        ),
                        Obx(
                          () => Text(
                            controller.formattedBillAmount,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.note_add, color: Colors.purple[600]),
                const SizedBox(width: 8),
                const Text(
                  'Observações',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Obx(
              () => TextFormField(
                key: ValueKey('notes_${controller.notes.value}'),
                initialValue: controller.notes.value,
                decoration: const InputDecoration(
                  labelText: 'Observações (opcional)',
                  hintText: 'Digite observações sobre a leitura...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.edit_note),
                ),
                maxLines: 3,
                onChanged: (value) => controller.notes.value = value,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Botão principal (salvar)
        SizedBox(
          width: double.infinity,
          height: 50,
          child: Obx(
            () => ElevatedButton.icon(
              onPressed:
                  controller.isLoading
                      ? null
                      : () {
                        if (controller.selectedClient.value == null) {
                          Get.snackbar(
                            'Atenção',
                            'Selecione um cliente primeiro',
                            backgroundColor: Colors.orange[100],
                            colorText: Colors.orange[800],
                            icon: const Icon(
                              Icons.warning,
                              color: Colors.orange,
                            ),
                            snackPosition: SnackPosition.TOP,
                          );
                          return;
                        }

                        controller.saveReading(); // ← Método unificado
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
                      : Icon(
                        controller.isEditing.value ? Icons.update : Icons.save,
                      ),
              label: Text(
                controller.isLoading
                    ? 'Salvando...'
                    : controller.saveButtonText,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    controller.isEditing.value
                        ? Colors.orange[600]
                        : Colors.blue[600],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Botões secundários
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  controller.clearForm();
                },
                icon: const Icon(Icons.clear),
                label: const Text('Limpar'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showReadingPreview(),
                icon: const Icon(Icons.visibility),
                label: const Text('Visualizar'),
              ),
            ),
          ],
        ),

        // Informações importantes
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.amber[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.amber[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.amber[700]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'A leitura atual deve ser maior que a anterior. '
                  'O consumo e valor são calculados automaticamente.',
                  style: TextStyle(fontSize: 12, color: Colors.amber[700]),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showReadingPreview() {
    if (controller.selectedClient.value == null) {
      Get.snackbar(
        'Atenção',
        'Selecione um cliente primeiro',
        backgroundColor: Colors.orange[100],
        colorText: Colors.orange[800],
        snackPosition: SnackPosition.TOP,
      );
      return;
    }

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
                  Text(
                    'Prévia da ${controller.isEditing.value ? "Edição" : "Leitura"}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPreviewSection(
                        'Cliente',
                        [
                          _buildPreviewItem(
                            'Nome',
                            controller.selectedClient.value!.name,
                          ),
                          _buildPreviewItem(
                            'Referência',
                            controller.selectedClient.value!.reference,
                          ),
                          _buildPreviewItem(
                            'Contador',
                            controller.selectedClient.value!.counterNumber,
                          ),
                        ],
                        Icons.person,
                        Colors.blue,
                      ),
                      const SizedBox(height: 16),
                      _buildPreviewSection(
                        'Leituras',
                        [
                          _buildPreviewItem(
                            'Leitura Anterior',
                            '${controller.previousReading.value.toStringAsFixed(1)} m³',
                          ),
                          _buildPreviewItem(
                            'Leitura Atual',
                            '${controller.currentReading.value.toStringAsFixed(1)} m³',
                          ),
                          _buildPreviewItem(
                            'Consumo',
                            controller.formattedConsumption,
                            highlight: true,
                          ),
                        ],
                        Icons.speed,
                        Colors.orange,
                      ),
                      const SizedBox(height: 16),
                      _buildPreviewSection(
                        'Faturamento',
                        [
                          _buildPreviewItem(
                            'Valor da Conta',
                            controller.formattedBillAmount,
                            highlight: true,
                          ),
                          _buildPreviewItem('Status', 'Pendente'),
                          _buildPreviewItem(
                            'Período',
                            '${controller.currentMonth.value}/${controller.currentYear.value}',
                          ),
                        ],
                        Icons.attach_money,
                        Colors.green,
                      ),
                      if (controller.notes.value.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _buildPreviewSection(
                          'Observações',
                          [_buildPreviewItem('Notas', controller.notes.value)],
                          Icons.note,
                          Colors.purple,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Get.back();
                    controller.saveReading();
                  },
                  icon: Icon(
                    controller.isEditing.value ? Icons.update : Icons.save,
                  ),
                  label: Text(controller.saveButtonText),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        controller.isEditing.value
                            ? Colors.orange[600]
                            : Colors.blue[600],
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewSection(
    String title,
    List<Widget> items,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
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
            const SizedBox(height: 8),
            ...items,
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewItem(
    String label,
    String value, {
    bool highlight = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
                color: highlight ? Colors.green[700] : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
