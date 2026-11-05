@echo off
chcp 65001 >nul
title Ekobelth - Flutter Web (Navegador)
cd /d "%~dp0\..\..\ekobelth"

echo ========================================================
echo   EKOBELTH - INICIANDO APP FLUTTER (Web no Navegador)
echo ========================================================
echo.
echo Dica: O modo Web funciona em qualquer Windows sem precisar do Visual Studio C++!
echo.

where flutter >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERRO] O comando 'flutter' nao foi encontrado no PATH do Windows.
    echo Instale o Flutter SDK ou adicione-o as Variaveis de Ambiente.
    pause
    exit /b 1
)

echo Executando Flutter no Edge / Chrome...
flutter run -d edge --dart-define=API_BASE_URL=http://localhost:8000 --dart-define=IA_BASE_URL=http://localhost:8001
if %errorlevel% neq 0 (
    echo Tentando abrir no Chrome...
    flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8000 --dart-define=IA_BASE_URL=http://localhost:8001
)
pause
