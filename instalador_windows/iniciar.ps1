# Ekobelth - Painel de Controle (PowerShell)
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $scriptDir

function Show-Menu {
    Clear-Host
    Write-Host "=====================================================================" -ForegroundColor Cyan
    Write-Host "                     EKOBELTH - PAINEL DE CONTROLE" -ForegroundColor Yellow
    Write-Host "=====================================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  [1] Iniciar TUDO (Backend + IA Eko + App Web) [Recomendado]" -ForegroundColor Green
    Write-Host "  [2] Iniciar apenas Backend FastAPI (Porta 8000)" -ForegroundColor White
    Write-Host "  [3] Iniciar apenas IA Eko API (Porta 8001)" -ForegroundColor White
    Write-Host "  [4] Iniciar App Flutter no Navegador (Edge / Chrome)" -ForegroundColor White
    Write-Host "  [5] Iniciar App Flutter Nativo (Windows Desktop)" -ForegroundColor White
    Write-Host "  [6] Iniciar Site Showcase / Pitch (Porta 3000)" -ForegroundColor White
    Write-Host "  [7] Testar e Inicializar Banco de Dados (MySQL)" -ForegroundColor Yellow
    Write-Host "  [8] Verificar Ambiente e Pacotes Baixados" -ForegroundColor Cyan
    Write-Host "  [9] Reinstalar / Atualizar Pacotes (instalar.ps1)" -ForegroundColor DarkGray
    Write-Host "  [0] Sair" -ForegroundColor Gray
    Write-Host ""
    Write-Host "=====================================================================" -ForegroundColor Cyan
}

while ($true) {
    Show-Menu
    $opcao = Read-Host "Escolha uma opcao (0-9)"
    switch ($opcao) {
        "1" { Start-Process cmd.exe -ArgumentList "/c scripts\run_tudo.bat" }
        "2" { Start-Process cmd.exe -ArgumentList "/c scripts\run_backend.bat" }
        "3" { Start-Process cmd.exe -ArgumentList "/c scripts\run_ia_eko.bat" }
        "4" { Start-Process cmd.exe -ArgumentList "/c scripts\run_flutter_web.bat" }
        "5" { Start-Process cmd.exe -ArgumentList "/c scripts\run_flutter_desktop.bat" }
        "6" { Start-Process cmd.exe -ArgumentList "/c scripts\run_showcase.bat" }
        "7" { Start-Process -Wait cmd.exe -ArgumentList "/c configurar_banco.bat" }
        "8" { Start-Process -Wait powershell.exe -ArgumentList "-NoExit -File verificar_ambiente.ps1" }
        "9" { Start-Process -Wait powershell.exe -ArgumentList "-NoExit -File instalar.ps1" }
        "0" { exit }
        default {
            Write-Host "Opcao invalida!" -ForegroundColor Red
            Start-Sleep -Seconds 1
        }
    }
}
