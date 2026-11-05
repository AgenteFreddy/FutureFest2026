# Ekobelth - Verificador de Ambiente e Pacotes Baixados (PowerShell)
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host "=====================================================================" -ForegroundColor Cyan
Write-Host "          EKOBELTH - DIAGNÓSTICO DO AMBIENTE WINDOWS" -ForegroundColor Yellow
Write-Host "      Identificando o que já está baixado e o que está ausente" -ForegroundColor Cyan
Write-Host "=====================================================================" -ForegroundColor Cyan
Write-Host ""

$baseDir = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $baseDir

function Print-Status($status, $item, $detail, $isOk) {
    if ($isOk) {
        Write-Host "  [$status] " -ForegroundColor Green -NoNewline
        Write-Host "$item: " -ForegroundColor White -NoNewline
        Write-Host "$detail" -ForegroundColor Gray
    } else {
        Write-Host "  [$status] " -ForegroundColor Red -NoNewline
        Write-Host "$item: " -ForegroundColor White -NoNewline
        Write-Host "$detail" -ForegroundColor Yellow
    }
}

# 1. PYTHON
Write-Host "[1] VERIFICANDO PYTHON E AMBIENTE VIRTUAL:" -ForegroundColor White
$pyCmd = Get-Command python -ErrorAction SilentlyContinue
if ($pyCmd) {
    $pyVer = (python --version 2>&1).ToString().Trim()
    Print-Status "JA BAIXADO / INSTALADO" "Python" $pyVer $true
} else {
    $pyLauncher = Get-Command py -ErrorAction SilentlyContinue
    if ($pyLauncher) {
        $pyVer = (py --version 2>&1).ToString().Trim()
        Print-Status "JA BAIXADO / INSTALADO" "Python Launcher" $pyVer $true
    } else {
        Print-Status "X AUSENTE" "Python" "Nenhum interpretador Python encontrado no PATH." $false
    }
}

$venvPath = Join-Path $baseDir "ekobelth\.venv\Scripts\python.exe"
$rootVenvPath = Join-Path $baseDir "venv\Scripts\python.exe"
$activeVenv = $null

if (Test-Path $venvPath) {
    Print-Status "JA BAIXADO / INSTALADO" "Ambiente Virtual" "ekobelth\.venv existente" $true
    $activeVenv = $venvPath
} elseif (Test-Path $rootVenvPath) {
    Print-Status "JA BAIXADO / INSTALADO" "Ambiente Virtual" "venv (raiz) existente" $true
    $activeVenv = $rootVenvPath
} else {
    Print-Status "X AUSENTE" "Ambiente Virtual" "Nenhuma .venv criada ainda" $false
}

if ($activeVenv) {
    Write-Host "  -> Checando pacotes essenciais dentro da .venv..." -ForegroundColor DarkGray
    & $activeVenv -c "import fastapi, uvicorn, pymysql, aiomysql, cryptography, websockets, dotenv, httpx, pydantic; print('OK')" 2>$null | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Print-Status "JA BAIXADO / INSTALADO" "Pacotes Backend" "FastAPI, PyMySQL, Cryptography, Uvicorn, etc." $true
    } else {
        Print-Status "PENDENTE" "Pacotes Backend" "Alguns pacotes faltam na .venv" $false
    }
}

Write-Host ""
# 2. PACOTES OFFLINE
Write-Host "[2] PACOTES EMBUTIDOS NO INSTALADOR (Offline):" -ForegroundColor White
$wheelsDir = Join-Path $baseDir "instalador_windows\pacotes\python_wheels"
if (Test-Path $wheelsDir) {
    $wheelFiles = Get-ChildItem -Path $wheelsDir -Filter "*.whl"
    Print-Status "JA BAIXADO" "Rodas (.whl) locais" "$($wheelFiles.Count) pacotes prontos para instalacao offline" $true
} else {
    Print-Status "AVISO" "Rodas offline" "Diretorio de rodas nao localizado" $false
}

Write-Host ""
# 3. FLUTTER SDK
Write-Host "[3] VERIFICANDO FLUTTER SDK E PACOTES DART:" -ForegroundColor White
$flutterCmd = Get-Command flutter -ErrorAction SilentlyContinue
if ($flutterCmd) {
    $flutterVer = (flutter --version 2>&1 | Select-Object -First 1).ToString().Trim()
    Print-Status "JA BAIXADO / INSTALADO" "Flutter SDK" $flutterVer $true
} else {
    Print-Status "X AUSENTE" "Flutter SDK" "Flutter nao encontrado no PATH" $false
}

$dartTool = Join-Path $baseDir "ekobelth\.dart_tool\package_config.json"
if (Test-Path $dartTool) {
    Print-Status "JA BAIXADO / INSTALADO" "Dependencias Dart/Flutter" "Cache local (.dart_tool) configurado" $true
} else {
    Print-Status "PENDENTE" "Dependencias Dart/Flutter" "Requer 'flutter pub get'" $false
}

Write-Host ""
# 4. NODE.JS & SITE SHOWCASE
Write-Host "[4] VERIFICANDO NODE.JS E SITE SHOWCASE:" -ForegroundColor White
$nodeCmd = Get-Command node -ErrorAction SilentlyContinue
if ($nodeCmd) {
    $nodeVer = (node --version).ToString().Trim()
    $npmVer = (npm --version).ToString().Trim()
    Print-Status "JA BAIXADO / INSTALADO" "Node.js e npm" "Node: $nodeVer | npm: $npmVer" $true
} else {
    Print-Status "X AUSENTE" "Node.js" "Nao instalado (opcional, apenas para site showcase)" $false
}

$siteModules = Join-Path $baseDir "ekobelth_site\node_modules"
if (Test-Path $siteModules) {
    Print-Status "JA BAIXADO / INSTALADO" "Modulos Site Showcase" "ekobelth_site\node_modules detectado" $true
} else {
    Print-Status "PENDENTE" "Modulos Site Showcase" "Requer 'npm install' em ekobelth_site" $false
}

Write-Host ""
# 5. BANCO DE DADOS MYSQL
Write-Host "[5] VERIFICANDO BANCO DE DADOS:" -ForegroundColor White
$envEkobelth = Join-Path $baseDir "ekobelth\.env"
$envRoot = Join-Path $baseDir ".env"
if ((Test-Path $envEkobelth) -or (Test-Path $envRoot)) {
    Print-Status "JA CONFIGURADO" "Arquivo de Ambiente" "Arquivo .env detectado" $true
} else {
    Print-Status "PENDENTE" "Arquivo de Ambiente" "Nenhum .env encontrado (sera criado pelo instalador)" $false
}

# Teste de porta 3306 (MySQL padrao)
try {
    $tcp = New-Object System.Net.Sockets.TcpClient
    $tcp.Connect("127.0.0.1", 3306)
    if ($tcp.Connected) {
        $tcp.Close()
        Print-Status "JA BAIXADO / EM EXECUCAO" "Servidor MySQL" "Porta 3306 aberta e respondendo!" $true
    }
} catch {
    Print-Status "INFO" "Servidor MySQL" "Porta 3306 fechada ou servico MySQL parado" $false
}

Write-Host ""
# 6. OLLAMA
Write-Host "[6] VERIFICANDO OLLAMA (IA LOCAL):" -ForegroundColor White
$ollamaCmd = Get-Command ollama -ErrorAction SilentlyContinue
if ($ollamaCmd) {
    Print-Status "JA BAIXADO / INSTALADO" "Ollama" "Ollama detectado no sistema" $true
} else {
    Print-Status "OPCIONAL" "Ollama" "Nao encontrado (opcional, necessarios se for rodar IA Eko local)" $false
}

Write-Host ""
Write-Host "=====================================================================" -ForegroundColor Cyan
Write-Host " Diagnóstico finalizado!" -ForegroundColor Green
Write-Host " Para instalar o que estiver faltando, execute 'instalar.bat' ou 'instalar.ps1'." -ForegroundColor White
Write-Host "=====================================================================" -ForegroundColor Cyan
Write-Host "Pressione qualquer tecla para sair..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
