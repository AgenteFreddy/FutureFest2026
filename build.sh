#!/bin/bash

echo "A descarregar o Flutter..."
git clone https://github.com/flutter/flutter.git -b stable

echo "A configurar o PATH..."
export PATH="$PATH:`pwd`/flutter/bin"

echo "A entrar na pasta do projeto..."
cd ekobelth

echo "A instalar dependências e a compilar o Flutter Web..."
flutter pub get
flutter build web --release

echo "A limpar o Flutter SDK para não exceder o limite do Vercel..."
cd ..
rm -rf flutter
