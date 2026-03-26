# TaskFlow — Gestor de Tarefas Flutter

**TaskFlow** é um aplicativo Flutter completo de gestão de tarefas com design moderno e minimalista, construído com ícones SVG do [Lucide Icons](https://lucide.dev) e suporte a dark/light mode.

## Funcionalidades

- Dashboard com progresso geral, estatísticas e tarefas do dia
- Criar, editar, excluir e concluir tarefas
- Categorias: Trabalho, Pessoal, Saúde, Finanças, Educação, Outros
- Prioridades: Alta, Média, Baixa com indicadores visuais coloridos
- Sub-tarefas com checkboxes individuais
- Prazo com seletor de data e alertas de atraso
- Filtros por categoria e prioridade
- Busca em tempo real por título
- Dark/Light Mode com persistência
- Dados guardados localmente via SharedPreferences
- Splash Screen animada
- Tarefas de demonstração pré-carregadas

## Tecnologias

- Flutter 3.27.4 (Dart 3.6.2)
- flutter_lucide 1.8.2 — ícones SVG Lucide
- provider 6.1.2 — gestão de estado
- shared_preferences 2.3.3 — persistência local
- intl 0.19.0 — formatação de datas em português

## Como Executar

```bash
cd taskflow_app
flutter pub get
flutter run
```

## Build

```bash
# Android
flutter build apk --release

# iOS
flutter build ios --release

# Web
flutter build web --release
```
 