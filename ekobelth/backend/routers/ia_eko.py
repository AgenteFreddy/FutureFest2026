import json
import logging
from contextlib import asynccontextmanager

import httpx
from fastapi import APIRouter, Request, HTTPException, WebSocket, WebSocketDisconnect
from fastapi.responses import StreamingResponse

from ..config import OLLAMA_BASE_URL, MODELO_PADRAO, OLLAMA_TIMEOUT
from .. import database
from ..services.ia_context import montar_mensagens

logger = logging.getLogger("ia_eko")

router = APIRouter(tags=["ia_eko"])

# Cliente HTTP único para o Ollama: reaproveita conexões (keep-alive)
# em vez de abrir uma nova a cada mensagem.
_cliente_ollama: httpx.AsyncClient | None = None


def _obter_cliente() -> httpx.AsyncClient:
    global _cliente_ollama
    if _cliente_ollama is None or _cliente_ollama.is_closed:
        _cliente_ollama = httpx.AsyncClient()
    return _cliente_ollama


async def fechar_cliente_ollama() -> None:
    """Fecha o cliente compartilhado (chamado no shutdown da API)."""
    global _cliente_ollama
    if _cliente_ollama is not None:
        await _cliente_ollama.aclose()
        _cliente_ollama = None


@asynccontextmanager
async def _ollama_client():
    """Entrega o cliente compartilhado sem fechá-lo ao final do bloco."""
    yield _obter_cliente()


def _usuario_id(body: dict) -> int | None:
    """Lê o id do usuário logado enviado pelo app (usado para filtrar os dados da IA)."""
    try:
        valor = body.get("usuario_id")
        return int(valor) if valor is not None else None
    except (TypeError, ValueError):
        return None


@router.get("/health")
async def health():
    status = {"ollama": "ok", "database": "ok"}
    try:
        async with _ollama_client() as client:
            resp = await client.get(f"{OLLAMA_BASE_URL}/api/tags", timeout=5)
            resp.raise_for_status()
    except Exception as e:
        status["ollama"] = f"erro: {e}"

    try:
        if not database.db_pool:
            status["database"] = "erro: pool nao inicializado"
        else:
            async with database.db_pool.acquire() as conexao:
                async with conexao.cursor() as cursor:
                    await cursor.execute("SELECT COUNT(*) as total FROM tratamentos")
                    resultado = await cursor.fetchone()
                    status["tratamentos"] = resultado["total"]
    except Exception as e:
        status["database"] = f"erro: {e}"

    ok = status["ollama"] == "ok" and status["database"] == "ok"
    if not ok:
        raise HTTPException(status_code=503, detail=status)
    return {"status": "ok", **status}


@router.post("/chat")
async def chat(request: Request):
    body = await request.json()
    mensagem = body.get("mensagem", "").strip()
    historico = body.get("historico", [])

    if not mensagem:
        raise HTTPException(status_code=400, detail="Mensagem vazia.")
    if len(mensagem) > 2000:
        raise HTTPException(status_code=400, detail="Mensagem muito longa (max. 2000 caracteres).")

    messages = await montar_mensagens(mensagem, historico, _usuario_id(body))
    payload = {"model": MODELO_PADRAO, "messages": messages, "stream": False, "options": {"num_predict": 200, "temperature": 0.0}}

    logger.info("Chat: modelo=%s mensagem='%s...'", MODELO_PADRAO, mensagem[:50])
    try:
        async with _ollama_client() as client:
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


@router.post("/chat/stream")
async def chat_stream(request: Request):
    body = await request.json()
    mensagem = body.get("mensagem", "").strip()
    historico = body.get("historico", [])

    if not mensagem:
        raise HTTPException(status_code=400, detail="Mensagem vazia.")
    if len(mensagem) > 2000:
        raise HTTPException(status_code=400, detail="Mensagem muito longa (max. 2000 caracteres).")

    messages = await montar_mensagens(mensagem, historico, _usuario_id(body))
    payload = {"model": MODELO_PADRAO, "messages": messages, "stream": True, "options": {"num_predict": 200, "temperature": 0.0}}

    async def gerar_tokens():
        async with _ollama_client() as client:
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


@router.websocket("/ws/chat")
async def websocket_chat(websocket: WebSocket):
    await websocket.accept()
    try:
        while True:
            data = await websocket.receive_text()
            try:
                body = json.loads(data)
                mensagem = body.get("mensagem", "").strip()
                historico = body.get("historico", [])

                if not mensagem:
                    await websocket.send_text(json.dumps({"error": "Mensagem vazia."}))
                    continue

                messages = await montar_mensagens(mensagem, historico, _usuario_id(body))
                payload = {"model": MODELO_PADRAO, "messages": messages, "stream": True, "options": {"num_predict": 200, "temperature": 0.0}}

                try:
                    async with _ollama_client() as client:
                        async with client.stream("POST", f"{OLLAMA_BASE_URL}/api/chat", json=payload, timeout=OLLAMA_TIMEOUT) as resp:
                            async for line in resp.aiter_lines():
                                if not line.strip():
                                    continue
                                try:
                                    chunk = json.loads(line)
                                    token = chunk.get("message", {}).get("content", "")
                                    if token:
                                        await websocket.send_text(json.dumps({"token": token}))
                                except json.JSONDecodeError:
                                    continue
                    await websocket.send_text(json.dumps({"done": True}))
                except httpx.TimeoutException:
                    logger.warning("Timeout ao comunicar com Ollama via WS")
                    await websocket.send_text(json.dumps({"error": "Ollama demorou demais para responder."}))
                except httpx.HTTPError as e:
                    logger.error("Erro Ollama WS: %s", e)
                    await websocket.send_text(json.dumps({"error": "Erro ao comunicar com Ollama."}))

            except json.JSONDecodeError:
                await websocket.send_text(json.dumps({"error": "Formato JSON invalido."}))
    except WebSocketDisconnect:
        logger.info("Cliente WebSocket desconectado")
