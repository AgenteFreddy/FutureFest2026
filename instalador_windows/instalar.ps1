# Ekobelth - Instalador Inteligente para Windows (PowerShell)
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host "=====================================================================" -ForegroundColor Cyan
Write-Host "                EKOBELTH - INSTALADOR PARA WINDOWS" -ForegroundColor Yellow
Write-Host "      Instalação inteligente: detecta o que já está baixado!" -ForegroundColor Cyan
Write-Host "=====================================================================" -ForegroundColor Cyan
Write-Host ""

$baseDir = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $baseDir

function Print-Ok($title, $detail) {
    Write-Host "  [JA BAIXADO / INSTALADO] " -ForegroundColor Green -NoNewline
    Write-Host "$title: " -ForegroundColor White -NoNewline
    Write-Host "$detail" -ForegroundColor Gray
}

function Print-Action($title, $detail) {
    Write-Host "  [EXECUTANDO] " -ForegroundColor Yellow -NoNewline
    Write-Host "$title: " -ForegroundColor White -NoNewline
    Write-Host "$detail" -ForegroundColor DarkYellow
}

function Print-Warn($title, $detail) {
    Write-Host "  [ATENÇÃO] " -ForegroundColor Magenta -NoNewline
    Write-Host "$title: " -ForegroundColor White -NoNewline
    Write-Host "$detail" -ForegroundColor Yellow
}

# 1. PYTHON
Write-Host "[PASSO 1/6] Verificando interpretador Python..." -ForegroundColor White
$pyExe = $null
if (Get-Command python -ErrorAction SilentlyContinue) {
    $pyExe = "python"
} elseif (Get-Command py -ErrorAction SilentlyContinue) {
    $pyExe = "py"
}

if (-not $pyExe) {
    Print-Warn "Python" "Python nao encontrado no PATH do Windows."
    $resp = Read-Host "Deseja tentar instalar o Python 3.12 agora via winget? (S/N)"
    if ($resp -eq 'S' -or $resp -eq 's') {
        winget install Python.Python.3.12 --silent
        Write-Host "Python instalado. Reinicie o instalador." -ForegroundColor Green
        pause
        exit
    } else {
        Write-Host "Baixe o Python em: https://www.python.org/downloads/ (Marque 'Add python.exe to PATH')" -ForegroundColor Yellow
        pause
        exit
    }
} else {
    $pyVer = (& $pyExe --version 2>&1).ToString().Trim()
    Print-Ok "Python" "$pyExe ($pyVer)"
}

Write-Host ""
# 2. VENV & PACOTES
Write-Host "[PASSO 2/6] Configurando ambiente virtual Python e pacotes..." -ForegroundColor White
$venvDir = Join-Path $baseDir "ekobelth\.venv"
$venvPy = Join-Path $venvDir "Scripts\python.exe"
$venvPip = Join-Path $venvDir "Scripts\pip.exe"

if (Test-Path $venvPy) {
    Print-Ok "Ambiente Virtual" "ekobelth\.venv ja existe"
} else {
    Print-Action "Ambiente Virtual" "Criando .venv em ekobelth..."
    & $pyExe -m venv $venvDir
    Write-Host "  Ambiente virtual criado com sucesso!" -ForegroundColor Green
}

# Checar pacotes instalados
& $venvPy -c "import fastapi, uvicorn, pymysql, aiomysql, cryptography, websockets, dotenv, httpx, pydantic; print('OK')" 2>$null | Out-Null
if ($LASTEXITCODE -eq 0) {
    Print-Ok "Pacotes Python" "Todos os pacotes necessarios ja estao instalados na .venv!"
} else {
    Print-Action "Pacotes Python" "Instalando a partir das rodas locais (.whl) embutidas..."
    $wheelsDir = Join-Path $baseDir "instalador_windows\pacotes\python_wheels"
    $reqFile = Join-Path $baseDir "instalador_windows\pacotes\requirements.txt"

    if (Test-Path $wheelsDir) {
        & $venvPip install --no-index --find-links=$wheelsDir -r $reqFile
    } else {
        & $venvPip install -r $reqFile
    }

    if ($LASTEXITCODE -ne 0) {
        Write-Host "  Tentando baixar via internet se faltou alguma roda..." -ForegroundColor DarkYellow
        & $venvPip install -r $reqFile
    }
    Write-Host "  Pacotes Python instalados com sucesso!" -ForegroundColor Green
}

Write-Host ""
# 3. .ENV
Write-Host "[PASSO 3/6] Verificando configuracao de ambiente (.env)..." -ForegroundColor White
$envTarget = Join-Path $baseDir "ekobelth\.env"
$envTemplate = Join-Path $baseDir "instalador_windows\pacotes\.env.template"

if (Test-Path $envTarget) {
    Print-Ok "Configuracao" "ekobelth\.env ja existe"
} else {
    Print-Action "Configuracao" "Copiando .env.template para ekobelth\.env"
    Copy-Item $envTemplate $envTarget
    Write-Host "  Arquivo ekobelth\.env criado com valores padrao!" -ForegroundColor Green
}

Write-Host ""
# 4. FLUTTER
Write-Host "[PASSO 4/6] Verificando Flutter e dependencias do App..." -ForegroundColor White
if (Get-Command flutter -ErrorAction SilentlyContinue) {
    $flVer = (flutter --version 2>&1 | Select-Object -First 1).ToString().Trim()
    Print-Ok "Flutter SDK" $flVer

    $dartTool = Join-Path $baseDir "ekobelth\.dart_tool\package_config.json"
    if (Test-Path $dartTool) {
        Print-Ok "Dependencias Dart" "Cache .dart_tool detectado"
    } else {
        Print-Action "Dependencias Dart" "Executando flutter pub get..."
        Push-Location (Join-Path $baseDir "ekobelth")
        flutter pub get
        Pop-Location
    }
} else {
    Print-Warn "Flutter SDK" "Nao encontrado no PATH. Adicione a pasta 'bin' do Flutter nas Variaveis de Ambiente."
}

Write-Host ""
# 5. NODE.JS & SHOWCASE
Write-Host "[PASSO 5/6] Verificando Node.js e modulos do site showcase..." -ForegroundColor White
if (Get-Command node -ErrorAction SilentlyContinue) {
    $ndVer = (node --version).ToString().Trim()
    Print-Ok "Node.js" $ndVer

    $siteModules = Join-Path $baseDir "ekobelth_site\node_modules"
    if (Test-Path $siteModules) {
        Print-Ok "Modulos Showcase" "ekobelth_site\node_modules detectado"
    } else {
        Print-Action "Modulos Showcase" "Executando npm install..."
        Push-Location (Join-Path $baseDir "ekobelth_site")
        npm install
        Pop-Location
    }
} else {
    Write-Host "  [INFO] Node.js nao detectado (apenas o site showcase depende dele, app principal roda normalmente)." -ForegroundColor DarkGray
}

Write-Host ""
# 6. BANCO MYSQL
Write-Host "[PASSO 6/6] Banco de Dados MySQL:" -ForegroundColor White
$testDb = Read-Host "Deseja testar conexao e inicializar tabelas MySQL agora? (S/N)"
if ($testDb -eq 'S' -or $testDb -eq 's') {
    $initScript = Join-Path $baseDir "instalador_windows\pacotes\init_db.py"
    & $venvPy $initScript
} else {
    Write-Host "  Voce podera executar configurar_banco.bat a qualquer momento." -ForegroundColor DarkGray
}

Write-Host ""
Write-Host "=====================================================================" -ForegroundColor Cyan
Write-Host "                INSTALAÇÃO E VERIFICAÇÃO CONCLUÍDAS!" -ForegroundColor Green
Write-Host "=====================================================================" -ForegroundColor Cyan
Write-Host "Para iniciar os servicos, execute:" -ForegroundColor White
Write-Host "  -> instalador_windows\iniciar.bat" -ForegroundColor Yellow
Write-Host "=====================================================================" -ForegroundColor Cyan
Write-Host "Pressione qualquer tecla para finalizar..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
