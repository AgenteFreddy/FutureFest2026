#!/bin/bash

echo "A descarregar o Flutter..."
git clone https://github.com/flutter/flutter.git -b stable

echo "A configurar o PATH..."
export PATH="$PATH:`pwd`/flutter/bin"

echo "A instalar dependências e a compilar o Flutter Web..."
flutter pub get
flutter build web --release
