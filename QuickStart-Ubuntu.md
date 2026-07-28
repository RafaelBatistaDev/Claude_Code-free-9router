# 🚀 Quick Start — 9Router CLI (Ubuntu/Debian)

## Pré-requisitos

- Ubuntu 20.04+ / Debian 11+ (ou derivados: Mint, Pop!_OS, Elementary)
- Conexão com internet
- Conta no [OpenRouter](https://openrouter.ai) com API key

---

## 1. Instalação

```bash
# Clonar o repositório
git clone https://github.com/RafaelBatistaDev/Claude_Code-free-9router.git
cd Claude_Code-free-9router

# Tornar o script executável e instalar
chmod +x 9-router-ubuntu.sh
./9-router-ubuntu.sh --install
```

> O script instala automaticamente o **Bun** (runtime JavaScript) caso não esteja presente.

---

## 2. Configurar API Keys

### Opção A — Editar manualmente

```bash
nano ~/.config/secrets.env
```

Substitua `sua-chave-aqui` pelas suas chaves reais.

### Opção B — Via sed (substitua pelos valores reais)

```bash
# OpenRouter API Key
sed -i 's|"openRouterApiKey": "[^"]*"|"openRouterApiKey": "sk-or-v1-SUA-CHAVE-AQUI"|g' ~/.claude.json

# Anthropic API Key
sed -i 's|"primaryApiKey": "[^"]*"|"primaryApiKey": "sk-ant-SUA-CHAVE-AQUI"|g' ~/.claude.json

# Secrets env
sed -i 's|^export ANTHROPIC_API_KEY=.*|export ANTHROPIC_API_KEY="sk-ant-SUA-CHAVE-AQUI"|g' ~/.config/secrets.env
```

### Opção C — Via Bun (configuração completa)

```bash
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

## 3. Carregar Variáveis de Ambiente

```bash
source ~/.config/secrets.env
```

> Adicione ao `~/.bashrc` para carregar automaticamente:
> ```bash
> echo 'source ~/.config/secrets.env' >> ~/.bashrc
> ```

---

## 4. Verificar Instalação

```bash
# Verificar versão
9router --version

# Mostrar ajuda completa
9router --help

# Verificar configuração
cat ~/.claude.json
cat ~/.config/secrets.env
```

---

## 5. Executar

```bash
# Iniciar servidor na porta padrão (20128)
9router

# Iniciar em porta específica
9router -p 3000

# Modo background (bandeja)
9router --tray

# Sem abrir navegador
9router --no-browser
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

```bash
./9-router-ubuntu.sh --uninstall
```

---

## Troubleshooting

### "Bun não encontrado"
```bash
curl -fsSL https://bun.sh/install | bash
source ~/.bashrc
```

### "Porta já em uso"
```bash
# Verificar processo na porta
lsof -i :20128
# Matar processo
kill -9 <PID>
# Ou usar outra porta
9router -p 3000
```

### "Permissão negada"
```bash
chmod +x 9-router-ubuntu.sh
chmod +x ~/.local/bin/9router
```

### PATH não configurado
```bash
# Adicionar ao ~/.bashrc
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```
