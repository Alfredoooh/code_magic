import 'package:flutter/material.dart';
import 'styles.dart';

class SettingsScreen extends StatefulWidget {
  final String token;
  
  const SettingsScreen({Key? key, required this.token}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _language = 'pt';
  bool _darkMode = true;
  bool _notifications = true;
  bool _soundEffects = true;
  bool _vibration = true;
  bool _autoTrade = false;
  int _autoTradeInterval = 60;
  bool _followPatterns = false;
  String _patternType = 'red_candle';
  
  final Map<String, String> _languages = {
    'pt': 'Português',
    'en': 'English',
    'es': 'Español',
    'fr': 'Français',
  };

  final Map<String, String> _patterns = {
    'red_candle': 'Candlestick Vermelho',
    'green_candle': 'Candlestick Verde',
    'doji': 'Padrão Doji',
    'hammer': 'Padrão Hammer',
    'engulfing': 'Padrão Engulfing',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyles.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppStyles.bgSecondary,
        title: const Text('Configurações'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Seção Geral
          _buildSectionTitle('Geral'),
          _buildSettingCard(
            children: [
              _buildDropdownSetting(
                'Idioma',
                _language,
                _languages,
                (value) => setState(() => _language = value!),
              ),
              const Divider(color: AppStyles.border, height: 1),
              _buildSwitchSetting(
                'Modo Escuro',
                _darkMode,
                (value) => setState(() => _darkMode = value),
              ),
              const Divider(color: AppStyles.border, height: 1),
              _buildSwitchSetting(
                'Notificações',
                _notifications,
                (value) => setState(() => _notifications = value),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Seção Som e Vibração
          _buildSectionTitle('Som e Vibração'),
          _buildSettingCard(
            children: [
              _buildSwitchSetting(
                'Efeitos Sonoros',
                _soundEffects,
                (value) => setState(() => _soundEffects = value),
              ),
              const Divider(color: AppStyles.border, height: 1),
              _buildSwitchSetting(
                'Vibração',
                _vibration,
                (value) => setState(() => _vibration = value),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Seção Automação
          _buildSectionTitle('Automação de Trading'),
          _buildSettingCard(
            children: [
              _buildSwitchSetting(
                'Ativar Trading Automático',
                _autoTrade,
                (value) => setState(() => _autoTrade = value),
              ),
              if (_autoTrade) ...[
                const Divider(color: AppStyles.border, height: 1),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Intervalo de Operação',
                            style: TextStyle(
                              color: AppStyles.textPrimary,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            '$_autoTradeInterval seg',
                            style: const TextStyle(
                              color: AppStyles.iosBlue,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Slider(
                        value: _autoTradeInterval.toDouble(),
                        min: 10,
                        max: 300,
                        divisions: 29,
                        activeColor: AppStyles.iosBlue,
                        inactiveColor: AppStyles.border,
                        onChanged: (value) {
                          setState(() => _autoTradeInterval = value.toInt());
                        },
                      ),
                      Text(
                        'O bot operará automaticamente a cada $_autoTradeInterval segundos',
                        style: const TextStyle(
                          color: AppStyles.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(color: AppStyles.border, height: 1),
                _buildSwitchSetting(
                  'Seguir Padrões',
                  _followPatterns,
                  (value) => setState(() => _followPatterns = value),
                ),
                if (_followPatterns) ...[
                  const Divider(color: AppStyles.border, height: 1),
                  _buildDropdownSetting(
                    'Tipo de Padrão',
                    _patternType,
                    _patterns,
                    (value) => setState(() => _patternType = value!),
                  ),
                ],
              ],
            ],
          ),

          const SizedBox(height: 24),

          // Seção Conexão
          _buildSectionTitle('Conexão'),
          _buildSettingCard(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.vpn_key_rounded,
                          color: AppStyles.textSecondary,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Token de API',
                                style: TextStyle(
                                  color: AppStyles.textPrimary,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${widget.token.substring(0, 20)}...',
                                style: const TextStyle(
                                  color: AppStyles.textSecondary,
                                  fontSize: 12,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Row(
                      children: [
                        Icon(
                          Icons.lock_rounded,
                          color: AppStyles.textSecondary,
                          size: 20,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Conexão Segura',
                                style: TextStyle(
                                  color: AppStyles.textPrimary,
                                  fontSize: 15,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'WebSocket SSL/TLS',
                                style: TextStyle(
                                  color: AppStyles.green,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Seção Avançado
          _buildSectionTitle('Avançado'),
          _buildSettingCard(
            children: [
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppStyles.red),
                title: const Text(
                  'Limpar Cache',
                  style: TextStyle(color: AppStyles.textPrimary),
                ),
                trailing: const Icon(Icons.chevron_right, color: AppStyles.textSecondary),
                onTap: () {
                  _showConfirmDialog(
                    'Limpar Cache',
                    'Deseja limpar todo o cache do aplicativo?',
                    () {
                      AppStyles.showSnackBar(context, 'Cache limpo com sucesso');
                    },
                  );
                },
              ),
              const Divider(color: AppStyles.border, height: 1),
              ListTile(
                leading: const Icon(Icons.refresh, color: AppStyles.iosBlue),
                title: const Text(
                  'Restaurar Padrões',
                  style: TextStyle(color: AppStyles.textPrimary),
                ),
                trailing: const Icon(Icons.chevron_right, color: AppStyles.textSecondary),
                onTap: () {
                  _showConfirmDialog(
                    'Restaurar Padrões',
                    'Deseja restaurar todas as configurações para os valores padrão?',
                    () {
                      setState(() {
                        _language = 'pt';
                        _darkMode = true;
                        _notifications = true;
                        _soundEffects = true;
                        _vibration = true;
                        _autoTrade = false;
                        _followPatterns = false;
                      });
                      AppStyles.showSnackBar(context, 'Configurações restauradas');
                    },
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Botão Salvar
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                AppStyles.showSnackBar(context, 'Configurações salvas com sucesso');
                Navigator.pop(context);
              },
              child: const Text(
                'Salvar Configurações',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: AppStyles.textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSettingCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: AppStyles.bgSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppStyles.border, width: 0.5),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSwitchSetting(
    String title,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return SwitchListTile(
      title: Text(
        title,
        style: const TextStyle(
          color: AppStyles.textPrimary,
          fontSize: 15,
        ),
      ),
      value: value,
      onChanged: onChanged,
      activeColor: AppStyles.iosBlue,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  Widget _buildDropdownSetting(
    String title,
    String value,
    Map<String, String> items,
    ValueChanged<String?> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppStyles.textPrimary,
              fontSize: 15,
            ),
          ),
          DropdownButton<String>(
            value: value,
            onChanged: onChanged,
            dropdownColor: AppStyles.bgPrimary,
            underline: const SizedBox(),
            style: const TextStyle(
              color: AppStyles.iosBlue,
              fontSize: 15,
            ),
            items: items.entries.map((e) {
              return DropdownMenuItem(
                value: e.key,
                child: Text(e.value),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  void _showConfirmDialog(String title, String message, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppStyles.bgSecondary,
        title: Text(
          title,
          style: const TextStyle(color: AppStyles.textPrimary),
        ),
        content: Text(
          message,
          style: const TextStyle(color: AppStyles.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }
}