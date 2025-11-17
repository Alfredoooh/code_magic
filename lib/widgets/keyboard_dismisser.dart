// lib/widgets/keyboard_dismisser.dart
import 'package:flutter/material.dart';

/// Widget wrapper que fecha o teclado ao tocar fora dos inputs
/// e previne o bug da área preta
class KeyboardDismisser extends StatelessWidget {
  final Widget child;

  const KeyboardDismisser({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      behavior: HitTestBehavior.opaque,
      child: child,
    );
  }
}

// EXEMPLO DE USO na SearchScreen:

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF242526) : Colors.white;
    final scaffoldBgColor = isDark ? const Color(0xFF18191A) : const Color(0xFFF0F2F5);

    return KeyboardDismisser(  // <-- WRAPPER AQUI
      child: Scaffold(
        backgroundColor: scaffoldBgColor,
        resizeToAvoidBottomInset: true,  // <-- IMPORTANTE: true aqui
        appBar: AppBar(
          backgroundColor: bgColor,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          title: TextField(
            controller: _searchController,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Pesquisar usuários...',
              border: InputBorder.none,
              // O tema do main.dart já cuida da estilização
            ),
          ),
        ),
        body: Column(
          children: [
            // Abas
            Container(
              color: bgColor,
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {},
                      child: const Text('Usuários'),
                    ),
                  ),
                  Expanded(
                    child: TextButton(
                      onPressed: () {},
                      child: const Text('Conversas'),
                    ),
                  ),
                  Expanded(
                    child: TextButton(
                      onPressed: () {},
                      child: const Text('Diário'),
                    ),
                  ),
                ],
              ),
            ),
            
            // Resultados
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: 10,
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: CircleAvatar(
                      child: Text('U$index'),
                    ),
                    title: Text('Usuário $index'),
                    subtitle: Text('Estudante'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

// ===== REGRAS IMPORTANTES =====

// 1. SEMPRE usar KeyboardDismisser em telas com TextField
// 2. SEMPRE usar resizeToAvoidBottomInset: true nessas telas
// 3. NUNCA usar resizeToAvoidBottomInset: false em telas com inputs
// 4. O main.dart já tem InputDecorationTheme configurado