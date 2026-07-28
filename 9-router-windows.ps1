#!/usr/bin/env pwsh
# ==============================================================================
# Script para instalar e gerenciar a CLI do 9Router
# Versão Windows 11 - Português do Brasil
# ==============================================================================

param(
    [Parameter(Position=0)]
    [string]$Command
)

$ErrorActionPreference = "Stop"

# ==============================================================================
# CONFIGURAÇÕES INICIAIS
# ==============================================================================

$USER_HOME = $env:USERPROFILE
$GLOBAL_SHARE_DIR = "${USER_HOME}\.local\share\9router-cli"
$GLOBAL_BIN_DIR = "${USER_HOME}\.local\bin"
$BUN_INSTALL_DIR = "${USER_HOME}\.bun"
$SECRETS_FILE = "${USER_HOME}\.config\secrets.env"
$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path

# ==============================================================================
# FUNÇÕES AUXILIARES (CORES + LOG)
# ==============================================================================

function log() {
    Write-Host "[INFO]" -ForegroundColor Blue -NoNewline
    Write-Host "   $($args[0])"
}

function success() {
    Write-Host "[OK]" -ForegroundColor Green -NoNewline
    Write-Host "     $($args[0])"
}

function warn() {
    Write-Host "[WARNING]" -ForegroundColor Yellow -NoNewline
    Write-Host " $($args[0])"
}

function error() {
    Write-Host "[ERROR]" -ForegroundColor Red -NoNewline
    Write-Host "  $($args[0])"
}

function debug() {
    Write-Host "[DEBUG]" -ForegroundColor Cyan -NoNewline
    Write-Host " $($args[0])"
}

# ==============================================================================
# INSTALAÇÃO AUTOMÁTICA DO BUN
# ==============================================================================

function Install-Bun() {
    log "Instalando Bun (runtime JavaScript)..."

    # Verificar se curl está disponível (no Windows, curl é nativo desde 1803)
    if (!(Get-Command curl -ErrorAction SilentlyContinue)) {
        log "curl não encontrado no sistema."
        warn "Baixe e instale o Bun manualmente: https://bun.sh"
        warn "Ou instale via winget: winget install Bun.Bun"

        if (Get-Command winget -ErrorAction SilentlyContinue) {
            log "Instalando Bun via winget..."
            try {
                winget install --id Bun.Bun --exact --silent --accept-package-agreements
                if ($LASTEXITCODE -eq 0) {
                    success "Bun instalado via winget!"
                    return $true
                }
            } catch {
                error "Falha ao instalar Bun via winget."
            }
        }
        return $false
    }

    # Instalar Bun via script oficial (requer curl)
    $bunInstallScript = Invoke-WebRequest -Uri "https://bun.sh/install" -UseBasicParsing
    $tempScript = "${env:TEMP}\install-bun.ps1"

    # O script oficial do Bun é curl | bash - convertemos para PowerShell
    log "Baixando e instalando Bun..."
    try {
        $installCmd = [System.Text.Encoding]::UTF8.GetString(
            (Invoke-WebRequest -Uri "https://bun.sh/install" -UseBasicParsing).Content
        )
        # Salvar e executar via cmd para compatibilidade
        Set-Content -Path $tempScript -Value $installCmd -Encoding UTF8
        & cmd /c "type `"$tempScript`" | bash" 2>&1 | Out-Null
    } catch {
        error "Falha ao baixar script de instalação do Bun."
        return $false
    }

    # Adicionar Bun ao PATH para esta sessão
    $env:Path = "${BUN_INSTALL_DIR}\bin;$env:Path"

    # Adicionar ao PATH do usuário permanentemente
    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    $bunPath = "${BUN_INSTALL_DIR}\bin"
    if ($userPath -notlike "*${bunPath}*") {
        [Environment]::SetEnvironmentVariable("Path", "${userPath};${bunPath}", "User")
        log "Bun adicionado ao PATH do usuário permanentemente."
    }

    success "Bun instalado com sucesso!"
    return $true
}

# ==============================================================================
# INSTALAÇÃO DO BUN VIA POWERSHELL (ALTERNATIVA NATIVA)
# ==============================================================================

function Install-Bun-Native() {
    log "Tentando instalação nativa do Bun via PowerShell..."

    $bunUrl = "https://bun.sh/install"
    $powershellScript = "${env:TEMP}\bun-install.ps1"

    try {
        log "Baixando script de instalação..."
        $scriptContent = Invoke-WebRequest -Uri $bunUrl -UseBasicParsing -TimeoutSec 30
        Set-Content -Path $powershellScript -Value $scriptContent.Content -Encoding UTF8

        # Executar script via PowerShell
        & powershell -ExecutionPolicy Bypass -File $powershellScript
        if ($LASTEXITCODE -eq 0) {
            $env:Path = "${BUN_INSTALL_DIR}\bin;$env:Path"
            success "Bun instalado com sucesso!"
            return $true
        }
    } catch {
        warn "Instalação nativa falhou: $($_.Exception.Message)"
    }
    return $false
}

# ==============================================================================
# VALIDAÇÃO DE AMBIENTE
# ==============================================================================

function Validate-Environment() {
    $status = $true

    # Verificar SO
    $osInfo = (Get-CimInstance Win32_OperatingSystem).Caption
    debug "Sistema Operacional detectado: ${osInfo}"

    if ($osInfo -notlike "*Windows 11*" -and $osInfo -notlike "*Windows 10*") {
        warn "Este script foi otimizado para Windows 11, mas pode funcionar em versões anteriores."
    }

    # Verificar/instalar Bun
    if (!(Get-Command bun -ErrorAction SilentlyContinue)) {
        warn "Bun não encontrado. Instalando automaticamente..."

        # Tentar instalação via winget primeiro
        if (Get-Command winget -ErrorAction SilentlyContinue) {
            log "Instalando Bun via winget..."
            try {
                winget install --id Bun.Bun --exact --silent --accept-package-agreements 2>&1 | Out-Null
                if ($LASTEXITCODE -eq 0) {
                    $env:Path = "${BUN_INSTALL_DIR}\bin;$env:Path"
                    success "Bun instalado via winget!"
                }
            } catch {
                warn "Falha ao instalar via winget. Tentando método alternativo..."
                if (!(Install-Bun-Native)) {
                    if (!(Install-Bun)) {
                        error "Não foi possível instalar Bun."
                        error "Instale manualmente: https://bun.sh (ou winget install Bun.Bun)"
                        $status = $false
                    }
                }
            }
        } else {
            if (!(Install-Bun-Native)) {
                if (!(Install-Bun)) {
                    error "Não foi possível instalar Bun."
                    error "Instale manualmente: https://bun.sh"
                    $status = $false
                }
            }
        }
    } else {
        debug "Bun detectado: $(Get-Command bun).Source"
    }

    return $status
}

# ==============================================================================
# CRIAR TEMPLATE DE SECRETS
# ==============================================================================

function Create-Secrets-Template() {
    $secretsDir = Split-Path -Parent $SECRETS_FILE

    if (Test-Path $SECRETS_FILE) {
        debug "Arquivo secrets.env já existe. Pulando criação."
        return $true
    }

    log "Criando template de secrets em ${SECRETS_FILE}..."
    New-Item -ItemType Directory -Path $secretsDir -Force | Out-Null

    $content = @'
# ~/.config/secrets.env
# ATENÇÃO: NUNCA comite este arquivo. Adicione ao .gitignore.
#
# Preencha com suas chaves reais e rode: source ~/.config/secrets.env

# Claude / Anthropic
export ANTHROPIC_BASE_URL="http://localhost:20128"
export ANTHROPIC_API_KEY="sua-chave-aqui"

# OpenRouter
export OPENROUTER_API_KEY="sua-chave-aqui"

# Google / Gemini
export GOOGLE_API_KEY="sua-chave-aqui"
export GEMINI_API_KEY="sua-chave-aqui"
export GEMINI_BASE_URL="https://generativelanguage.googleapis.com"

# OpenAI (compatível)
export OPENAI_BASE_URL="https://api.openai.com/v1"
export OPENAI_API_KEY="sua-chave-aqui"

# Outros (opcional)
export XAI_API_KEY=""
export GITHUB_TOKEN=""
'@

    Set-Content -Path $SECRETS_FILE -Value $content -Encoding UTF8

    # No Windows, usar icacls para restringir permissões (similar ao chmod 600)
    try {
        icacls $SECRETS_FILE /inheritance:r /grant "${env:USERNAME}:(R,W)" 2>&1 | Out-Null
        success "Permissões restritas aplicadas ao secrets.env"
    } catch {
        warn "Não foi possível restringir permissões automaticamente."
    }

    success "Template criado: ${SECRETS_FILE}"
    warn "Edite com suas chaves reais: notepad ${SECRETS_FILE}"
    return $true
}

# ==============================================================================
# INSTALAÇÃO GLOBAL
# ==============================================================================

function Install-Package() {
    param([string]$Manager, [string]$PackageName)

    if ($Manager -eq "bun") {
        log "Instalando ${PackageName} globalmente via Bun..."
        try {
            $result = bun add -g $PackageName 2>&1
            if ($LASTEXITCODE -eq 0) {
                success "Instalação concluída via Bun."
                return $true
            }
        } catch {
            warn "Falha ao instalar via Bun: $($_.Exception.Message)"
        }
    } elseif ($Manager -eq "npm") {
        log "Instalando ${PackageName} globalmente via npm..."
        try {
            $result = npm install -g $PackageName 2>&1
            if ($LASTEXITCODE -eq 0) {
                success "Instalação concluída via npm."
                return $true
            }
        } catch {
            warn "Falha ao instalar via npm: $($_.Exception.Message)"
        }
    }
    return $false
}

function Install-Global() {
    log "Iniciando a instalação do 9Router globalmente..."

    # Criar estrutura de diretórios
    New-Item -ItemType Directory -Path $GLOBAL_SHARE_DIR -Force | Out-Null
    New-Item -ItemType Directory -Path $GLOBAL_BIN_DIR -Force | Out-Null

    # Copiar script para execução global
    log "Copiando o script para ${GLOBAL_BIN_DIR}\9router.ps1..."
    try {
        Copy-Item "${SCRIPT_DIR}\9-router-windows.ps1" "${GLOBAL_BIN_DIR}\9router.ps1" -Force
        success "Script copiado para execução global."
    } catch {
        error "Falha ao copiar script para execução global."
        return $false
    }

    # Criar atalho .cmd para execução sem PowerShell prefix
    $cmdContent = @"
@echo off
REM Atalho para 9router CLI - Windows
powershell -ExecutionPolicy Bypass -File "%USERPROFILE%\.local\bin\9router.ps1" %*
"@
    Set-Content -Path "${GLOBAL_BIN_DIR}\9router.cmd" -Value $cmdContent -Encoding ASCII
    success "Atalho .cmd criado para execução direta."

    # Detectar gerenciador de pacotes
    $packageManager = ""
    if (Get-Command bun -ErrorAction SilentlyContinue) {
        $packageManager = "bun"
        log "Gerenciador de pacotes Bun detectado."
    } elseif (Get-Command npm -ErrorAction SilentlyContinue) {
        $packageManager = "npm"
        log "Gerenciador de pacotes npm detectado."
    }

    # Instalar pacote 9router
    if ($packageManager -ne "") {
        log "Instalando 9router globalmente..."
        if (Install-Package -Manager $packageManager -PackageName "9router") {
            success "Pacote 9router instalado globalmente."
        } else {
            warn "Falha ao instalar pacote 9router (pode não existir no registry)."
            warn "O script continuará funcionando via proxy local."
        }
    } else {
        error "Nenhum gerenciador de pacotes encontrado."
        return $false
    }

    # Criar template de secrets
    Create-Secrets-Template

    # Adicionar ao PATH do usuário se necessário
    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    if ($userPath -notlike "*${GLOBAL_BIN_DIR}*") {
        [Environment]::SetEnvironmentVariable("Path", "${userPath};${GLOBAL_BIN_DIR}", "User")
        log "${GLOBAL_BIN_DIR} adicionado ao PATH do usuário."
        warn "Reinicie o terminal ou execute: `$env:Path = `"${GLOBAL_BIN_DIR};`$env:Path`""
    }

    success "Instalação global concluída com sucesso!"
    Write-Host ""
    Write-Host "🚀 Próximos passos:" -ForegroundColor Cyan
    Write-Host "   1. Edite suas chaves API: notepad ${SECRETS_FILE}"
    Write-Host "   2. Execute: 9router --help"
    Write-Host "   3. Ou: 9router -p 20128"
    Write-Host ""
    Write-Host "💡 Dica: Adicione o diretório ao PATH manualmente se necessário:" -ForegroundColor Yellow
    Write-Host "   [Environment]::SetEnvironmentVariable('Path'," -ForegroundColor Gray
    Write-Host "       `"${GLOBAL_BIN_DIR};`$([Environment]::GetEnvironmentVariable('Path','User'))`"," -ForegroundColor Gray
    Write-Host "       'User')" -ForegroundColor Gray

    return $true
}

# ==============================================================================
# DESINSTALAÇÃO
# ==============================================================================

function Uninstall-Global() {
    log "Iniciando a desinstalação global do 9Router..."

    # Remover script
    $scriptPath = "${GLOBAL_BIN_DIR}\9router.ps1"
    $cmdPath = "${GLOBAL_BIN_DIR}\9router.cmd"

    if (Test-Path $scriptPath) {
        Remove-Item -Path $scriptPath -Force
        success "Script removido de ${scriptPath}."
    } else {
        warn "Script não encontrado em ${scriptPath}."
    }

    if (Test-Path $cmdPath) {
        Remove-Item -Path $cmdPath -Force
        success "Atalho .cmd removido."
    }

    # Remover pacote via gerenciador
    if (Get-Command bun -ErrorAction SilentlyContinue) {
        try {
            bun remove -g 9router 2>&1 | Out-Null
            success "Remoção via Bun concluída."
        } catch {
            # Ignorar erro se pacote não existe
        }
    } elseif (Get-Command npm -ErrorAction SilentlyContinue) {
        try {
            npm uninstall -g 9router 2>&1 | Out-Null
            success "Remoção via npm concluída."
        } catch {
            # Ignorar erro se pacote não existe
        }
    }

    # Remover diretório de compartilhamento
    if (Test-Path $GLOBAL_SHARE_DIR) {
        Remove-Item -Path $GLOBAL_SHARE_DIR -Recurse -Force
        success "Diretório de compartilhamento removido."
    }

    success "Desinstalação global concluída com sucesso!"
    return $true
}

# ==============================================================================
# AJUDA
# ==============================================================================

function Show-Help() {
    Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║             9Router CLI - Windows 11                        ║" -ForegroundColor Cyan
    Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Uso: .\9-router-windows.ps1 [opções]" -ForegroundColor White
    Write-Host ""
    Write-Host "OPÇÕES DO SCRIPT:" -ForegroundColor Yellow
    Write-Host "  --install          Instala globalmente no sistema"
    Write-Host "  --uninstall        Remove instalação global do sistema"
    Write-Host "  --help             Exibe esta ajuda"
    Write-Host ""
    Write-Host "INSTALAÇÃO RÁPIDA:" -ForegroundColor Yellow
    Write-Host "  Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser"
    Write-Host "  .\9-router-windows.ps1 --install"
    Write-Host ""
    Write-Host "APÓS INSTALAÇÃO:" -ForegroundColor Yellow
    Write-Host "  9router --help"
    Write-Host "  9router -p 20128"
    Write-Host "  9router --version"
    Write-Host ""
    Write-Host "OPÇÕES DO 9ROUTER CLI:" -ForegroundColor Yellow
    Write-Host "  -p, --port <port>        Porta do servidor (padrão: 20128)"
    Write-Host "  -H, --host <host>        Host para bind (padrão: 0.0.0.0)"
    Write-Host "  -n, --no-browser         Não abre navegador automaticamente"
    Write-Host "  -l, --log                Exibe logs do servidor"
    Write-Host "  -t, --tray               Executa em modo de bandeja (background)"
    Write-Host "  -h, --help               Mostra ajuda do 9router"
    Write-Host "  -v, --version            Mostra versão"
    Write-Host ""
    Write-Host "DESINSTALAÇÃO:" -ForegroundColor Yellow
    Write-Host "  .\9-router-windows.ps1 --uninstall"
    Write-Host ""
    Write-Host "SISTEMAS SUPORTADOS:" -ForegroundColor Yellow
    Write-Host "  • Windows 11"
    Write-Host "  • Windows 10"
    Write-Host "  • Windows Server 2022+"
}

# ==============================================================================
# DELEGAR EXECUÇÃO PARA 9ROUTER
# ==============================================================================

function Delegate-To-9router() {
    $bunBinPath = "${env:USERPROFILE}\.bun\bin"
    $bunBinPath9router = "${bunBinPath}\9router"

    if (Test-Path $bunBinPath9router) {
        debug "Executando 9router via Bun global..."
        & $bunBinPath9router $args
        exit $LASTEXITCODE
    } elseif (Get-Command bun -ErrorAction SilentlyContinue) {
        debug "Executando 9router via bun x..."
        & bun x 9router $args
        exit $LASTEXITCODE
    } else {
        error "9router não encontrado globalmente."
        error "Execute a instalação primeiro: .\9-router-windows.ps1 --install"
        exit 1
    }
}

# ==============================================================================
# PONTO DE ENTRADA PRINCIPAL
# ==============================================================================

function Main() {
    # Sem argumentos — mostrar ajuda
    if ($args.Count -eq 0 -or [string]::IsNullOrEmpty($args[0])) {
        Show-Help
        exit 0
    }

    # Processar argumentos
    switch ($args[0]) {
        "-h"
        "--help" {
            Show-Help
            exit 0
        }
        "--install" {
            if (!(Validate-Environment)) {
                error "Validação do ambiente falhou."
                exit 1
            }
            if (!(Install-Global)) {
                error "Instalação falhou."
                exit 1
            }
            exit 0
        }
        "--uninstall" {
            if (!(Uninstall-Global)) {
                error "Desinstalação falhou."
                exit 1
            }
            exit 0
        }
        default {
            # Se executando de ~/.local/bin, delegar para 9router
            if ($SCRIPT_DIR -eq $GLOBAL_BIN_DIR) {
                Delegate-To-9router @args
            }

            # Se executando do diretório de origem
            Write-Host "📦 Detectada execução no diretório de origem." -ForegroundColor Cyan
            Write-Host "💡 Execute primeiro: .\9-router-windows.ps1 --install" -ForegroundColor Yellow
            Write-Host ""
            Delegate-To-9router @args
        }
    }
}

# ==============================================================================
# EXECUÇÃO
# ==============================================================================

Main @args
