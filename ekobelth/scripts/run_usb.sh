#!/bin/bash
echo "Configurando portas USB (adb reverse)..."

# Limpa configurações antigas
adb reverse --remove-all

# Mapeia portas (usamos 9000 e 9001 no celular para evitar conflito com a 8000 que pode estar em uso)
adb reverse tcp:9000 tcp:8000
adb reverse tcp:9001 tcp:8001

echo "Portas mapeadas com sucesso!"
echo "Iniciando o app via USB..."

cd "$(dirname "$0")/.."
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:9000 --dart-define=IA_BASE_URL=http://127.0.0.1:9001 "$@"
