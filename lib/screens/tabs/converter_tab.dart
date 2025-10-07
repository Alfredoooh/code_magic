import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../services/theme_service.dart';

class ConverterTab extends StatefulWidget {
  const ConverterTab({Key? key}) : super(key: key);

  @override
  State<ConverterTab> createState() => _ConverterTabState();
}

class _ConverterTabState extends State<ConverterTab> {
  final _inputController = TextEditingController();
  String _selectedConverter = 'Moeda';
  String _fromUnit = 'USD';
  String _toUnit = 'EUR';
  String _result = '';

  final Map<String, List<String>> _converterOptions = {
    'Moeda': ['USD', 'EUR', 'GBP', 'JPY', 'BRL'],
    'Comprimento': ['Metro', 'Km', 'Milha', 'Pé', 'Polegada'],
    'Peso': ['Kg', 'Grama', 'Libra', 'Onça', 'Tonelada'],
    'Temperatura': ['Celsius', 'Fahrenheit', 'Kelvin'],
    'Volume': ['Litro', 'Mililitro', 'Galão', 'Xícara', 'm³'],
  };

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _convert() {
    if (_inputController.text.isEmpty) return;

    final value = double.tryParse(_inputController.text);
    if (value == null) {
      setState(() => _result = 'Valor inválido');
      return;
    }

    // Conversão simples de exemplo
    double converted = value;
    
    if (_selectedConverter == 'Temperatura') {
      if (_fromUnit == 'Celsius' && _toUnit == 'Fahrenheit') {
        converted = (value * 9 / 5) + 32;
      } else if (_fromUnit == 'Fahrenheit' && _toUnit == 'Celsius') {
        converted = (value - 32) * 5 / 9;
      } else if (_fromUnit == 'Celsius' && _toUnit == 'Kelvin') {
        converted = value + 273.15;
      } else if (_fromUnit == 'Kelvin' && _toUnit == 'Celsius') {
        converted = value - 273.15;
      }
    }

    setState(() {
      _result = '${converted.toStringAsFixed(2)} $_toUnit';
    });
  }

  @override
  Widget build(BuildContext context) {
    final textColor = ThemeService.currentTheme == AppTheme.light
        ? const Color(0xFF000000)
        : const Color(0xFFFFFFFF);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Conversor'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildConverterTypeSelector(textColor),
            const SizedBox(height: 24),
            _buildInputField(textColor),
            const SizedBox(height: 16),
            _buildUnitSelectors(textColor),
            const SizedBox(height: 24),
            _buildConvertButton(),
            const SizedBox(height: 24),
            if (_result.isNotEmpty) _buildResultCard(textColor),
          ],
        ),
      ),
    );
  }

  Widget _buildConverterTypeSelector(Color textColor) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: textColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _converterOptions.keys.map((type) {
            final isSelected = _selectedConverter == type;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedConverter = type;
                  _fromUnit = _converterOptions[type]![0];
                  _toUnit = _converterOptions[type]![1];
                  _result = '';
                });
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF1877F2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  type,
                  style: TextStyle(
                    color: isSelected ? Colors.white : textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildInputField(Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: textColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withOpacity(0.15)),
      ),
      child: TextField(
        controller: _inputController,
        keyboardType: TextInputType.number,
        style: TextStyle(color: textColor, fontSize: 18),
        decoration: InputDecoration(
          hintText: 'Digite o valor',
          hintStyle: TextStyle(color: textColor.withOpacity(0.4)),
          border: InputBorder.none,
          prefixIcon: Icon(
            CupertinoIcons.number,
            color: textColor.withOpacity(0.6),
          ),
        ),
      ),
    );
  }

  Widget _buildUnitSelectors(Color textColor) {
    final units = _converterOptions[_selectedConverter]!;

    return Row(
      children: [
        Expanded(
          child: _buildUnitDropdown(
            value: _fromUnit,
            items: units,
            textColor: textColor,
            onChanged: (value) {
              setState(() {
                _fromUnit = value!;
                _result = '';
              });
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Icon(
            CupertinoIcons.arrow_right_arrow_left,
            color: textColor.withOpacity(0.6),
          ),
        ),
        Expanded(
          child: _buildUnitDropdown(
            value: _toUnit,
            items: units,
            textColor: textColor,
            onChanged: (value) {
              setState(() {
                _toUnit = value!;
                _result = '';
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildUnitDropdown({
    required String value,
    required List<String> items,
    required Color textColor,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: textColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withOpacity(0.15)),
      ),
      child: DropdownButton<String>(
        value: value,
        isExpanded: true,
        underline: const SizedBox(),
        style: TextStyle(color: textColor, fontSize: 16),
        dropdownColor: ThemeService.currentTheme == AppTheme.light
            ? Colors.white
            : const Color(0xFF2C2C2E),
        items: items.map((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(item),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildConvertButton() {
    return ElevatedButton(
      onPressed: _convert,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1877F2),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: const Text(
        'Converter',
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildResultCard(Color textColor) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1877F2), Color(0xFF0D47A1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1877F2).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Resultado',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _result,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
