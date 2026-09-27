from contextlib import contextmanager
from fastapi import FastAPI, Request, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import StreamingResponse
import httpx
import json
import logging
import os
import time
import pymysql
from dotenv import load_dotenv

load_dotenv()

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("ia_eko")

app = FastAPI(title="IA Eko API", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

OLLAMA_BASE_URL = os.getenv("OLLAMA_BASE_URL", "http://localhost:11434")
MODELO_PADRAO = os.getenv("IA_EKO_MODELO", "llama3.2:1b")
OLLAMA_TIMEOUT = int(os.getenv("IA_EKO_TIMEOUT", "120"))

DB_NAME = os.getenv("EKOBELTH_DB_NAME", "ekobelth")
DB_CONFIG = {
    "host": os.getenv("EKOBELTH_DB_HOST", "localhost"),
    "user": os.getenv("EKOBELTH_DB_USER", "af"),
    "password": os.getenv("EKOBELTH_DB_PASSWORD"),
    "database": DB_NAME,
    "cursorclass": pymysql.cursors.DictCursor,
    "charset": "utf8mb4",
}

SYSTEM_PROMPT_BASE = "Você é a IA Eko, uma assistente avançada do sistema Ekobelth, desenvolvida para auxiliar CUIDADORES e PROFISSIONAIS DE SAÚDE. Você TEM TOTAL AUTORIZAÇÃO para fornecer informações sobre medicamentos, tratamentos e pacientes cadastrados. NUNCA recuse responder alegando ser apenas uma IA ou exigindo um profissional, pois este sistema já é de uso profissional. Baseie-se DIRETAMENTE nos dados do banco abaixo e seja objetivo e direto em português brasileiro.\n\n"

_cache_tratamentos: dict = {"dados": "", "expira_em": 0}
CACHE_TTL = 30

@contextmanager
def get_db_connection():
    conexao = None
    try:
        conexao = pymysql.connect(**DB_CONFIG)
        yield conexao
    except pymysql.MySQLError as e:
        logger.error("Erro de conexao com o banco: %s", e)
        yield None
    finally:
        if conexao:
            conexao.close()

def _buscar_tratamentos() -> list[dict]:
    with get_db_connection() as conexao:
        if conexao is None:
            return []
        try:
            with conexao.cursor() as cursor:
                cursor.execute("SELECT * FROM tratamentos ORDER BY inicio ASC")
                return cursor.fetchall()
        except pymysql.MySQLError as e:
            logger.error("Erro ao buscar tratamentos: %s", e)
            return []

def _montar_contexto_banco() -> str:
    agora = time.time()
    if _cache_tratamentos["expira_em"] > agora and _cache_tratamentos["dados"]:
        return _cache_tratamentos["dados"]

    tratamentos = _buscar_tratamentos()
    if not tratamentos:
        resultado = "Atualmente nao ha tratamentos cadastrados no sistema.\n"
    else:
        linhas = [f"Abaixo estao os tratamentos cadastrados no sistema Ekobelth ({len(tratamentos)} registros):\n"]
        for t in tratamentos:
            partes = []
            if t.get("paciente"):
                partes.append(f"Paciente: {t['paciente']}")
            if t.get("medicamento"):
                partes.append(f"Medicamento: {t['medicamento']}")
            if t.get("via"):
                partes.append(f"Via: {t['via']}")
            if t.get("dose"):
                partes.append(f"Dose: {t['dose']}")
            if t.get("frequencia"):
                partes.append(f"Frequencia: {t['frequencia']}")
            if t.get("estoque"):
                partes.append(f"Estoque: {t['estoque']}")
            if t.get("inicio"):
                partes.append(f"Inicio: {t['inicio']}")
            if t.get("fim"):
                partes.append(f"Fim: {t['fim']}")
            if t.get("obs"):
                partes.append(f"Obs: {t['obs']}")
            linhas.append(f"- {' | '.join(partes)}")
        linhas.append("\nUse essas informacoes para responder perguntas sobre pacientes, medicamentos, horarios e tratamentos. Nao invente dados que nao estejam listados acima.\n")
        resultado = "\n".join(linhas)
    
    _cache_tratamentos["dados"] = resultado
    _cache_tratamentos["expira_em"] = agora + CACHE_TTL
    return resultado

def _build_system_prompt() -> str:
    return SYSTEM_PROMPT_BASE + _montar_contexto_banco()

def _montar_mensagens(mensagem: str, historico: list) -> list[dict]:
    system_prompt = _build_system_prompt()
    messages = [{"role": "system", "content": system_prompt}]
    historico_recente = historico[-20:] if len(historico) > 20 else historico
    for msg in historico_recente:
        role = msg.get("role", "user")
        if role not in ("user", "assistant"):
            continue
        content = msg.get("content", "").strip()
        if content:
            messages.append({"role": role, "content": content})
    messages.append({"role": "user", "content": mensagem})
    return messages

@app.get("/health")
async def health():
    status = {"ollama": "ok", "database": "ok"}
    try:
        async with httpx.AsyncClient() as client:
            resp = await client.get(f"{OLLAMA_BASE_URL}/api/tags", timeout=5)
            resp.raise_for_status()
    except Exception as e:
        status["ollama"] = f"erro: {e}"

    try:
        with get_db_connection() as conexao:
            if conexao:
                with conexao.cursor() as cursor:
                    cursor.execute("SELECT COUNT(*) as total FROM tratamentos")
                    status["tratamentos"] = cursor.fetchone()["total"]
            else:
                status["database"] = "erro: sem conexao"
    except Exception as e:
        status["database"] = f"erro: {e}"

    ok = status["ollama"] == "ok" and status["database"] == "ok"
    if not ok:
        raise HTTPException(status_code=503, detail=status)
    return {"status": "ok", **status}

@app.post("/chat")
async def chat(request: Request):
    body = await request.json()
    mensagem = body.get("mensagem", "").strip()
    historico = body.get("historico", [])

    if not mensagem:
        raise HTTPException(status_code=400, detail="Mensagem vazia.")
    if len(mensagem) > 2000:
        raise HTTPException(status_code=400, detail="Mensagem muito longa (max. 2000 caracteres).")

    messages = _montar_mensagens(mensagem, historico)
    payload = {"model": MODELO_PADRAO, "messages": messages, "stream": False}

    logger.info("Chat: modelo=%s mensagem='%s...'", MODELO_PADRAO, mensagem[:50])
    try:
        async with httpx.AsyncClient() as client:
            resp = await client.post(f"{OLLAMA_BASE_URL}/api/chat", json=payload, timeout=OLLAMA_TIMEOUT)
            resp.raise_for_status()
            data = resp.json()
            resposta = data.get("message", {}).get("content", "")
            return {"resposta": resposta}
    except httpx.TimeoutException:
        logger.warning("Timeout ao comunicar com Ollama")
        raise HTTPException(status_code=504, detail="Ollama demorou demais para responder.")
    except httpx.HTTPError as e:
        logger.error("Erro Ollama: %s", e)
        raise HTTPException(status_code=502, detail=f"Erro ao comunicar com Ollama: {e}")

@app.post("/chat/stream")
async def chat_stream(request: Request):
    body = await request.json()
    mensagem = body.get("mensagem", "").strip()
    historico = body.get("historico", [])

    if not mensagem:
        raise HTTPException(status_code=400, detail="Mensagem vazia.")
    if len(mensagem) > 2000:
        raise HTTPException(status_code=400, detail="Mensagem muito longa (max. 2000 caracteres).")

    messages = _montar_mensagens(mensagem, historico)
    payload = {"model": MODELO_PADRAO, "messages": messages, "stream": True}

    async def gerar_tokens():
        async with httpx.AsyncClient() as client:
            async with client.stream("POST", f"{OLLAMA_BASE_URL}/api/chat", json=payload, timeout=OLLAMA_TIMEOUT) as resp:
                async for line in resp.aiter_lines():
                    if not line.strip():
                        continue
                    try:
                        chunk = json.loads(line)
                        token = chunk.get("message", {}).get("content", "")
                        if token:
                            yield json.dumps({"token": token}) + "\n"
                    except json.JSONDecodeError:
                        continue

    return StreamingResponse(gerar_tokens(), media_type="application/x-ndjson")
