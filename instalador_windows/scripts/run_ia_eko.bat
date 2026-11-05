@echo off
chcp 65001 >nul
title Ekobelth - IA Eko API (Porta 8001)
cd /d "%~dp0\..\.."

echo ========================================================
echo   EKOBELTH - INICIANDO IA EKO (FastAPI - Porta 8001)
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
echo Certifique-se de que o Ollama esta rodando caso use o modelo local (ollama serve).
echo.
cd ekobelth
"%PYTHON_CMD%" -m backend.ia_eko_api
if %errorlevel% neq 0 (
    echo.
    echo [ERRO] A IA Eko encerrou com erro (%errorlevel%).
    pause
)
