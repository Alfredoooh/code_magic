// lib/screens/settings_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Estado local: opção para desativar acesso restrito (somente UI por enquanto)
  bool _disableRestrictedAccess = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2C2C2E).withOpacity(0.9),
        elevation: 0,
        centerTitle: true,
        title: const Text('Configurações', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(CupertinoIcons.back, color: Color(0xFF007AFF)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.06)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Geral', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(child: Text('Desativar Acesso Restrito', style: TextStyle(color: Colors.white))),
                      CupertinoSwitch(
                        value: _disableRestrictedAccess,
                        onChanged: (v) {
                          setState(() => _disableRestrictedAccess = v);
                          // NOTA: não integra com o modelo — é apenas UI local.
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ao ativar esta opção, o app exibirá as telas sem exigir verificação extra (apenas UI local).',
                    style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Espaço para futuras opções (por enquanto vazio conforme pedido)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.06)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Outras Opções', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Nenhuma opção por enquanto.', style: TextStyle(color: Colors.white.withOpacity(0.6))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}