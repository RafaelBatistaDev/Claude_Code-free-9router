# 🚀 Quick Start — 9Router CLI (Windows 11)

## Pré-requisitos

- Windows 11 (também funciona no Windows 10)
- Terminal (PowerShell ou Windows Terminal recomendado)
- Conexão com internet
- Conta no [OpenRouter](https://openrouter.ai) com API key

---

## 1. Instalação

### Via PowerShell (método direto)

```powershell
# Abrir PowerShell como Administrador (opcional, recomendado na primeira vez)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Clonar o repositório
git clone https://github.com/RafaelBatistaDev/Claude_Code-free-9router.git
cd Claude_Code-free-9router

# Tornar o script executável e instalar
.\9-router-windows.ps1 --install
```

### Via GUI (sem terminal)

1. Baixe e execute o script `9-router-windows.ps1` clicando com o botão direito → "Run with PowerShell"
2. Siga as instruções na tela

### Via winget (Bun)

Se o Bun ainda não está instalado, o script tenta instalá-lo automaticamente:
```powershell
# Instalar Bun via winget manualmente (opcional)
winget install Bun.Bun --exact --silent --accept-package-agreements
```

---

## 2. Configurar API Keys

### Opção A — Editar manualmente

```powershell
notepad $env:USERPROFILE\.config\secrets.env
```

Substitua os valores `sua-chave-aqui` pelas suas chaves reais.

### Opção B — Via PowerShell (substitua pelos valores reais)

```powershell
# OpenRouter API Key
(Get-Content "$env:USERPROFILE\.env\secrets.env") -replace '"openRouterApiKey": "[^"]*"', '"openRouterApiKey": "sk-or-v1-SUA-CHAVE-AQUI"' | Set-Content "$env:USERPROFILE\.env\secrets.env"

# Anthropic API Key
(Get-Content "$env:USERPROFILE\.env\secrets.env") -replace '"primaryApiKey": "[^"]*"', '"primaryApiKey": "sk-ant-SUA-CHAVE-AQUI"' | Set-Content "$env:USERPROFILE\.env\secrets.env"
```

### Opção C — Via Bun (configuração completa)

```powershell
bun -e '
import os from "node:os";
import path from "node:path";

const configPath = path.join(os.homedir(), ".claude.json");
const file = Bun.file(configPath);
const json = await file.json();

json.primaryApiKey = "sk-ant-SUA-CHAVE-AQUI";
json.openRouterApiKey = "sk-or-v1-SUA-CHAVE-AQUI";

if (json.clientDataCacheSlots) {
    for (const key of Object.keys(json.clientDataCacheSlots)) {
        json.clientDataCacheSlots[key].model = "gemini/gemini-3.1-flash-lite-preview";
    }
}

json.additionalModelOptionsCache = [
    { value: "gemini/gemini-3.1-flash-lite-preview", label: "Gemini 3.1 Flash Lite", description: "Fast & lightweight" },
    { value: "oc/deepseek-v4-flash-free", label: "DeepSeek V4 Flash Free", description: "Free reasoning model" },
    { value: "oc/mimo-v2.5-free", label: "Mimo v2.5 Free", description: "Free tier with vision" },
    { value: "oc/nemotron-3-ultra-free", label: "Nemotron 3 Ultra Free", description: "Ultra free tier model" }
];

await Bun.write(configPath, JSON.stringify(json, null, 2));
console.info("✅ Configuração atualizada com sucesso!");
'
```

---

## 3. Carregar Variáveis de Ambiente (PowerShell)

```powershell
# Importar variáveis (PowerShell usa $env: em vez de source)
# Cole o conteúdo de secrets.env no seu perfil:
notepad $PROFILE
```

Adicione ao `$PROFILE` (se não existir, crie-o):
```powershell
$env:ANTHROPIC_BASE_URL = "http://localhost:20128"
$env:ANTHROPIC_API_KEY = "sua-chave-aqui"
$env:OPENROUTER_API_KEY = "sua-chave-aqui"
```

> Execute `mkdir -Force (Split-Path $PROFILE); notepad $PROFILE` para abrir o perfil do PowerShell.

Alternativamente, recarregue o terminal após instalar.

---

## 4. Verificar Instalação

```powershell
# Verificar versão
9router --version

# Mostrar ajuda completa
9router --help

# Verificar configuração
notepad $env:USERPROFILE\.claude.json
notepad $env:USERPROFILE\.config\secrets.env
```

---

## 5. Executar

```powershell
# Iniciar servidor na porta padrão (20128)
9router

# Iniciar em porta específica
9router -p 3000

# Modo background (bandeja)
9router --tray

# Sem abrir navegador
9router --no-browser
```

### Executando como administrador (necessário para porta < 1024)

```powershell
# Para portas privilegiadas, abra o PowerShell como Administrador
Start-Process powershell -Verb RunAs -ArgumentList "-File 9router -p 80"
```

---

## Comandos Úteis

| Comando | Descrição |
|---------|-----------|
| `9router --help` | Mostra ajuda completa |
| `9router --version` | Mostra versão instalada |
| `9router -p 20128` | Inicia na porta 20128 |
| `9router --tray` | Inicia em modo bandeja |
| `9router --log` | Exibe logs do servidor |

---

## Desinstalação

```powershell
.\9-router-windows.ps1 --uninstall
```

---

## Troubleshooting

### "ExecutionPolicy" — Script não executa
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### "Bun não encontrado"
```powershell
# Installer via winget (recomendado)
winget install Bun.Bun --exact --silent --accept-package-agreements

# Ou baixe manualmente de https://bun.sh e adicione ao PATH
```

### "Porta já em uso"
```powershell
# Verificar processo na porta
Get-Process -Id (Get-NetTCPConnection -LocalPort 20128).OwningProcess

# Matar processo
Stop-Process -Id <PID> -Force

# Ou usar outra porta
9router -p 3000
```

### "Permissão negada"
```powershell
# Verificar permissões do diretório
Get-Acl "$env:USERPROFILE\.local\bin"

# Garantir que 9router.ps1 é executável no PowerShell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Se o executável global não está no PATH:
$env:Path = "${env:USERPROFILE}\.local\bin;$env:Path"
```

### PATH não configurado persistentemente
```powershell
# Adicionar permanentemente ao PATH do usuário
$env:Path = [Environment]::GetEnvironmentVariable("Path", "User") + ";${env:USERPROFILE}\.local\bin"
[Environment]::SetEnvironmentVariable("Path", $env:Path, "User")
```

### "Acesso negado ao criar diretório em .local"
```powershell
# Criar a estrutura de diretórios manualmente
New-Item -ItemType Directory -Path "${env:USERPROFILE}\.local\bin" -Force
New-Item -ItemType Directory -Path "${env:USERPROFILE}\.config" -Force
```

### PowerShell version incompatibility
```powershell
# Verificar versão do PowerShell
$PSVersionTable.PSVersion

# O script requer PowerShell 5.1+ (Windows 11 vem com 5.1 e 7+)
```

### Erro de SSL/TLS ao baixar Bun
```powershell
# Forçar TLS 1.2
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
```

---

## Windows 11 — Dicas Específicas

### Windows Terminal (recomendado)
```powershell
# Instalar Windows Terminal via Microsoft Store
winget install Microsoft.WindowsTerminal

# Ou via winget
winget install Microsoft.WindowsTerminal
```

### PowerShell 7+ (opcional, recomendado)
```powershell
winget install Microsoft.PowerShell --exact --silent --accept-package-agreements
```

### Firewall / Portas
O Windows Defender Firewall pode bloquear a porta 20128. Se a conexão falhar:
```powershell
# Criar regra de entrada para a porta
New-NetFirewallRule -DisplayName "9Router Port 20128" -Direction Inbound -Protocol TCP -LocalPort 20128 -Action Allow
```

### Executar como serviço (background)
Para rodar o 9router automaticamente ao iniciar o sistema:
```powershell
# Criar tarefa agendada
$action = New-ScheduledTaskAction -Execute "powershell" -Argument "-ExecutionPolicy Bypass -File '$env:USERPROFILE\.local\bin\9router.ps1'"
$trigger = New-ScheduledTaskTrigger -AtStartup
Register-ScheduledTask -Action $action -Trigger $trigger -TaskName "9Router" -Description "9Router AI Proxy"
```
