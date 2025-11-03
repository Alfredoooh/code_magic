# 📱 Cashnet Flutter Web App - Guia Completo

## 📁 Estrutura de Pastas

```
cashnet/
├── lib/
│   ├── main.dart
│   ├── firebase_options.dart
│   │
│   ├── providers/
│   │   ├── auth_provider.dart
│   │   └── theme_provider.dart
│   │
│   ├── screens/
│   │   ├── splash_screen.dart
│   │   ├── login_screen.dart
│   │   ├── signup_screen.dart
│   │   ├── phone_auth_screen.dart
│   │   ├── home_screen.dart
│   │   ├── settings_screen.dart
│   │   ├── notifications_screen.dart
│   │   ├── messages_screen.dart
│   │   └── search_screen.dart
│   │
│   └── widgets/
│       ├── custom_button.dart
│       └── custom_text_field.dart
│
├── web/
│   ├── index.html
│   ├── manifest.json
│   └── favicon.png
│
├── pubspec.yaml
└── README.md
```

## 🚀 Comandos para Deploy no Render

### 1️⃣ Root Directory
```
.
```
(deixe vazio ou ponto, pois Flutter está na raiz)

### 2️⃣ Build Command
```bash
git clone https://github.com/flutter/flutter.git -b stable --depth 1 && export PATH="$PATH:`pwd`/flutter/bin" && flutter doctor && flutter pub get && flutter build web --release --web-renderer html
```

### 3️⃣ Publish Directory
```
build/web
```

## 📦 Dependências (pubspec.yaml)

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # Firebase
  firebase_core: ^2.24.2
  firebase_auth: ^4.16.0
  cloud_firestore: ^4.14.0
  firebase_database: ^10.4.0
  firebase_storage: ^11.6.0
  
  # State Management
  provider: ^6.1.1
  
  # UI
  cupertino_icons: ^1.0.6
  google_fonts: ^6.1.0
  flutter_svg: ^2.0.9
  
  # Utils
  intl: ^0.18.1
  shared_preferences: ^2.2.2
  http: ^1.1.2
```

## 🎨 Características do App

### ✅ Autenticação
- Login com Email/Senha
- Cadastro com Email/Senha  
- Autenticação com Telefone (estrutura pronta)
- Logout

### ✅ Temas
- Modo Claro
- Modo Escuro
- Persistência de preferências

### ✅ Navegação
- Sistema de rotas nomeadas
- Drawer lateral
- Bottom Navigation (estrutura pronta)
- AppBar customizado

### ✅ Screens Implementadas
- ✅ Splash Screen (animado)
- ✅ Login Screen (completo)
- ✅ SignUp Screen (completo)
- ✅ Home Screen (básico)
- ✅ Settings Screen (completo)
- 🔨 Phone Auth (estrutura)
- 🔨 Notifications (estrutura)
- 🔨 Messages (estrutura)
- 🔨 Search (estrutura)

## 🎨 Design System

### Cores Principais
```dart
Primary: Color(0xFFFDB52A)  // Amarelo dourado
Secondary: Color(0xFFFFD700) // Dourado claro
Dark Background: Color(0xFF1A1A1A)
Dark Surface: Color(0xFF242526)
Light Background: Color(0xFFF5F5F5)
```

### Componentes Customizados
- **CustomButton**: Botão com gradiente e animação de scale
- **CustomTextField**: Campo de texto Material Design com suporte dark mode

## 🔥 Configuração Firebase

O app já está configurado com suas credenciais Firebase:
- Project ID: `chat00-7f1b1`
- Auth, Firestore, Realtime Database e Storage habilitados

## 📱 Features Nativas Flutter

### Animações
- Scale animation nos botões
- Float animation no logo (splash)
- Fade transitions entre telas
- Smooth theme transitions

### Responsividade
- Layout adaptativo mobile-first
- Suporte para tablets e desktop web
- Safe areas respeitadas

### Performance
- Lazy loading de telas
- Provider para state management eficiente
- Otimização de rebuilds

## 🛠️ Próximos Passos para Expandir

### 1. Phone Authentication
Implementar em `phone_auth_screen.dart`:
```dart
import 'package:firebase_auth/firebase_auth.dart';

final auth = FirebaseAuth.instance;
await auth.verifyPhoneNumber(
  phoneNumber: phoneNumber,
  verificationCompleted: (credential) {},
  verificationFailed: (error) {},
  codeSent: (verificationId, resendToken) {},
  codeAutoRetrievalTimeout: (verificationId) {},
);
```

### 2. Bills/Transactions
Criar `models/bill.dart` e telas para:
- Criar nova conta
- Listar contas
- Detalhes da conta
- Dividir entre usuários

### 3. Notificações
Implementar em `notifications_screen.dart`:
- Stream do Firestore
- Lista de notificações
- Marcar como lido

### 4. Chat/Messages
Implementar em `messages_screen.dart`:
- Lista de conversas
- Tela de chat individual
- Real-time com Firestore

### 5. Search
Implementar busca de usuários:
- Algolia ou busca no Firestore
- Lista de resultados
- Adicionar amigos

## 🎯 Comandos Úteis

### Desenvolvimento Local
```bash
# Instalar dependências
flutter pub get

# Rodar em modo web
flutter run -d chrome

# Build para produção
flutter build web --release
```

### Verificar Erros
```bash
flutter doctor
flutter analyze
```

### Limpar Cache
```bash
flutter clean
flutter pub get
```

## 📝 Notas Importantes

1. **Firebase Web Config**: Já está configurado no `firebase_options.dart`
2. **Web Renderer**: Usando `--web-renderer html` para melhor compatibilidade
3. **State Management**: Provider para simplicidade e performance
4. **Responsive**: Layout funciona em mobile, tablet e desktop
5. **PWA Ready**: Configurado para funcionar como Progressive Web App

## 🐛 Troubleshooting

### Erro no Build
```bash
flutter clean
flutter pub get
flutter build web --release
```

### Erro Firebase
Verificar se as credenciais em `firebase_options.dart` estão corretas

### Erro de Rotas
Verificar se todas as rotas estão definidas no `main.dart`

---

**🎉 App pronto para deploy no Render!**

Basta seguir as configurações de Build Command e Publish Directory acima.