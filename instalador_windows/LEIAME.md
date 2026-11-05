# 🚀 Ekobelth - Guia de Instalação e Execução para Windows

Este pacote contém o instalador completo, pré-configurações e todos os pacotes necessários para executar a plataforma **Ekobelth** no ambiente Windows.

---

## 📦 O que este instalador contém

```
instalador_windows/
├── instalar.bat                 <- Instalador inteligente (detecta o que já tem e só instala o que falta)
├── instalar.ps1                 <- Instalador alternativo via PowerShell com interface colorida
├── iniciar.bat                  <- Painel de controle interativo para iniciar os serviços
├── iniciar.ps1                  <- Painel de controle interativo em PowerShell
├── verificar_ambiente.bat       <- Diagnóstico: lista tudo o que já está instalado vs ausente
├── verificar_ambiente.ps1       <- Diagnóstico avançado em PowerShell
├── configurar_banco.bat         <- Assistente para testar e criar banco/tabelas no MySQL
├── pacotes/
│   ├── python_wheels/           <- Rodas (.whl) pré-baixadas de todas as dependências Python
│   ├── requirements.txt         <- Lista de dependências Python com versões estáveis
│   ├── database.sql             <- Script SQL completo com tabelas 'usuarios', 'tratamentos' e 'estoque'
│   ├── init_db.py               <- Script Python automatizado para conexão e criação do banco
│   └── .env.template            <- Modelo de variáveis de ambiente pré-configurado
└── scripts/
    ├── run_backend.bat          <- Inicia a API FastAPI principal (Porta 8000)
    ├── run_ia_eko.bat           <- Inicia a API de IA Eko (Porta 8001)
    ├── run_flutter_web.bat      <- Inicia o App no navegador Edge/Chrome (Flutter Web)
    ├── run_flutter_desktop.bat  <- Inicia o App compilado como executável nativo Windows
    ├── run_showcase.bat         <- Inicia o site web de pitch/showcase (Porta 3000)
    └── run_tudo.bat             <- Inicia Backend + IA + App simultaneamente
```

---

## 🔍 Detecção Inteligente do que já está Baixado

O instalador foi programado para **nunca reinstalar ou baixar novamente o que você já possui**:
1. **Python**: Se já estiver instalado no Windows, detecta a versão e não baixa outro.
2. **Ambiente Virtual (`.venv`)**: Se a pasta já existir e contiver os pacotes necessários (`fastapi`, `uvicorn`, `pymysql`, `pydantic`, `cryptography`, etc.), o passo de instalação é **ignorado**.
3. **Instalação Offline**: Se os pacotes Python precisarem ser instalados, o instalador usa as rodas `.whl` já embutidas na pasta `pacotes/python_wheels/`, sem depender de internet.
4. **Flutter SDK e Cache**: Detecta se o Flutter já está configurado no PATH e se as dependências Dart (`.dart_tool`) já estão salvas.
5. **Node.js**: Detecta se `node_modules` já existe no projeto do site showcase (`ekobelth_site`).
6. **Configuração (.env)**: Se você já tiver um arquivo `.env` personalizado, o instalador preserva seu arquivo e não o substitui.

---

## ⚡ Como Instalar (Passo a Passo)

### 1. Execute o Instalador
Dê um duplo clique no arquivo:
👉 **`instalar.bat`**  
*(Ou abra o terminal PowerShell e execute `./instalar.ps1`)*

O script fará a varredura do seu computador e configurará tudo automaticamente.

### 2. Configurar o Banco de Dados MySQL
Certifique-se de que o **MySQL** esteja em execução (por exemplo, via **XAMPP**, **MySQL Workbench/Server** ou **Docker**).
- O arquivo `.env` padrão está configurado para:
  - `Host`: `localhost`
  - `Porta`: `3306`
  - `Usuário`: `root` (ou `af` se configurado)
  - `Senha`: *(vazia por padrão no XAMPP)*
- Você pode rodar o **`configurar_banco.bat`** para testar e criar o banco `ekobelth` e todas as tabelas automaticamente.

---

## 🎮 Como Iniciar as Aplicações

Após a instalação, abra o painel central:
👉 **`iniciar.bat`**

Você verá o seguinte menu:
```
=====================================================================
                     EKOBELTH - PAINEL DE CONTROLE
=====================================================================

  [1] Iniciar TUDO (Backend + IA Eko + App Web) [Recomendado]
  [2] Iniciar apenas Backend FastAPI (Porta 8000)
  [3] Iniciar apenas IA Eko API (Porta 8001)
  [4] Iniciar App Flutter no Navegador (Edge / Chrome)
  [5] Iniciar App Flutter Nativo (Windows Desktop)
  [6] Iniciar Site Showcase / Pitch (Porta 3000)
  [7] Testar e Inicializar Banco de Dados (MySQL)
  [8] Verificar Ambiente e Pacotes Baixados
  [9] Reinstalar / Atualizar Pacotes (instalar.bat)
  [0] Sair
```

### 💡 Recomendações de Execução:
- **Opção 1 (`Iniciar TUDO`)**: Abre o Backend (porta 8000), o serviço de IA (porta 8001) e o App Flutter no navegador (Edge/Chrome). É a forma mais rápida e compatível com qualquer computador Windows.
- **Opção 4 (`App Flutter no Navegador`)**: Não requer Visual Studio C++, roda imediatamente em qualquer navegador moderno.
- **Opção 5 (`App Nativo Windows`)**: Compila um `.exe` desktop. Requer que o Visual Studio com suporte a C++ esteja instalado.

---

## 🛠️ Diagnóstico do Sistema

Para apenas inspecionar o que está baixado e o que falta sem alterar nada:
👉 Execute **`verificar_ambiente.bat`** (ou `verificar_ambiente.ps1`).

---

## ❓ Perguntas Frequentes (FAQ)

### 1. Como usar com o XAMPP?
Abra o **XAMPP Control Panel** e clique em **Start** no módulo **MySQL**. Em seguida, execute `configurar_banco.bat`.

### 2. A IA Eko é obrigatória?
Não. O backend principal e o app Flutter funcionam com 100% dos recursos de login, estoque, tratamentos e lembretes mesmo sem a IA. A IA é um módulo complementar integrado com o Ollama (`llama3.2:1b`). Se quiser usar a IA local, basta instalar o [Ollama para Windows](https://ollama.com/) e executar `ollama run llama3.2:1b`.

### 3. Credenciais padrão de teste:
- **Email**: `admin@admin.com`
- **Senha**: `admin`
- Criadas automaticamente na inicialização da API!
