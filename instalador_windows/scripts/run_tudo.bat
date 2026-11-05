@echo off
chcp 65001 >nul
title Ekobelth - Inicializador Completo
cd /d "%~dp0"

echo ========================================================
echo   EKOBELTH - INICIANDO TODOS OS SERVIÇOS
echo ========================================================
echo.
echo 1. Abrindo Backend Principal (Porta 8000)...
start "Ekobelth - Backend FastAPI (8000)" cmd /c run_backend.bat

timeout /t 2 >nul

echo 2. Abrindo Servico IA Eko (Porta 8001)...
start "Ekobelth - IA Eko API (8001)" cmd /c run_ia_eko.bat

timeout /t 2 >nul

echo 3. Abrindo App Flutter Web (Edge)...
start "Ekobelth - App Flutter" cmd /c run_flutter_web.bat

echo.
echo Todos os serviços foram disparados em janelas separadas!
echo Para encerrar, basta fechar as janelas abertas.
echo ========================================================
pause
