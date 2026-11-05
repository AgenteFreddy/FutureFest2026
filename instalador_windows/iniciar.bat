@echo off
chcp 65001 >nul
title Ekobelth - Painel de Controle (Windows)
cd /d "%~dp0"

:MENU
cls
echo =====================================================================
echo                     EKOBELTH - PAINEL DE CONTROLE
echo =====================================================================
echo.
echo   [1] Iniciar TUDO (Backend + IA Eko + App Web) [Recomendado]
echo   [2] Iniciar apenas Backend FastAPI (Porta 8000)
echo   [3] Iniciar apenas IA Eko API (Porta 8001)
echo   [4] Iniciar App Flutter no Navegador (Edge / Chrome)
echo   [5] Iniciar App Flutter Nativo (Windows Desktop)
echo   [6] Iniciar Site Showcase / Pitch (Porta 3000)
echo   [7] Testar e Inicializar Banco de Dados (MySQL)
echo   [8] Verificar Ambiente e Pacotes Baixados
echo   [9] Reinstalar / Atualizar Pacotes (instalar.bat)
echo   [0] Sair
echo.
echo =====================================================================
set /p OPCAO="Escolha uma opção (0-9): "

if "%OPCAO%"=="1" (
    call scripts\run_tudo.bat
    goto MENU
)
if "%OPCAO%"=="2" (
    start "Ekobelth - Backend FastAPI (8000)" cmd /c scripts\run_backend.bat
    goto MENU
)
if "%OPCAO%"=="3" (
    start "Ekobelth - IA Eko API (8001)" cmd /c scripts\run_ia_eko.bat
    goto MENU
)
if "%OPCAO%"=="4" (
    start "Ekobelth - Flutter Web" cmd /c scripts\run_flutter_web.bat
    goto MENU
)
if "%OPCAO%"=="5" (
    start "Ekobelth - Flutter Desktop" cmd /c scripts\run_flutter_desktop.bat
    goto MENU
)
if "%OPCAO%"=="6" (
    start "Ekobelth - Showcase Site" cmd /c scripts\run_showcase.bat
    goto MENU
)
if "%OPCAO%"=="7" (
    call configurar_banco.bat
    goto MENU
)
if "%OPCAO%"=="8" (
    call verificar_ambiente.bat
    goto MENU
)
if "%OPCAO%"=="9" (
    call instalar.bat
    goto MENU
)
if "%OPCAO%"=="0" (
    exit /b 0
)

echo Opção inválida!
timeout /t 2 >nul
goto MENU
