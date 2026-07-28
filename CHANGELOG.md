# Changelog

Todas as mudanças notáveis neste projeto serão documentadas neste arquivo.

O formato é baseado no [Keep a Changelog](https://keepachangelog.com/pt-BR/1.0.0/),
e este projeto adere ao [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-07-28

### Adicionado

- Script de instalação para **Ubuntu/Debian** (`9-router-ubuntu.sh`)
  - Instalação automática do Bun runtime
  - Criação de template de secrets (`~/.config/secrets.env`)
  - Detecção de sistema operacional com validação de distribuição
  - Suporte a Ubuntu 20.04+, Debian 11+, Mint, Pop!_OS e Elementary OS

- Script de instalação para **Fedora** (`9-router-fedora.sh`)
  - Detecção automática de Fedora Tradicional (dnf) vs Imutável (rpm-ostree)
  - Suporte a Silverblue, Kinoite e COSMIC
  - Mesmas funcionalidades do script Ubuntu

- Script de instalação para **Windows** (`9-router-windows.ps1`)
  - Instalação via PowerShell com suporte a winget
  - Criação de atalho `.cmd` para execução direta
  - Configuração de PATH do usuário
  - Aplicação de permissões restritas ao secrets.env

- Documentação completa para todas as plataformas
  - README com visão geral, pré-requisitos e instruções
  - QuickStarts específicos por plataforma
  - Tabelas de troubleshooting
  - Badges de compatibilidade

### Melhorias

- Proxy local redireciona chamadas do Claude CLI para modelos gratuitos via OpenRouter
- Arquitetura simples: Claude CLI → localhost:20128 → 9Router → OpenRouter
- Suporte aos modelos: Gemini 3.1 Flash Lite, DeepSeek V4 Flash, Mimo v2.5, Nemotron 3 Ultra
- Modo bandeja (background) para execução silenciosa
- Templates de configuração para Anthropic, OpenRouter, Google/Gemini e OpenAI
