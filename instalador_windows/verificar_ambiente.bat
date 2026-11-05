@echo off
chcp 65001 >nul
title Ekobelth - Verificador de Ambiente e Pacotes Baixados
cd /d "%~dp0\.."

echo =====================================================================
echo           EKOBELTH - DIAGNÓSTICO DO AMBIENTE WINDOWS
echo       Identificando o que já está baixado e o que está ausente
echo =====================================================================
echo.

setlocal enabledelayedexpansion

:: 1. PYTHON
echo [1] VERIFICANDO PYTHON E AMBIENTE VIRTUAL:
set PYTHON_ENCONTRADO=0
where python >nul 2>nul
if %errorlevel% equ 0 (
    for /f "tokens=*" %%v in ('python --version 2^>^&1') do set "PY_VER=%%v"
    echo   [JA BAIXADO / INSTALADO] Python no PATH: !PY_VER!
    set PYTHON_ENCONTRADO=1
) else (
    where py >nul 2>nul
    if %errorlevel% equ 0 (
        for /f "tokens=*" %%v in ('py --version 2^>^&1') do set "PY_VER=%%v"
        echo   [JA BAIXADO / INSTALADO] Python Launcher (py): !PY_VER!
        set PYTHON_ENCONTRADO=1
    ) else (
        echo   [X AUSENTE] Python nao foi encontrado no PATH do Windows.
    )
)

if exist "ekobelth\.venv\Scripts\python.exe" (
    echo   [JA BAIXADO / INSTALADO] Ambiente Virtual: ekobelth\.venv (Detectado)
    set "VENV_PY=ekobelth\.venv\Scripts\python.exe"
) else if exist "venv\Scripts\python.exe" (
    echo   [JA BAIXADO / INSTALADO] Ambiente Virtual: venv (Detectado na raiz)
    set "VENV_PY=venv\Scripts\python.exe"
) else (
    echo   [X AUSENTE] Nenhum ambiente virtual (.venv) criado ainda.
    set "VENV_PY="
)

if defined VENV_PY (
    echo   -> Verificando pacotes dentro da .venv...
    "%VENV_PY%" -c "import fastapi, uvicorn, pymysql, aiomysql, cryptography, websockets, dotenv, httpx, pydantic; print('OK')" >nul 2>nul
    if !errorlevel! equ 0 (
        echo   [JA BAIXADO / INSTALADO] Todos os pacotes Python do backend estao prontos!
    ) else (
        echo   [AVISO] Alguns pacotes Python estao pendentes na .venv.
    )
)

echo.
:: 2. PACOTES OFFLINE FORNECIDOS
echo [2] PACOTES EMBUTIDOS NO INSTALADOR (Offline):
if exist "instalador_windows\pacotes\python_wheels" (
    set WHEEL_COUNT=0
    for %%f in ("instalador_windows\pacotes\python_wheels\*.whl") do set /a WHEEL_COUNT+=1
    echo   [JA BAIXADO] Rodas Python (.whl) locais: !WHEEL_COUNT! arquivos prontos para instalacao offline!
) else (
    echo   [AVISO] Pasta de rodas offline nao encontrada.
)

echo.
:: 3. FLUTTER SDK E DEPENDÊNCIAS
echo [3] VERIFICANDO FLUTTER SDK E PACOTES DART:
where flutter >nul 2>nul
if %errorlevel% equ 0 (
    for /f "tokens=1,2,*" %%a in ('flutter --version 2^>^&1 ^| findstr "Flutter"') do set "FLUTTER_VER=%%a %%b"
    echo   [JA BAIXADO / INSTALADO] Flutter SDK: !FLUTTER_VER!
) else (
    echo   [X AUSENTE] Flutter SDK nao encontrado no PATH.
)

if exist "ekobelth\.dart_tool\package_config.json" (
    echo   [JA BAIXADO / INSTALADO] Cache de dependencias Flutter (.dart_tool pronto)
) else (
    echo   [PENDENTE] Dependencias do Flutter precisam de 'flutter pub get'.
)

echo.
:: 4. NODE.JS E PACOTES DO SITE
echo [4] VERIFICANDO NODE.JS E SITE SHOWCASE:
where node >nul 2>nul
if %errorlevel% equ 0 (
    for /f "tokens=*" %%v in ('node --version 2^>^&1') do set "NODE_VER=%%v"
    echo   [JA BAIXADO / INSTALADO] Node.js: !NODE_VER!
) else (
    echo   [X AUSENTE] Node.js nao encontrado (necessario apenas para o site showcase).
)

if exist "ekobelth_site\node_modules" (
    echo   [JA BAIXADO / INSTALADO] Modulos Node.js (ekobelth_site\node_modules detectado)
) else (
    echo   [PENDENTE] Modulos do site showcase precisam de 'npm install'.
)

echo.
:: 5. BANCO DE DADOS MYSQL
echo [5] VERIFICANDO BANCO DE DADOS:
if exist "ekobelth\.env" (
    echo   [JA CONFIGURADO] Arquivo ekobelth\.env detectado.
) else if exist ".env" (
    echo   [JA CONFIGURADO] Arquivo .env detectado na raiz.
) else (
    echo   [PENDENTE] Nenhum .env encontrado (sera criado pelo instalador).
)

where mysqladmin >nul 2>nul
if %errorlevel% equ 0 (
    echo   [JA BAIXADO / INSTALADO] Cliente MySQL CLI detectado no sistema.
) else (
    echo   [INFO] Cliente mysql no terminal nao detectado (se usa XAMPP, inicie pelo painel).
)

echo.
:: 6. IA EKO (OLLAMA - OPCIONAL)
echo [6] VERIFICANDO OLLAMA (IA LOCAL):
where ollama >nul 2>nul
if %errorlevel% equ 0 (
    echo   [JA BAIXADO / INSTALADO] Ollama detectado no sistema!
) else (
    echo   [OPCIONAL] Ollama nao encontrado (a IA requer o Ollama instalado se for usar IA local).
)

echo.
echo =====================================================================
echo Diagnóstico finalizado!
echo Execute 'instalar.bat' para baixar/configurar o que estiver faltando.
echo =====================================================================
pause
