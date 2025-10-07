import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../services/theme_service.dart';

// converter_tab.dart
class ConverterTab extends StatefulWidget {
  @override
  State<ConverterTab> createState() => _ConverterTabState();
}

class _ConverterTabState extends State<ConverterTab> {
  final _inputController = TextEditingController();
  String _selectedConverter = 'Moeda';
  String _result = '';

  final List<String> _converters = [
    'Moeda',
    'Temperatura',
    'Comprimento',
    'Peso',
    'Volume',
  ];

  void _convert() {
    final input = double.tryParse(_inputController.text);
    if (input == null) return;

    setState(() {
      switch (_selectedConverter) {
        case 'Moeda':
          _result = 'USD ${(input * 0.20).toStringAsFixed(2)}';
          break;
        case 'Temperatura':
          _result = '${((input * 9 / 5) + 32).toStringAsFixed(1)}°F';
          break;
        case 'Comprimento':
          _result = '${(input * 3.281).toStringAsFixed(2)} pés';
          break;
        case 'Peso':
          _result = '${(input * 2.205).toStringAsFixed(2)} libras';
          break;
        case 'Volume':
          _result = '${(input * 0.264).toStringAsFixed(2)} galões';
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeService.backgroundColor,
      appBar: AppBar(
        backgroundColor: ThemeService.backgroundColor,
        elevation: 0,
        title: Text(
          'Conversor',
          style: TextStyle(
            color: ThemeService.textColor,
            fontSize: 28,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tipo de Conversão',
              style: TextStyle(
                color: ThemeService.textColor,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: ThemeService.cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: ThemeService.isDarkMode
                      ? Colors.white.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.3),
                ),
              ),
              child: DropdownButton<String>(
                value: _selectedConverter,
                isExpanded: true,
                underline: Container(),
                dropdownColor: ThemeService.cardColor,
                style: TextStyle(
                  color: ThemeService.textColor,
                  fontSize: 16,
                ),
                items: _converters.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedConverter = newValue;
                      _result = '';
                    });
                  }
                },
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Valor',
              style: TextStyle(
                color: ThemeService.textColor,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: ThemeService.cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: ThemeService.isDarkMode
                      ? Colors.white.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.3),
                ),
              ),
              child: TextField(
                controller: _inputController,
                keyboardType: TextInputType.number,
                style: TextStyle(
                  color: ThemeService.textColor,
                  fontSize: 16,
                ),
                decoration: InputDecoration(
                  hintText: 'Digite o valor',
                  hintStyle: TextStyle(
                    color: ThemeService.textColor.withOpacity(0.5),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _convert,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1877F2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Converter',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            if (_result.isNotEmpty) ...[
              const SizedBox(height: 32),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF1877F2).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF1877F2).withOpacity(0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'Resultado',
                      style: TextStyle(
                        color: ThemeService.textColor.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _result,
                      style: const TextStyle(
                        color: Color(0xFF1877F2),
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }
}
