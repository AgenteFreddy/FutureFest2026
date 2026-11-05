@echo off
chcp 65001 >nul
title Ekobelth - Configurar Banco de Dados MySQL
cd /d "%~dp0\.."

echo ========================================================
echo   EKOBELTH - CONFIGURADOR DE BANCO DE DADOS (MySQL)
echo ========================================================
echo.

set PYTHON_CMD=
if exist "ekobelth\.venv\Scripts\python.exe" (
    set "PYTHON_CMD=ekobelth\.venv\Scripts\python.exe"
) else if exist "venv\Scripts\python.exe" (
    set "PYTHON_CMD=venv\Scripts\python.exe"
) else (
    set "PYTHON_CMD=python"
)

echo Executando script de conexao e criacao de tabelas...
echo.
"%PYTHON_CMD%" instalador_windows\pacotes\init_db.py
echo.
pause
