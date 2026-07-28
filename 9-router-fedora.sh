#!/usr/bin/env bash

# ==============================================================================
# Script para instalar e gerenciar a CLI do 9Router
# Versão Fedora / Silverblue / Kinoite / COSMIC - Português do Brasil
# ==============================================================================

set -euo pipefail

# ==============================================================================
# CONFIGURAÇÕES INICIAIS
# ==============================================================================

USER_HOME="${HOME}"
GLOBAL_SHARE_DIR="${USER_HOME}/.local/share/9router-cli"
GLOBAL_BIN_DIR="${USER_HOME}/.local/bin"
BUN_INSTALL_DIR="${USER_HOME}/.bun"
SECRETS_FILE="${USER_HOME}/.config/secrets.env"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Detectar se é Fedora Imutável (Silverblue, Kinoite, COSMIC)
IS_IMMUTABLE=false
if command -v rpm-ostree &> /dev/null; then
    IS_IMMUTABLE=true
fi

# ==============================================================================
# FUNÇÕES AUXILIARES (CORES + LOG)
# ==============================================================================

function log() {
    echo -e "\033[1;34m[INFO]\033[0m   $1"
}

function success() {
    echo -e "\033[1;32m[OK]\033[0m     $1"
}

function warn() {
    echo -e "\033[1;33m[WARNING]\033[0m $1"
}

function error() {
    echo -e "\033[1;31m[ERROR]\033[0m  $1"
}

function debug() {
    echo -e "\033[1;36m[DEBUG]\033[0m $1"
}

# ==============================================================================
# INSTALAÇÃO DE PACOTES DO SISTEMA
# ==============================================================================

function install_system_package() {
    local package=$1

    if [[ "${IS_IMMUTABLE}" == true ]]; then
        # Fedora Imutável (Silverblue, Kinoite, COSMIC)
        log "Instalando ${package} via rpm-ostree (sistema imutável)..."
        if sudo rpm-ostree install --idempotent "${package}"; then
            success "${package} instalado via rpm-ostree."
            warn "⚠️  REINICIE O SISTEMA para aplicar as alterações."
            return 0
        fi
    else
        # Fedora Tradicional
        log "Instalando ${package} via dnf..."
        if sudo dnf install -y "${package}"; then
            success "${package} instalado via dnf."
            return 0
        fi
    fi
    return 1
}

# ==============================================================================
# INSTALAÇÃO AUTOMÁTICA DO BUN
# ==============================================================================

function install_bun() {
    log "Instalando Bun (runtime JavaScript)..."

    # Verificar se curl está disponível
    if ! command -v curl &> /dev/null; then
        log "curl não encontrado. Instalando..."
        if ! install_system_package "curl"; then
            error "Falha ao instalar curl."
            return 1
        fi
    fi

    # Instalar Bun via script oficial
    if curl -fsSL https://bun.sh/install | bash; then
        # Adicionar Bun ao PATH para esta sessão
        export PATH="${BUN_INSTALL_DIR}/bin:${PATH}"

        # Garantir que Bun persiste no PATH
        local shell_rc=""
        if [[ -f "${USER_HOME}/.bashrc" ]]; then
            shell_rc="${USER_HOME}/.bashrc"
        elif [[ -f "${USER_HOME}/.zshrc" ]]; then
            shell_rc="${USER_HOME}/.zshrc"
        elif [[ -f "${USER_HOME}/.config/fish/config.fish" ]]; then
            # Fish usa formatação diferente
            shell_rc="${USER_HOME}/.config/fish/config.fish"
        fi

        if [[ -n "${shell_rc}" ]]; then
            if ! grep -q 'bun/bin' "${shell_rc}" 2>/dev/null; then
                if [[ "${shell_rc}" == *"fish"* ]]; then
                    # Fish shell
                    echo '' >> "${shell_rc}"
                    echo '# Bun Runtime' >> "${shell_rc}"
                    echo 'set -gx PATH $HOME/.bun/bin $PATH' >> "${shell_rc}"
                else
                    # Bash/Zsh
                    echo '' >> "${shell_rc}"
                    echo '# Bun Runtime' >> "${shell_rc}"
                    echo 'export PATH="$HOME/.bun/bin:$PATH"' >> "${shell_rc}"
                fi
                log "Bun adicionado ao PATH em ${shell_rc}"
            fi
        fi

        success "Bun instalado com sucesso!"
        return 0
    else
        error "Falha ao instalar Bun."
        return 1
    fi
}

# ==============================================================================
# VALIDAÇÃO DE AMBIENTE
# ==============================================================================

function validate_environment() {
    local status=0

    # Verificar SO
    if [[ -f "/etc/os-release" ]]; then
        local os_id
        local os_version_id
        os_id=$(grep "^ID=" "/etc/os-release" | cut -d'=' -f2 | tr -d '"' | tr -d "'")
        os_version_id=$(grep "^VERSION_ID=" "/etc/os-release" | cut -d'=' -f2 | tr -d '"' | tr -d "'")
        debug "Sistema Operacional detectado: ${os_id} ${os_version_id}"

        # Verificar se é Fedora ou derivado
        case "${os_id}" in
            fedora)
                if [[ "${IS_IMMUTABLE}" == true ]]; then
                    # Detectar variante imutável
                    if [[ -f "/etc/os-release" ]]; then
                        local variant
                        variant=$(grep "^VARIANT_ID=" "/etc/os-release" | cut -d'=' -f2 | tr -d '"' | tr -d "'")
                        case "${variant}" in
                            silverblue)
                                debug "Variante detectada: Fedora Silverblue"
                                ;;
                            kinoite)
                                debug "Variante detectada: Fedora Kinoite"
                                ;;
                            cosmit)
                                debug "Variante detectada: Fedora COSMIC"
                                ;;
                            *)
                                debug "Variante imutável detectada: ${variant}"
                                ;;
                        esac
                    fi
                    success "Fedora Imutável detectado — usando rpm-ostree."
                else
                    success "Fedora Tradicional detectado — usando dnf."
                fi
                ;;
            *)
                warn "Este script foi otimizado para Fedora, mas pode funcionar em outras distribuições RPM."
                ;;
        esac
    fi

    # Verificar/instalar Bun
    if ! command -v bun &> /dev/null; then
        warn "Bun não encontrado. Instalando automaticamente..."
        if ! install_bun; then
            error "Não foi possível instalar Bun."
            error "Instale manualmente: curl -fsSL https://bun.sh/install | bash"
            status=1
        fi
    else
        debug "Bun detectado: $(command -v bun)"
    fi

    return ${status}
}

# ==============================================================================
# CRIAR TEMPLATE DE SECRETS
# ==============================================================================

function create_secrets_template() {
    local secrets_dir
    secrets_dir=$(dirname "${SECRETS_FILE}")

    if [[ -f "${SECRETS_FILE}" ]]; then
        debug "Arquivo secrets.env já existe. Pulando criação."
        return 0
    fi

    log "Criando template de secrets em ${SECRETS_FILE}..."
    mkdir -p "${secrets_dir}"

    cat > "${SECRETS_FILE}" << 'SECRETS_EOF'
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
SECRETS_EOF

    chmod 600 "${SECRETS_FILE}"
    success "Template criado: ${SECRETS_FILE}"
    warn "Edite com suas chaves reais: nano ${SECRETS_FILE}"
}

# ==============================================================================
# INSTALAÇÃO GLOBAL
# ==============================================================================

function install_package() {
    local manager=$1
    local package_name=$2

    if [[ "${manager}" == "bun" ]]; then
        log "Instalando ${package_name} globalmente via Bun..."
        if bun add -g "${package_name}"; then
            success "Instalação concluída via Bun."
            return 0
        fi
    elif [[ "${manager}" == "npm" ]]; then
        log "Instalando ${package_name} globalmente via npm..."
        if npm install -g "${package_name}"; then
            success "Instalação concluída via npm."
            return 0
        fi
    fi
    return 1
}

function install_global() {
    log "Iniciando a instalação do 9Router globalmente..."

    # Criar estrutura de diretórios
    mkdir -p "${GLOBAL_SHARE_DIR}"
    mkdir -p "${GLOBAL_BIN_DIR}"

    # Copiar script para execução global
    log "Copiando o script para ${GLOBAL_BIN_DIR}/9router..."
    if cp "${SCRIPT_DIR}/9-router-fedora.sh" "${GLOBAL_BIN_DIR}/9router" && \
       chmod +x "${GLOBAL_BIN_DIR}/9router"; then
        success "Script copiado para execução global."
    else
        error "Falha ao copiar script para execução global."
        return 1
    fi

    # Detectar gerenciador de pacotes
    local package_manager=""
    if command -v bun &> /dev/null; then
        package_manager="bun"
        log "Gerenciador de pacotes Bun detectado."
    elif command -v npm &> /dev/null; then
        package_manager="npm"
        log "Gerenciador de pacotes npm detectado."
    fi

    # Instalar pacote 9router
    if [[ -n "${package_manager}" ]]; then
        log "Instalando 9router globalmente..."
        if install_package "${package_manager}" "9router"; then
            success "Pacote 9router instalado globalmente."
        else
            warn "Falha ao instalar pacote 9router (pode não existir no registry)."
            warn "O script continuará funcionando via proxy local."
        fi
    else
        error "Nenhum gerenciador de pacotes encontrado."
        return 1
    fi

    # Criar template de secrets
    create_secrets_template

    # Verificar PATH
    if [[ ":${PATH}:" != *":${GLOBAL_BIN_DIR}:"* ]]; then
        warn "${GLOBAL_BIN_DIR} não está no seu PATH atual."
        echo "💡 Adicione ao seu ~/.bashrc, ~/.zshrc ou ~/.config/fish/config.fish:"
        echo "   Bash/Zsh: export PATH=\"${GLOBAL_BIN_DIR}:\$PATH\""
        echo "   Fish:     set -gx PATH ${GLOBAL_BIN_DIR} \$PATH"
    fi

    # Aviso para sistemas imutáveis
    if [[ "${IS_IMMUTABLE}" == true ]]; then
        echo ""
        warn "SISTEMA IMUTÁVEL DETECTADO (Silverblue/Kinoite/COSMIC)"
        echo "💡 Se instalou pacotes via rpm-ostree, reinicie o sistema:"
        echo "   sudo systemctl reboot"
    fi

    success "Instalação global concluída com sucesso!"
    echo ""
    echo "🚀 Próximos passos:"
    echo "   1. Edite suas chaves API: nano ~/.config/secrets.env"
    echo "   2. Carregue as variáveis: source ~/.config/secrets.env"
    echo "   3. Execute: 9router --help"
}

# ==============================================================================
# DESINSTALAÇÃO
# ==============================================================================

function uninstall_global() {
    log "Iniciando a desinstalação global do 9Router..."

    # Remover script
    if [[ -f "${GLOBAL_BIN_DIR}/9router" ]]; then
        rm -f "${GLOBAL_BIN_DIR}/9router"
        success "Script removido de ${GLOBAL_BIN_DIR}/9router."
    else
        warn "Script não encontrado em ${GLOBAL_BIN_DIR}/9router."
    fi

    # Remover pacote
    if command -v bun &> /dev/null; then
        bun remove -g 9router 2>/dev/null || true
        success "Remoção via Bun concluída."
    elif command -v npm &> /dev/null; then
        npm uninstall -g 9router 2>/dev/null || true
        success "Remoção via npm concluída."
    fi

    # Remover diretório de compartilhamento
    if [[ -d "${GLOBAL_SHARE_DIR}" ]]; then
        rm -rf "${GLOBAL_SHARE_DIR}"
        success "Diretório de compartilhamento removido."
    fi

    success "Desinstalação global concluída com sucesso!"
}

# ==============================================================================
# AJUDA
# ==============================================================================

function show_help() {
    local fedora_type="Fedora"
    if [[ "${IS_IMMUTABLE}" == true ]]; then
        fedora_type="Fedora Imutável (Silverblue/Kinoite/COSMIC)"
    fi

    cat << HELP_EOF
╔══════════════════════════════════════════════════════════════╗
║               9Router CLI - ${fedora_type}                    ║
╚══════════════════════════════════════════════════════════════╝

Uso: ./9-router-fedora.sh [opções]

OPÇÕES DO SCRIPT:
  --install          Instala globalmente no sistema
  --uninstall        Remove instalação global do sistema
  --help             Exibe esta ajuda

INSTALAÇÃO RÁPIDA:
  chmod +x 9-router-fedora.sh
  ./9-router-fedora.sh --install

APÓS INSTALAÇÃO:
  9router --help
  9router -p 20128
  9router --version

OPÇÕES DO 9ROUTER CLI:
  -p, --port <port>        Porta do servidor (padrão: 20128)
  -H, --host <host>        Host para bind (padrão: 0.0.0.0)
  -n, --no-browser         Não abre navegador automaticamente
  -l, --log                Exibe logs do servidor
  -t, --tray               Executa em modo de bandeja (background)
  -h, --help               Mostra ajuda do 9router
  -v, --version            Mostra versão

DESINSTALAÇÃO:
  ./9-router-fedora.sh --uninstall

SISTEMAS SUPORTADOS:
  • Fedora 38+
  • Fedora Silverblue (imutável)
  • Fedora Kinoite (imutável)
  • Fedora COSMIC (imutável)
  • Outros baseados em Fedora/RPM
HELP_EOF
}

# ==============================================================================
# DELEGAR EXECUÇÃO PARA 9ROUTER
# ==============================================================================

function delegate_to_9router() {
    local bun_bin_path="${HOME}/.bun/bin"

    if [[ -f "${bun_bin_path}/9router" ]]; then
        exec "${bun_bin_path}/9router" "${@}"
    elif command -v bun &> /dev/null; then
        local global_bin_path
        global_bin_path=$(bun pm -g bin 2>/dev/null | head -n1 || true)
        if [[ -n "${global_bin_path}" ]] && [[ -f "${global_bin_path}/9router" ]]; then
            exec "${global_bin_path}/9router" "${@}"
        else
            exec bun x 9router "${@}"
        fi
    else
        error "9router não encontrado globalmente."
        error "Execute a instalação primeiro: ./9-router-fedora.sh --install"
        exit 1
    fi
}

# ==============================================================================
# PONTO DE ENTRADA PRINCIPAL
# ==============================================================================

function main() {
    # Sem argumentos — mostrar ajuda
    if [[ $# -eq 0 ]]; then
        show_help
        exit 0
    fi

    # Processar argumentos
    case "${1}" in
        -h|--help)
            show_help
            exit 0
            ;;
        --install)
            if ! validate_environment; then
                error "Validação do ambiente falhou."
                exit 1
            fi
            if ! install_global; then
                error "Instalação falhou."
                exit 1
            fi
            exit 0
            ;;
        --uninstall)
            if ! uninstall_global; then
                error "Desinstalação falhou."
                exit 1
            fi
            exit 0
            ;;
        *)
            # Se executando de ~/.local/bin, delegar para 9router
            if [[ "${SCRIPT_DIR}" == "${GLOBAL_BIN_DIR}" ]]; then
                delegate_to_9router "${@}"
            fi

            # Se executando do diretório de origem
            echo "📦 Detectada execução no diretório de origem."
            echo "💡 Execute primeiro: ./9-router-fedora.sh --install"
            echo ""
            delegate_to_9router "${@}"
            ;;
    esac
}

# ==============================================================================
# EXECUÇÃO (apenas quando chamado diretamente)
# ==============================================================================

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "${@}"
fi
