#!/bin/bash

# Script de build para Flutter no Render
echo "🚀 Iniciando build do Flutter Web..."

# Instalar Flutter se não estiver instalado
if [ ! -d "flutter" ]; then
    echo "📦 Instalando Flutter..."
    git clone https://github.com/flutter/flutter.git -b stable --depth 1
fi

# Adicionar Flutter ao PATH
export PATH="$PATH:`pwd`/flutter/bin"

# Verificar versão do Flutter
flutter --version

# Limpar cache
echo "🧹 Limpando cache..."
flutter clean

# Baixar dependências
echo "📚 Baixando dependências..."
flutter pub get

# Build para web
echo "🔨 Compilando para web..."
flutter build web --release --web-renderer html

echo "✅ Build concluído com sucesso!"