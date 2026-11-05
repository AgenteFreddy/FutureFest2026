@echo off
chcp 65001 >nul
title Ekobelth - Flutter Windows Desktop
cd /d "%~dp0\..\..\ekobelth"

echo ========================================================
echo   EKOBELTH - INICIANDO APP FLUTTER (Nativo Windows)
echo ========================================================
echo.
echo Nota: O build nativo Windows requer 'Desktop development with C++' instalado no Visual Studio.
echo Se nao tiver o compilador C++, use o modo Web (run_flutter_web.bat).
echo.

where flutter >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERRO] O comando 'flutter' nao foi encontrado no PATH do Windows.
    pause
    exit /b 1
)

echo Iniciando no dispositivo Windows...
flutter run -d windows --dart-define=API_BASE_URL=http://localhost:8000 --dart-define=IA_BASE_URL=http://localhost:8001
if %errorlevel% neq 0 (
    echo.
    echo [AVISO] Falha ao compilar nativo Windows. 
    echo Deseja abrir no Navegador Web (Edge)? (S/N)
    set /p RESP=
    if /i "%RESP%"=="S" (
        flutter run -d edge --dart-define=API_BASE_URL=http://localhost:8000 --dart-define=IA_BASE_URL=http://localhost:8001
    )
)
pause
