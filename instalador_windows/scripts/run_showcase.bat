@echo off
chcp 65001 >nul
title Ekobelth - Site Showcase / Pitch (Porta 3000)
cd /d "%~dp0\..\..\ekobelth_site"

echo ========================================================
echo   EKOBELTH - SITE SHOWCASE (Express - Porta 3000)
echo ========================================================
echo.

where node >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERRO] Node.js nao encontrado no PATH do Windows.
    pause
    exit /b 1
)

echo Iniciando servidor Node.js...
node api/index.js
if %errorlevel% neq 0 (
    echo.
    echo [ERRO] O servidor Node.js encerrou com erro (%errorlevel%).
    pause
)
