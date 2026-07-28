# 🛡️ 9Router CLI

**Servidor de proxy local para Claude CLI** — Encaminha requisições para modelos gratuitos via OpenRouter.

[![Ubuntu/Debian](https://img.shields.io/badge/Ubuntu-20.04%2B-orange?logo=ubuntu)](QuickStart-Ubuntu.md)
[![Debian](https://img.shields.io/badge/Debian-11%2B-red?logo=debian)](QuickStart-Ubuntu.md)
[![Fedora](https://img.shields.io/badge/Fedora-38%2B-blue?logo=fedora)](QuickStart-Fedora.md)
[![Windows 11](https://img.shields.io/badge/Windows-11-success?logo=windows)](QuickStart-Windows.md)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

---

## 📋 Visão Geral

O 9Router funciona como um **proxy local** na porta `20128`, redirecionando as chamadas do Claude CLI para modelos gratuitos disponíveis no OpenRouter, como:

- Gemini 3.1 Flash Lite
- DeepSeek V4 Flash
- Mimo v2.5
- Nemotron 3 Ultra

### Arquitetura

```
Claude CLI → localhost:20128 → 9Router Proxy → OpenRouter API → Modelos Gratuitos
```

---

## 🖥️ Sistemas Suportados

| Sistema | Versão Mínima | Script | Quick Start | Status |
|---------|---------------|--------|-------------|--------|
| Ubuntu | 20.04 LTS | `9-router-ubuntu.sh` | [QuickStart-Ubuntu.md](QuickStart-Ubuntu.md) | ✅ |
| Debian | 11 (Bullseye) | `9-router-ubuntu.sh` | [QuickStart-Ubuntu.md](QuickStart-Ubuntu.md) | ✅ |
| Linux Mint | 20+ | `9-router-ubuntu.sh` | [QuickStart-Ubuntu.md](QuickStart-Ubuntu.md) | ✅ |
| Pop!_OS | 22.04+ | `9-router-ubuntu.sh` | [QuickStart-Ubuntu.md](QuickStart-Ubuntu.md) | ✅ |
| Elementary OS | 6+ | `9-router-ubuntu.sh` | [QuickStart-Ubuntu.md](QuickStart-Ubuntu.md) | ✅ |
| **Fedora (Tradicional)** | 38+ | `9-router-fedora.sh` | [QuickStart-Fedora.md](QuickStart-Fedora.md) | ✅ |
| **Fedora Silverblue** | 38+ | `9-router-fedora.sh` | [QuickStart-Fedora.md](QuickStart-Fedora.md) | ✅ |
| **Fedora Kinoite** | 38+ | `9-router-fedora.sh` | [QuickStart-Fedora.md](QuickStart-Fedora.md) | ✅ |
| **Fedora COSMIC** | 38+ | `9-router-fedora.sh` | [QuickStart-Fedora.md](QuickStart-Fedora.md) | ✅ |
| **Windows 11** | 22H2+ | `9-router-windows.ps1` | [QuickStart-Windows.md](QuickStart-Windows.md) | ✅ |
| Windows 10 | 22H2+ | `9-router-windows.ps1` | [QuickStart-Windows.md](QuickStart-Windows.md) | ✅ |

---

## ⚡ Pré-requisitos

- **Sistema:** Ubuntu/Debian, Fedora ou Windows 11
- **Internet:** Conexão ativa para download de dependências
- **Conta:** [OpenRouter](https://openrouter.ai) com API key ativa
- **Runtime:** [Bun](https://bun.sh) (instalado automaticamente pelo script)

---

## 🚀 Instalação

### Escolha sua plataforma:

<table>
<tr>
<th width="33%">Ubuntu / Debian</th>
<th width="33%">Fedora / Imutável</th>
<th width="33%">Windows 11</th>
</tr>
<tr>
<td>

```bash
# Linux (Ubuntu/Debian)
git clone https://github.com/RafaelBatistaDev/Claude_Code-free-9router.git
cd Claude_Code-free-9router

chmod +x 9-router-ubuntu.sh
./9-router-ubuntu.sh --install

nano ~/.config/secrets.env
```

</td>
<td>

```bash
# Linux (Fedora)
git clone https://github.com/RafaelBatistaDev/Claude_Code-free-9router.git
cd Claude_Code-free-9router

chmod +x 9-router-fedora.sh
./9-router-fedora.sh --install

nano ~/.config/secrets.env
```

</td>
<td>

```powershell
# Windows 11 PowerShell
git clone https://github.com/RafaelBatistaDev/Claude_Code-free-9router.git
cd Claude_Code-free-9router

Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
.\9-router-windows.ps1 --install

notepad $env:USERPROFILE\.config\secrets.env
```

</td>
</tr>
</table>

> **Nota:** O script instala automaticamente o [Bun](https://bun.sh) caso não esteja disponível.

### O que a instalação faz

1. ✅ Instala o Bun (runtime JavaScript) — se necessário
2. ✅ Copia o script para `~/.local/bin/9router` (Linux) ou `%USERPROFILE%\.local\bin\9router.ps1` (Windows)
3. ✅ Instala o pacote 9router globalmente via Bun
4. ✅ Cria template em `~/.config/secrets.env`
5. ✅ Adiciona Bun ao PATH do shell

---

## ⚙️ Configuração

### 1. Configurar Chaves API

Edite o arquivo de secrets:

```bash
# Linux
nano ~/.config/secrets.env
```

```powershell
# Windows
notepad $env:USERPROFILE\.config\secrets.env
```

Substitua `sua-chave-aqui` pelas suas chaves reais:

```bash
# Claude / Anthropic
export ANTHROPIC_BASE_URL="http://localhost:20128"
export ANTHROPIC_API_KEY="sk-ant-SUA-CHAVE"

# OpenRouter (obrigatório)
export OPENROUTER_API_KEY="sk-or-v1-SUA-CHAVE"
```

### 2. Carregar Variáveis

```bash
# Linux
source ~/.config/secrets.env
```

```powershell
# Windows (adicione ao $PROFILE)
$env:ANTHROPIC_API_KEY = "sk-ant-SUA-CHAVE"
$env:OPENROUTER_API_KEY = "sk-or-v1-SUA-CHAVE"
```

### 3. Configurar Claude CLI (Opcional)

Se usar o Claude CLI oficial, configure o `~/.claude.json`:

```bash
bun -e '
import os from "node:os";
import path from "node:path";

const configPath = path.join(os.homedir(), ".claude.json");
const file = Bun.file(configPath);
const json = await file.json();

json.primaryApiKey = "sk-ant-SUA-CHAVE";
json.openRouterApiKey = "sk-or-v1-SUA-CHAVE";

await Bun.write(configPath, JSON.stringify(json, null, 2));
console.info("✅ Configuração atualizada!");
'
```

---

## 📖 Uso

### Comandos do Script

```bash
# Iniciar servidor
9router

# Porta específica
9router -p 3000

# Modo background (bandeja)
9router --tray

# Sem abrir navegador
9router --no-browser

# Ver logs
9router --log

# Ajuda
9router --help

# Versão
9router --version
```

### Flags Disponíveis

| Flag | Descrição | Padrão |
|------|-----------|--------|
| `-p, --port` | Porta do servidor | `20128` |
| `-H, --host` | Host para bind | `0.0.0.0` |
| `-n, --no-browser` | Não abre navegador | `false` |
| `-l, --log` | Exibe logs | `false` |
| `-t, --tray` | Modo bandeja (background) | `false` |
| `-h, --help` | Mostra ajuda | — |
| `-v, --version` | Mostra versão | — |

---

## 🔧 Gerenciamento

### Atualizar

```bash
# Linux
cd Claude_Code-free-9router
git pull
./9-router-ubuntu.sh --install   # ou 9-router-fedora.sh
```

```powershell
# Windows
cd Claude_Code-free-9router
git pull
.\9-router-windows.ps1 --install
```

### Desinstalar

```bash
# Linux
./9-router-ubuntu.sh --uninstall   # ou 9-router-fedora.sh
```

```powershell
# Windows
.\9-router-windows.ps1 --uninstall
```

A desinstalação remove:
- Script de `~/.local/bin/9router`
- Pacote global 9router
- Diretório `~/.local/share/9router-cli`

> **Nota:** O arquivo `~/.config/secrets.env` NÃO é removido para preservar suas chaves.

---

## 🐛 Troubleshooting

### Linux (Ubuntu/Debian/Fedora)

| Problema | Solução |
|----------|---------|
| Bun não encontrado | `curl -fsSL https://bun.sh/install \| bash` |
| Porta em uso | `lsof -i :20128` / `ss -tlnp \| grep 20128` (Fedora) |
| Permissão negada | `chmod +x ~/.local/bin/9router` |
| PATH ausente | `export PATH="$HOME/.local/bin:$PATH"` |

### Fedora Imutável (Silverblue/Kinoite/COSMIC)

| Problema | Solução |
|----------|---------|
| Instalar pacote | `sudo rpm-ostree install --idempotent curl` |
| Deployment travado | `sudo rpm-ostree rollback` |
| App desktop | Prefira Flatpak: `flatpak install flathub org.app.Name` |
| Desenvolvimento | Use Distrobox: `distrobox create --name dev` |

### Windows 11

| Problema | Solução |
|----------|---------|
| Script não executa | `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned` |
| Bun não encontrado | `winget install Bun.Bun --exact --silent` |
| Porta em uso | `Get-Process -Id (Get-NetTCPConnection -LocalPort 20128).OwningProcess` |
| Firewall bloqueando | `New-NetFirewallRule -DisplayName "9Router" -Direction Inbound -Protocol TCP -LocalPort 20128 -Action Allow` |

---

## 📁 Estrutura do Projeto

```
Claude_Code-free-9router/
├── 9-router-ubuntu.sh       # Script de instalação — Ubuntu/Debian
├── 9-router-fedora.sh       # Script de instalação — Fedora (tradicional + imutável)
├── 9-router-windows.ps1     # Script de instalação — Windows 11
├── QuickStart-Ubuntu.md     # Guia rápido — Ubuntu/Debian
├── QuickStart-Fedora.md     # Guia rápido — Fedora
├── QuickStart-Windows.md    # Guia rápido — Windows 11
├── README.md                # Este arquivo
├── LICENSE                  # Licença MIT
├── CHANGELOG.md             # Histórico de versões
├── .gitignore               # Arquivos ignorados
```

---

## 📚 Documentação por Plataforma

| Plataforma | Script | Guia Rápido |
|------------|--------|-------------|
| Ubuntu / Debian / Mint / Pop!_OS / Elementary | [`9-router-ubuntu.sh`](9-router-ubuntu.sh) | [`QuickStart-Ubuntu.md`](QuickStart-Ubuntu.md) |
| Fedora / Silverblue / Kinoite / COSMIC | [`9-router-fedora.sh`](9-router-fedora.sh) | [`QuickStart-Fedora.md`](QuickStart-Fedora.md) |
| Windows 11 / Windows 10 | [`9-router-windows.ps1`](9-router-windows.ps1) | [`QuickStart-Windows.md`](QuickStart-Windows.md) |

---

## 🤝 Contribuindo

1. Fork o projeto
2. Crie uma branch (`git checkout -b feature/nova-feature`)
3. Commit suas mudanças (`git commit -m 'Adiciona nova feature'`)
4. Push para a branch (`git push origin feature/nova-feature`)
5. Abra um Pull Request

---

## 📄 Licença

Este projeto está licenciado sob a MIT License — veja o arquivo [LICENSE](LICENSE) para detalhes.

---

## 🔗 Links Úteis

- [OpenRouter](https://openrouter.ai) — API de modelos gratuitos
- [Bun](https://bun.sh) — Runtime JavaScript
- [Claude CLI](https://docs.anthropic.com/claude/docs/cli) — Documentação oficial
- [Fedora docs](https://docs.fedoraproject.org) — Documentação Fedora
- [Windows Terminal](https://github.com/microsoft/terminal) — Terminal moderno para Windows

---

**Feito com ❤️ para a comunidade — Linux & Windows**
