// word_editor_screen.dart
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';

class WordEditorScreen extends StatefulWidget {
  const WordEditorScreen({super.key});

  @override
  State<WordEditorScreen> createState() => _WordEditorScreenState();
}

class _WordEditorScreenState extends State<WordEditorScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  
  // Configurações de estilo
  bool _isBold = false;
  bool _isItalic = false;
  bool _isUnderline = false;
  TextAlign _textAlign = TextAlign.left;
  double _fontSize = 16.0;
  Color _textColor = Colors.black;
  Color _backgroundColor = Colors.white;
  String _selectedFrame = 'none';
  
  // Lista de documentos recentes
  List<String> _recentDocs = ['Documento sem título'];
  String _currentDoc = 'Documento sem título';

  // Histórico para desfazer/refazer
  List<String> _history = [];
  int _historyIndex = -1;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    if (_historyIndex == -1 || _controller.text != _history[_historyIndex]) {
      setState(() {
        _history = _history.sublist(0, _historyIndex + 1);
        _history.add(_controller.text);
        _historyIndex++;
        if (_history.length > 50) {
          _history.removeAt(0);
          _historyIndex--;
        }
      });
    }
  }

  void _undo() {
    if (_historyIndex > 0) {
      setState(() {
        _historyIndex--;
        _controller.text = _history[_historyIndex];
        _controller.selection = TextSelection.collapsed(
          offset: _controller.text.length,
        );
      });
    }
  }

  void _redo() {
    if (_historyIndex < _history.length - 1) {
      setState(() {
        _historyIndex++;
        _controller.text = _history[_historyIndex];
        _controller.selection = TextSelection.collapsed(
          offset: _controller.text.length,
        );
      });
    }
  }

  TextStyle _getTextStyle() {
    return TextStyle(
      fontSize: _fontSize,
      fontWeight: _isBold ? FontWeight.bold : FontWeight.normal,
      fontStyle: _isItalic ? FontStyle.italic : FontStyle.normal,
      decoration: _isUnderline ? TextDecoration.underline : TextDecoration.none,
      color: _textColor,
      height: 1.5,
    );
  }

  void _showFrameSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildFrameSelector(),
    );
  }

  void _showBackgroundSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildBackgroundSelector(),
    );
  }

  Widget _buildFrameSelector() {
    final frames = [
      {'name': 'Nenhuma', 'value': 'none'},
      {'name': 'Simples', 'value': 'simple'},
      {'name': 'Sombra', 'value': 'shadow'},
      {'name': 'Arredondada', 'value': 'rounded'},
      {'name': 'Negrito', 'value': 'bold'},
      {'name': 'Dupla', 'value': 'double'},
      {'name': 'Tracejada', 'value': 'dashed'},
      {'name': 'Pontilhada', 'value': 'dotted'},
      {'name': 'Gradiente', 'value': 'gradient'},
      {'name': 'Elegante', 'value': 'elegant'},
      {'name': 'Moderna', 'value': 'modern'},
      {'name': 'Clássica', 'value': 'classic'},
    ];

    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Molduras',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: frames.length,
              itemBuilder: (context, index) {
                final frame = frames[index];
                final isSelected = _selectedFrame == frame['value'];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedFrame = frame['value'] as String;
                    });
                    Navigator.pop(context);
                  },
                  child: Container(
                    decoration: _getFrameDecoration(frame['value'] as String)
                        .copyWith(
                      color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.white,
                    ),
                    child: Center(
                      child: Text(
                        frame['name'] as String,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? Colors.blue : Colors.black87,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundSelector() {
    final backgrounds = [
      {'name': 'Branco', 'color': Colors.white},
      {'name': 'Creme', 'color': const Color(0xFFFFFEF7)},
      {'name': 'Azul Claro', 'color': const Color(0xFFE3F2FD)},
      {'name': 'Verde Claro', 'color': const Color(0xFFE8F5E9)},
      {'name': 'Amarelo', 'color': const Color(0xFFFFF9C4)},
      {'name': 'Rosa', 'color': const Color(0xFFFCE4EC)},
      {'name': 'Cinza', 'color': const Color(0xFFF5F5F5)},
      {'name': 'Lavanda', 'color': const Color(0xFFF3E5F5)},
    ];

    return Container(
      height: MediaQuery.of(context).size.height * 0.5,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Fundo da Página',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 1,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: backgrounds.length,
              itemBuilder: (context, index) {
                final bg = backgrounds[index];
                final isSelected = _backgroundColor == bg['color'];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _backgroundColor = bg['color'] as Color;
                    });
                    Navigator.pop(context);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: bg['color'] as Color,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? Colors.blue : Colors.grey[300]!,
                        width: isSelected ? 3 : 1,
                      ),
                    ),
                    child: isSelected
                        ? const Center(
                            child: Icon(
                              Icons.check_circle,
                              color: Colors.blue,
                            ),
                          )
                        : null,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _getFrameDecoration(String frame) {
    switch (frame) {
      case 'simple':
        return BoxDecoration(
          border: Border.all(color: Colors.grey[400]!, width: 1),
        );
      case 'shadow':
        return BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        );
      case 'rounded':
        return BoxDecoration(
          border: Border.all(color: Colors.grey[400]!, width: 2),
          borderRadius: BorderRadius.circular(16),
        );
      case 'bold':
        return BoxDecoration(
          border: Border.all(color: Colors.black, width: 4),
        );
      case 'double':
        return BoxDecoration(
          border: Border.all(color: Colors.black, width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.black,
              blurRadius: 0,
              spreadRadius: -6,
            ),
          ],
        );
      case 'dashed':
        return BoxDecoration(
          border: Border.all(
            color: Colors.grey[700]!,
            width: 2,
            style: BorderStyle.solid,
          ),
        );
      case 'dotted':
        return BoxDecoration(
          border: Border.all(color: Colors.grey[700]!, width: 2),
        );
      case 'gradient':
        return BoxDecoration(
          border: Border.all(width: 4, color: Colors.transparent),
          gradient: const LinearGradient(
            colors: [Colors.purple, Colors.blue, Colors.pink],
          ),
        );
      case 'elegant':
        return BoxDecoration(
          border: Border.all(color: const Color(0xFFB8860B), width: 2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFF5F5DC).withOpacity(0.5),
              spreadRadius: 8,
            ),
          ],
        );
      case 'modern':
        return BoxDecoration(
          border: Border.all(color: Colors.grey[300]!, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        );
      case 'classic':
        return BoxDecoration(
          border: Border.all(color: const Color(0xFF8B4513), width: 12),
        );
      default:
        return const BoxDecoration();
    }
  }

  void _showFormatMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text(
              'Formatação de Texto',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildFormatButton(
                  Icons.format_bold,
                  'Negrito',
                  _isBold,
                  () => setState(() => _isBold = !_isBold),
                ),
                _buildFormatButton(
                  Icons.format_italic,
                  'Itálico',
                  _isItalic,
                  () => setState(() => _isItalic = !_isItalic),
                ),
                _buildFormatButton(
                  Icons.format_underlined,
                  'Sublinhado',
                  _isUnderline,
                  () => setState(() => _isUnderline = !_isUnderline),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildFormatButton(
                  Icons.format_align_left,
                  'Esquerda',
                  _textAlign == TextAlign.left,
                  () => setState(() => _textAlign = TextAlign.left),
                ),
                _buildFormatButton(
                  Icons.format_align_center,
                  'Centro',
                  _textAlign == TextAlign.center,
                  () => setState(() => _textAlign = TextAlign.center),
                ),
                _buildFormatButton(
                  Icons.format_align_right,
                  'Direita',
                  _textAlign == TextAlign.right,
                  () => setState(() => _textAlign = TextAlign.right),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Text('Tamanho: '),
                Expanded(
                  child: Slider(
                    value: _fontSize,
                    min: 12,
                    max: 32,
                    divisions: 20,
                    label: _fontSize.round().toString(),
                    onChanged: (value) => setState(() => _fontSize = value),
                  ),
                ),
                Text(_fontSize.round().toString()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormatButton(
    IconData icon,
    String label,
    bool isActive,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isActive ? Colors.blue : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isActive ? Colors.white : Colors.black87,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isActive ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentDoc),
        actions: [
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: _historyIndex > 0 ? _undo : null,
          ),
          IconButton(
            icon: const Icon(Icons.redo),
            onPressed: _historyIndex < _history.length - 1 ? _redo : null,
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              Share.share(_controller.text);
            },
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'new',
                child: Row(
                  children: [
                    Icon(Icons.add),
                    SizedBox(width: 8),
                    Text('Novo Documento'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.download),
                    SizedBox(width: 8),
                    Text('Exportar'),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'new') {
                setState(() {
                  _controller.clear();
                  _currentDoc = 'Documento sem título';
                });
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de ferramentas
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                ),
              ],
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  _buildToolButton(
                    Icons.text_fields,
                    'Texto',
                    _showFormatMenu,
                  ),
                  _buildToolButton(
                    Icons.palette,
                    'Fundo',
                    _showBackgroundSelector,
                  ),
                  _buildToolButton(
                    Icons.border_style,
                    'Moldura',
                    _showFrameSelector,
                  ),
                ],
              ),
            ),
          ),
          // Área de edição
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                decoration: _getFrameDecoration(_selectedFrame).copyWith(
                  color: _backgroundColor,
                ),
                padding: const EdgeInsets.all(20),
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  maxLines: null,
                  expands: true,
                  textAlign: _textAlign,
                  style: _getTextStyle(),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Comece a escrever...',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolButton(IconData icon, String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}