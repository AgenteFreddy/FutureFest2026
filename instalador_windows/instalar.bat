@echo off
chcp 65001 >nul
title Ekobelth - Instalador para Windows
cd /d "%~dp0\.."

echo =====================================================================
echo                EKOBELTH - INSTALADOR PARA WINDOWS
echo      Instalacao inteligente: detecta o que ja esta baixado!
echo =====================================================================
echo.

setlocal enabledelayedexpansion

:: -----------------------------------------------------------
:: PASSO 1: DETECÇÃO DO PYTHON
:: -----------------------------------------------------------
echo [PASSO 1/6] Verificando interpretador Python...
set PYTHON_EXE=
where python >nul 2>nul
if %errorlevel% equ 0 (
    set "PYTHON_EXE=python"
) else (
    where py >nul 2>nul
    if %errorlevel% equ 0 (
        set "PYTHON_EXE=py"
    )
)

if not defined PYTHON_EXE (
    echo.
    echo   [X ATENCAO] Python nao foi encontrado no sistema!
    echo   Deseja tentar instalar o Python 3.12 agora via winget? (S/N)
    set /p INST_PY=
    if /i "!INST_PY!"=="S" (
        echo   Instalando Python 3.12 via winget...
        winget install Python.Python.3.12 --silent
        echo   Python instalado. Por favor, reinicie este instalador.
        pause
        exit /b 0
    ) else (
        echo   Baixe o Python em: https://www.python.org/downloads/
        echo   IMPORTANTE: Marque a opcao "Add python.exe to PATH" durante a instalacao.
        pause
        exit /b 1
    )
) else (
    for /f "tokens=*" %%v in ('%PYTHON_EXE% --version 2^>^&1') do set "PY_VER=%%v"
    echo   [JA BAIXADO / INSTALADO] %PYTHON_EXE% detectado (!PY_VER!).
)

echo.
:: -----------------------------------------------------------
:: PASSO 2: AMBIENTE VIRTUAL E PACOTES PYTHON
:: -----------------------------------------------------------
echo [PASSO 2/6] Configurando ambiente virtual Python e pacotes...
set "VENV_DIR=ekobelth\.venv"

if exist "%VENV_DIR%\Scripts\python.exe" (
    echo   [JA BAIXADO / INSTALADO] Ambiente virtual (%VENV_DIR%) ja existe.
) else (
    echo   [CRIANDO] Criando ambiente virtual em %VENV_DIR%...
    %PYTHON_EXE% -m venv "%VENV_DIR%"
    if %errorlevel% neq 0 (
        echo   [ERRO] Falha ao criar o ambiente virtual.
        pause
        exit /b 1
    )
    echo   Ambiente virtual criado com sucesso!
)

set "VENV_PY=%VENV_DIR%\Scripts\python.exe"
set "VENV_PIP=%VENV_DIR%\Scripts\pip.exe"

echo   Verificando se os pacotes Python essenciais ja estao presentes...
"%VENV_PY%" -c "import fastapi, uvicorn, pymysql, aiomysql, cryptography, websockets, dotenv, httpx, pydantic; print('OK')" >nul 2>nul
if %errorlevel% equ 0 (
    echo   [JA BAIXADO / INSTALADO] Todos os pacotes Python necessarios ja estao instalados!
) else (
    echo   [INSTALANDO] Instalando pacotes do backend a partir dos arquivos locais (.whl)...
    if exist "instalador_windows\pacotes\python_wheels" (
        "%VENV_PIP%" install --no-index --find-links=instalador_windows\pacotes\python_wheels -r instalador_windows\pacotes\requirements.txt
    ) else (
        "%VENV_PIP%" install -r instalador_windows\pacotes\requirements.txt
    )
    if %errorlevel% neq 0 (
        echo   [AVISO] Tentando instalar com acesso a internet caso alguma roda falte...
        "%VENV_PIP%" install -r instalador_windows\pacotes\requirements.txt
    )
    echo   Pacotes Python instalados com sucesso!
)

echo.
:: -----------------------------------------------------------
:: PASSO 3: ARQUIVO DE CONFIGURAÇÃO (.env)
:: -----------------------------------------------------------
echo [PASSO 3/6] Verificando configuracao do ambiente (.env)...
if exist "ekobelth\.env" (
    echo   [JA BAIXADO / CONFIGURADO] Arquivo ekobelth\.env já existente.
) else (
    echo   [CONFIGURANDO] Criando ekobelth\.env a partir do modelo...
    copy "instalador_windows\pacotes\.env.template" "ekobelth\.env" >nul
    echo   Arquivo ekobelth\.env criado! Voce podera ajustar a senha do MySQL se necessario.
)

echo.
:: -----------------------------------------------------------
:: PASSO 4: DEPENDÊNCIAS DO FLUTTER
:: -----------------------------------------------------------
echo [PASSO 4/6] Verificando Flutter e dependencias do App...
where flutter >nul 2>nul
if %errorlevel% equ 0 (
    for /f "tokens=1,2,*" %%a in ('flutter --version 2^>^&1 ^| findstr "Flutter"') do set "FL_VER=%%a %%b"
    echo   [JA BAIXADO / INSTALADO] Flutter detectado (!FL_VER!).

    if exist "ekobelth\.dart_tool\package_config.json" (
        echo   [JA BAIXADO / INSTALADO] Dependencias Dart/Flutter ja estao resolvidas (.dart_tool ok).
    ) else (
        echo   [BAIXANDO] Executando flutter pub get em ekobelth...
        cd ekobelth
        call flutter pub get
        cd ..
    )
) else (
    echo   [AVISO] Flutter SDK nao encontrado no PATH do Windows.
    echo   Se voce ja baixou o Flutter, adicione a pasta 'bin' dele nas Variaveis de Ambiente do Windows.
    echo   Se ainda nao baixou, baixe em: https://docs.flutter.dev/get-started/install/windows
)

echo.
:: -----------------------------------------------------------
:: PASSO 5: NODE.JS & SITE SHOWCASE (OPCIONAL)
:: -----------------------------------------------------------
echo [PASSO 5/6] Verificando Node.js e modulos do site showcase...
where node >nul 2>nul
if %errorlevel% equ 0 (
    for /f "tokens=*" %%v in ('node --version 2^>^&1') do set "ND_VER=%%v"
    echo   [JA BAIXADO / INSTALADO] Node.js detectado (!ND_VER!).

    if exist "ekobelth_site\node_modules" (
        echo   [JA BAIXADO / INSTALADO] node_modules do site showcase ja estao prontos!
    ) else (
        echo   [INSTALANDO] Executando npm install em ekobelth_site...
        cd ekobelth_site
        call npm install
        cd ..
    )
) else (
    echo   [INFO] Node.js nao detectado. O site showcase e opcional e nao afeta o App principal.
)

echo.
:: -----------------------------------------------------------
:: PASSO 6: BANCO DE DADOS MYSQL
:: -----------------------------------------------------------
echo [PASSO 6/6] Banco de Dados MySQL:
echo   Deseja testar a conexao e criar as tabelas agora? (S/N)
set /p TEST_DB=
if /i "!TEST_DB!"=="S" (
    "%VENV_PY%" instalador_windows\pacotes\init_db.py
) else (
    echo   Voce pode rodar 'configurar_banco.bat' a qualquer momento mais tarde.
)

echo.
echo =====================================================================
echo                INSTALAÇÃO E VERIFICAÇÃO CONCLUÍDAS!
echo =====================================================================
echo Tudo pronto para usar o Ekobelth no Windows.
echo Para abrir o sistema, execute:
echo   -> instalador_windows\iniciar.bat
echo =====================================================================
echo.
pause
