// app_theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: Color(0xFFFF444F),
      scaffoldBackgroundColor: Color(0xFF0E0E0E),
      cardColor: Color(0xFF1C1C1E),
      dividerColor: Color(0xFF38383A),
      appBarTheme: AppBarTheme(
        backgroundColor: Color(0xFF1C1C1E),
        elevation: 0,
        centerTitle: true,
      ),
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: Colors.white),
        bodyMedium: TextStyle(color: Colors.white),
      ),
      iconTheme: IconThemeData(color: Colors.white),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: Color(0xFFFF444F),
      scaffoldBackgroundColor: Color(0xFFF5F5F5),
      cardColor: Colors.white,
      dividerColor: Color(0xFFE0E0E0),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.black),
        titleTextStyle: TextStyle(
          color: Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: Colors.black87),
        bodyMedium: TextStyle(color: Colors.black87),
      ),
      iconTheme: IconThemeData(color: Colors.black87),
    );
  }
}

// app_localizations.dart
class AppLocalizations {
  static Map<String, Map<String, String>> _localizedValues = {
    'pt': {
      'welcome': 'Bem-vindo',
      'home': 'Home',
      'chats': 'Chats',
      'admin': 'Admin',
      'logout': 'Sair',
      'settings': 'Configurações',
      'theme': 'Tema',
      'language': 'Idioma',
      'dark_theme': 'Tema Escuro',
      'light_theme': 'Tema Claro',
      'portuguese': 'Português',
      'english': 'English',
      'spanish': 'Español',
      'create_group': 'Criar Grupo',
      'group_name': 'Nome do Grupo',
      'description': 'Descrição',
      'send': 'Enviar',
      'message': 'Mensagem',
      'active_users': 'Usuários Ativos',
      'total_messages': 'Total de Mensagens',
      'groups_created': 'Grupos Criados',
      'tokens_remaining': 'Tokens Restantes',
      'unlimited': 'Ilimitado',
      'upgrade_to_pro': 'Upgrade para PRO',
      'pro_features': 'Tokens ilimitados, criar grupos e muito mais!',
      'free_account': 'Conta Gratuita',
      'pro_account': 'Conta PRO',
    },
    'en': {
      'welcome': 'Welcome',
      'home': 'Home',
      'chats': 'Chats',
      'admin': 'Admin',
      'logout': 'Logout',
      'settings': 'Settings',
      'theme': 'Theme',
      'language': 'Language',
      'dark_theme': 'Dark Theme',
      'light_theme': 'Light Theme',
      'portuguese': 'Português',
      'english': 'English',
      'spanish': 'Español',
      'create_group': 'Create Group',
      'group_name': 'Group Name',
      'description': 'Description',
      'send': 'Send',
      'message': 'Message',
      'active_users': 'Active Users',
      'total_messages': 'Total Messages',
      'groups_created': 'Groups Created',
      'tokens_remaining': 'Tokens Remaining',
      'unlimited': 'Unlimited',
      'upgrade_to_pro': 'Upgrade to PRO',
      'pro_features': 'Unlimited tokens, create groups and much more!',
      'free_account': 'Free Account',
      'pro_account': 'PRO Account',
    },
    'es': {
      'welcome': 'Bienvenido',
      'home': 'Inicio',
      'chats': 'Chats',
      'admin': 'Admin',
      'logout': 'Salir',
      'settings': 'Configuración',
      'theme': 'Tema',
      'language': 'Idioma',
      'dark_theme': 'Tema Oscuro',
      'light_theme': 'Tema Claro',
      'portuguese': 'Português',
      'english': 'English',
      'spanish': 'Español',
      'create_group': 'Crear Grupo',
      'group_name': 'Nombre del Grupo',
      'description': 'Descripción',
      'send': 'Enviar',
      'message': 'Mensaje',
      'active_users': 'Usuarios Activos',
      'total_messages': 'Total de Mensajes',
      'groups_created': 'Grupos Creados',
      'tokens_remaining': 'Tokens Restantes',
      'unlimited': 'Ilimitado',
      'upgrade_to_pro': 'Actualizar a PRO',
      'pro_features': '¡Tokens ilimitados, crear grupos y mucho más!',
      'free_account': 'Cuenta Gratuita',
      'pro_account': 'Cuenta PRO',
    },
  };

  static String translate(String key, String language) {
    return _localizedValues[language]?[key] ?? key;
  }
}