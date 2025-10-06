# AuthSystem iOS - Flutter App

Sistema de autenticação completo com design iOS usando Flutter, com verificação 2FA e integração com API JSON online.

## 📱 Características

- ✅ **Design iOS Dark Theme** - Interface moderna com estilo Cupertino
- ✅ **Autenticação 2FA** - Verificação em duas etapas com código
- ✅ **Bloqueio Automático** - Conta bloqueada por 24h após 3 tentativas falhadas
- ✅ **API Online** - Busca usuários de múltiplos arquivos JSON (users.json até users20.json)
- ✅ **Cache Inteligente** - Armazenamento local seguro dos dados
- ✅ **4 Tabs Principais** - Início, Plataformas, Stories e Dashboard
- ✅ **Informações Detalhadas** - Tela protegida com senha/User Key
- ✅ **Countdown em Tempo Real** - Contador de tempo até expiração da conta
- ✅ **Último Login Dinâmico** - Atualizado automaticamente ao fazer login

## 🏗️ Estrutura do Projeto

```
lib/
├── main.dart                      # Aplicação principal
├── models/
│   └── user_model.dart           # Modelo de dados do usuário
├── services/
│   ├── auth_service.dart         # Serviço de autenticação
│   └── storage_service.dart      # Serviço de armazenamento local
├── screens/
│   ├── login_screen.dart         # Tela de login
│   ├── main_screen.dart          # Tela principal com tabs
│   ├── user_info_screen.dart     # Informações do usuário
│   └── tabs/
│       ├── home_tab.dart         # Tab Início
│       ├── platforms_tab.dart    # Tab Plataformas
│       ├── stories_tab.dart      # Tab Stories
│       └── dashboard_tab.dart    # Tab Dashboard
└── widgets/
    ├── custom_button.dart        # Botão customizado
    └── custom_text_field.dart    # Campo de texto customizado
```

## 🚀 Instalação

### 1. Pré-requisitos

- Flutter SDK 3.0.0 ou superior
- Dart SDK 3.0.0 ou superior
- Android Studio / VS Code
- Dispositivo Android/iOS ou Emulador

### 2. Clonar o Projeto

```bash
git clone https://github.com/seu-usuario/auth-system-ios.git
cd auth-system-ios
```

### 3. Instalar Dependências

```bash
flutter pub get
```

### 4. Configurar API

O app busca usuários de:
- `https://alfredoooh.github.io/database/assets/users.json`
- `https://alfredoooh.github.io/database/assets/users1.json`
- ...até...
- `https://alfredoooh.github.io/database/assets/users20.json`

**Importante:** Faça upload dos arquivos JSON no seu repositório GitHub:

1. Crie um repositório `database`
2. Crie a pasta `assets/`
3. Faça upload do `users.json` (e opcionalmente users1.json até users20.json)
4. Ative GitHub Pages nas configurações do repositório
5. Atualize a URL em `lib/services/auth_service.dart`:

```dart
static const String baseUrl = 'https://SEU-USUARIO.github.io/database/assets';
```

### 5. Executar o App

```bash
flutter run
```

## 📋 Formato do JSON

Cada arquivo JSON deve seguir este formato:

```json
{
  "users": [
    {
      "id": "usr_001",
      "username": "admin",
      "email": "admin@example.com",
      "password": "admin123",
      "full_name": "Administrador Sistema",
      "birth_date": "1990-05-15",
      "phone": "+351 912 345 678",
      "access": true,
      "expiration_date": "2025-12-31T23:59:59",
      "two_factor_auth": true,
      "two_factor_code": "123456",
      "user_key": "ADM-2024-XYZ789",
      "notification_message": "Bem-vindo ao sistema!",
      "created_at": "2024-01-15T10:30:00",
      "profile_image": "",
      "role": "administrator",
      "blocked": false,
      "failed_attempts": 0,
      "blocked_until": null
    }
  ],
  "system_settings": {
    "app_name": "AuthSystem iOS",
    "version": "1.0.0",
    "maintenance_mode": false,
    "max_login_attempts": 3,
    "session_timeout": 3600,
    "require_password_change": false
  }
}
```

## 🔐 Funcionalidades de Segurança

### Bloqueio Automático

- Após **3 tentativas falhadas**, a conta é bloqueada por **24 horas**
- Contador de tentativas é resetado após login bem-sucedido
- Bloqueio é armazenado localmente e sincronizado com a API

### Verificação 2FA

- Se `two_factor_auth: true`, o código é solicitado após login
- O código está definido no campo `two_factor_code` no JSON
- Tentativas falhadas também contam para o bloqueio

### Validação de Sessão

- Sessão válida por **24 horas**
- Verificação automática ao abrir o app
- Logout automático se a conta for desativada ou expirar

## 🎨 Design

O app segue o **iOS Human Interface Guidelines**:

- Paleta de cores escura (Dark Mode)
- Ícones Cupertino
- Animações suaves e naturais
- Feedback háptico
- Espaçamento e tipografia consistentes

### Cores Principais

- **Primary Blue**: `#007AFF`
- **Success Green**: `#34C759`
- **Warning Orange**: `#FF9500`
- **Error Red**: `#FF3B30`
- **Background**: `#1A1A1A`
- **Surface**: `#2C2C2E`

## 📱 Telas

### 1. Login Screen
- Campo de email e senha
- Validação em tempo real
- Verificação 2FA (se ativada)
- Mensagens de erro amigáveis

### 2. Main Screen (4 Tabs)
- **Início**: Visão geral da conta, estatísticas, ações rápidas
- **Plataformas**: Em desenvolvimento (Hello World)
- **Stories**: Em desenvolvimento (Hello World)
- **Dashboard**: Em desenvolvimento (Hello World)

### 3. User Info Screen
- Acesso protegido (senha ou User Key)
- Informações completas do usuário
- Countdown em tempo real
- Notificações personalizadas

## 🔄 Fluxo de Autenticação

1. **Usuário insere email e senha**
2. **App busca em todos os 20 arquivos JSON**
3. **Verifica credenciais**
4. **Se 2FA ativo → solicita código**
5. **Se código correto → login bem-sucedido**
6. **Atualiza último login e salva sessão**

## 🛠️ Dependências

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.6
  http: ^1.1.0                      # Requisições HTTP
  shared_preferences: ^2.2.2        # Armazenamento local
  flutter_secure_storage: ^9.0.0    # Armazenamento seguro
  intl: ^0.18.1                     # Formatação de datas
  flutter_spinkit: ^5.2.0           # Indicadores de carregamento
  connectivity_plus: ^4.0.2         # Verificação de conectividade
  email_validator: ^2.1.17          # Validação de email
  crypto: ^3.0.3                    # Criptografia
```

## 📝 Usuários de