@echo off
chcp 65001 >nul
title Ekobelth - Backend FastAPI (Porta 8000)
cd /d "%~dp0\..\.."

echo ========================================================
echo   EKOBELTH - INICIANDO BACKEND (FastAPI - Porta 8000)
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

echo Usando Python: %PYTHON_CMD%
cd ekobelth
"%PYTHON_CMD%" -m backend.main_api
if %errorlevel% neq 0 (
    echo.
    echo [ERRO] O backend encerrou com erro (%errorlevel%).
    echo Verifique se o MySQL esta rodando e as dependencias estao instaladas.
    pause
)
