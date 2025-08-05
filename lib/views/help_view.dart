// ===== HELP VIEW =====
// lib/app/modules/home/views/help_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HelpView extends StatelessWidget {
  const HelpView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Ajuda')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHelpSection('Como fazer uma leitura', [
            '1. Vá para "Leituras" no menu principal',
            '2. Toque em "Nova Leitura"',
            '3. Digite a referência do cliente',
            '4. Insira a leitura atual do contador',
            '5. O sistema calculará automaticamente o consumo',
            '6. Adicione observações se necessário',
            '7. Salve a leitura',
          ], Icons.assessment),

          _buildHelpSection('Como processar um pagamento', [
            '1. Vá para "Pagamentos" no menu principal',
            '2. Toque em "Processar Pagamento"',
            '3. Digite a referência do cliente',
            '4. Selecione a conta a pagar',
            '5. Escolha a forma de pagamento',
            '6. Confirme o valor',
            '7. Processe o pagamento',
            '8. Imprima o recibo se necessário',
          ], Icons.payment),

          _buildHelpSection('Como cadastrar um cliente', [
            '1. Vá para "Clientes" no menu principal',
            '2. Toque em "Novo Cliente"',
            '3. Preencha o nome do cliente',
            '4. Adicione o contacto',
            '5. Defina uma referência única',
            '6. Insira o número do contador',
            '7. Salve o cadastro',
          ], Icons.person_add),

          _buildHelpSection('Níveis de Usuário', [
            'Administrador: Acesso completo ao sistema',
            'Caixa: Pode processar pagamentos e cadastrar clientes',
            'Operador de Campo: Pode apenas fazer leituras',
          ], Icons.people),

          _buildContactSection(),
        ],
      ),
    );
  }

  Widget _buildHelpSection(String title, List<String> steps, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        leading: Icon(icon, color: Get.theme.primaryColor),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children:
                  steps
                      .map(
                        (step) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            step,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      )
                      .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.support, color: Get.theme.primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Precisa de mais ajuda?',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Entre em contacto com o suporte técnico:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            const Text(
              'Email: suporte@waterSystem.local\nTelefone: +258 84 000 0000',
              style: TextStyle(fontSize: 14, fontFamily: 'monospace'),
            ),
          ],
        ),
      ),
    );
  }
}
