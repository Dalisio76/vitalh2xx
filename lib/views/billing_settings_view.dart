// ===== CONFIGURAÇÕES DE FATURAMENTO =====
// Tela para configurar preço do metro cúbico e outras configurações de faturamento

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:vitalh2x/services/settings_service.dart';
import 'package:vitalh2x/controlers/reading_controller.dart';

class BillingSettingsView extends StatefulWidget {
  const BillingSettingsView({Key? key}) : super(key: key);

  @override
  State<BillingSettingsView> createState() => _BillingSettingsViewState();
}

class _BillingSettingsViewState extends State<BillingSettingsView> {
  final _formKey = GlobalKey<FormState>();
  final SettingsService _settingsService = SettingsService.instance;
  
  // Controllers
  late TextEditingController _priceController;
  late TextEditingController _companyNameController;
  late TextEditingController _companyAddressController;
  late TextEditingController _companyPhoneController;
  late TextEditingController _taxRateController;
  late TextEditingController _minimumChargeController;
  
  // Values
  double _currentPrice = 50.0;
  String _currentCompanyName = '';
  String _currentCompanyAddress = '';
  String _currentCompanyPhone = '';
  double _currentTaxRate = 0.0;
  double _currentMinimumCharge = 0.0;
  int _currentReadingDay = 20;

  bool _isLoading = true;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _initControllers();
    _loadCurrentSettings();
  }

  void _initControllers() {
    _priceController = TextEditingController();
    _companyNameController = TextEditingController();
    _companyAddressController = TextEditingController();
    _companyPhoneController = TextEditingController();
    _taxRateController = TextEditingController();
    _minimumChargeController = TextEditingController();

    // Listen for changes
    _priceController.addListener(_onChanged);
    _companyNameController.addListener(_onChanged);
    _companyAddressController.addListener(_onChanged);
    _companyPhoneController.addListener(_onChanged);
    _taxRateController.addListener(_onChanged);
    _minimumChargeController.addListener(_onChanged);
  }

  void _onChanged() {
    setState(() {
      _hasChanges = true;
    });
  }

  Future<void> _loadCurrentSettings() async {
    try {
      setState(() => _isLoading = true);

      _currentPrice = await _settingsService.getPricePerCubicMeter();
      _currentCompanyName = await _settingsService.getCompanyName();
      _currentCompanyAddress = await _settingsService.getCompanyAddress();
      _currentCompanyPhone = await _settingsService.getCompanyPhone();
      _currentTaxRate = await _settingsService.getTaxRate();
      _currentMinimumCharge = await _settingsService.getMinimumCharge();
      _currentReadingDay = await _settingsService.getReadingDay();

      // Update controllers
      _priceController.text = _currentPrice.toStringAsFixed(2);
      _companyNameController.text = _currentCompanyName;
      _companyAddressController.text = _currentCompanyAddress;
      _companyPhoneController.text = _currentCompanyPhone;
      _taxRateController.text = _currentTaxRate.toStringAsFixed(2);
      _minimumChargeController.text = _currentMinimumCharge.toStringAsFixed(2);

      setState(() {
        _isLoading = false;
        _hasChanges = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      Get.snackbar('Erro', 'Erro ao carregar configurações: $e');
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      // Show loading
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      // Parse values
      final price = double.tryParse(_priceController.text) ?? 0.0;
      final taxRate = double.tryParse(_taxRateController.text) ?? 0.0;
      final minimumCharge = double.tryParse(_minimumChargeController.text) ?? 0.0;

      // Save to preferences
      await _settingsService.setPricePerCubicMeter(price);
      await _settingsService.setCompanyName(_companyNameController.text);
      await _settingsService.setCompanyAddress(_companyAddressController.text);
      await _settingsService.setCompanyPhone(_companyPhoneController.text);
      await _settingsService.setTaxRate(taxRate);
      await _settingsService.setMinimumCharge(minimumCharge);
      await _settingsService.setReadingDay(_currentReadingDay);

      // Update reading controller to use new settings
      try {
        final readingController = Get.find<ReadingController>();
        readingController.update();
      } catch (e) {
        // Controller not found, ignore
      }

      Get.back(); // Close loading dialog

      setState(() => _hasChanges = false);

      Get.snackbar(
        'Sucesso',
        'Configurações salvas com sucesso!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.back(); // Close loading dialog
      Get.snackbar('Erro', 'Erro ao salvar configurações: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações de Faturamento'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        actions: [
          if (_hasChanges)
            TextButton(
              onPressed: _saveSettings,
              child: const Text(
                'SALVAR',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'reset',
                child: Row(
                  children: [
                    Icon(Icons.restore, size: 20),
                    SizedBox(width: 8),
                    Text('Restaurar Padrões'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'test',
                child: Row(
                  children: [
                    Icon(Icons.calculate, size: 20),
                    SizedBox(width: 8),
                    Text('Testar Cálculo'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPricingSection(),
                    const SizedBox(height: 24),
                    _buildCompanySection(),
                    const SizedBox(height: 24),
                    _buildBillingSettingsSection(),
                    const SizedBox(height: 24),
                    _buildActionButtons(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildPricingSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.water_drop, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Preços e Tarifas',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Preço por metro cúbico (principal)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Preço por Metro Cúbico (m³)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _priceController,
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                    ],
                    decoration: InputDecoration(
                      labelText: 'Preço por m³',
                      hintText: '50.00',
                      prefixText: 'MT ',
                      border: const OutlineInputBorder(),
                      suffixIcon: const Icon(Icons.monetization_on),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor digite o preço';
                      }
                      final price = double.tryParse(value);
                      if (price == null || price <= 0) {
                        return 'Digite um preço válido maior que zero';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Este é o valor principal usado para calcular as contas',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Taxa de imposto
            TextFormField(
              controller: _taxRateController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              decoration: const InputDecoration(
                labelText: 'Taxa de Imposto (%)',
                hintText: '0.00',
                suffixText: '%',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.percent),
                helperText: 'Percentual de imposto aplicado na conta (opcional)',
              ),
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  final tax = double.tryParse(value);
                  if (tax == null || tax < 0 || tax > 100) {
                    return 'Digite uma taxa entre 0 e 100';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Tarifa mínima
            TextFormField(
              controller: _minimumChargeController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              decoration: const InputDecoration(
                labelText: 'Tarifa Mínima',
                hintText: '0.00',
                prefixText: 'MT ',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.attach_money),
                helperText: 'Valor mínimo da conta mesmo sem consumo (opcional)',
              ),
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  final charge = double.tryParse(value);
                  if (charge == null || charge < 0) {
                    return 'Digite um valor válido maior ou igual a zero';
                  }
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompanySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.business, color: Colors.orange),
                const SizedBox(width: 8),
                const Text(
                  'Informações da Empresa',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _companyNameController,
              decoration: const InputDecoration(
                labelText: 'Nome da Empresa',
                hintText: 'VitalH2X - Sistema de Água',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.business),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Por favor digite o nome da empresa';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _companyAddressController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Endereço da Empresa',
                hintText: 'Rua, bairro, cidade',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.location_on),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Por favor digite o endereço da empresa';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _companyPhoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Telefone da Empresa',
                hintText: '+258 XXX XXXX',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.phone),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Por favor digite o telefone da empresa';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBillingSettingsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.calendar_today, color: Colors.purple),
                const SizedBox(width: 8),
                const Text(
                  'Configurações de Cobrança',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Dia da leitura
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.purple[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.purple[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Dia da Leitura Mensal',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('Dia: '),
                      DropdownButton<int>(
                        value: _currentReadingDay,
                        items: List.generate(28, (index) {
                          final day = index + 1;
                          return DropdownMenuItem(
                            value: day,
                            child: Text('$day'),
                          );
                        }),
                        onChanged: (value) {
                          setState(() {
                            _currentReadingDay = value ?? 20;
                            _hasChanges = true;
                          });
                        },
                      ),
                      const Spacer(),
                      Text(
                        'Contas viram dívida após dia $_currentReadingDay de cada mês',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ],
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
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: _hasChanges ? _saveSettings : null,
            icon: const Icon(Icons.save),
            label: const Text('Salvar Configurações'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[600],
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey[300],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _testCalculation,
                icon: const Icon(Icons.calculate),
                label: const Text('Testar Cálculo'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _showResetDialog,
                icon: const Icon(Icons.restore),
                label: const Text('Restaurar Padrões'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red[600],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'reset':
        _showResetDialog();
        break;
      case 'test':
        _testCalculation();
        break;
    }
  }

  void _testCalculation() {
    Get.dialog(
      AlertDialog(
        title: const Text('Testar Cálculo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Digite um consumo para testar o cálculo:'),
            const SizedBox(height: 16),
            TextFormField(
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Consumo (m³)',
                hintText: '10.5',
                border: OutlineInputBorder(),
              ),
              onFieldSubmitted: (value) {
                _calculateTestBill(value);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  void _calculateTestBill(String consumptionText) async {
    final consumption = double.tryParse(consumptionText);
    if (consumption == null || consumption <= 0) {
      Get.snackbar('Erro', 'Digite um consumo válido');
      return;
    }

    Get.back(); // Close dialog

    final price = double.tryParse(_priceController.text) ?? 0.0;
    final taxRate = double.tryParse(_taxRateController.text) ?? 0.0;
    final minimumCharge = double.tryParse(_minimumChargeController.text) ?? 0.0;

    double baseAmount = consumption * price;
    if (baseAmount < minimumCharge) {
      baseAmount = minimumCharge;
    }
    
    final taxAmount = baseAmount * (taxRate / 100);
    final totalAmount = baseAmount + taxAmount;

    Get.dialog(
      AlertDialog(
        title: const Text('Resultado do Cálculo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Consumo: ${consumption.toStringAsFixed(2)} m³'),
            Text('Preço por m³: ${price.toStringAsFixed(2)} MT'),
            const Divider(),
            Text('Valor base: ${baseAmount.toStringAsFixed(2)} MT'),
            if (taxRate > 0)
              Text('Imposto (${taxRate.toStringAsFixed(1)}%): ${taxAmount.toStringAsFixed(2)} MT'),
            const Divider(),
            Text(
              'Total: ${totalAmount.toStringAsFixed(2)} MT',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showResetDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Restaurar Configurações Padrão'),
        content: const Text(
          'Tem certeza que deseja restaurar todas as configurações para os valores padrão?\n\n'
          'Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: _resetToDefaults,
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Restaurar'),
          ),
        ],
      ),
    );
  }

  void _resetToDefaults() async {
    Get.back(); // Close dialog

    try {
      await _settingsService.resetToDefaults();
      await _loadCurrentSettings();
      
      Get.snackbar(
        'Sucesso',
        'Configurações restauradas para os valores padrão',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar('Erro', 'Erro ao restaurar configurações: $e');
    }
  }

  @override
  void dispose() {
    _priceController.dispose();
    _companyNameController.dispose();
    _companyAddressController.dispose();
    _companyPhoneController.dispose();
    _taxRateController.dispose();
    _minimumChargeController.dispose();
    super.dispose();
  }
}