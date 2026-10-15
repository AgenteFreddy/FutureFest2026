import asyncio
import logging
import time

from ..repositories import tratamento_repo, estoque_repo

logger = logging.getLogger("ia_eko")

SYSTEM_PROMPT_BASE = """Você é a IA Eko, uma assistente prestativa e gentil do aplicativo Ekobelth para cuidadores.
Sua missão é responder às dúvidas do usuário interpretando os dados de tratamentos e do estoque de remédios fornecidos abaixo.
REGRAS:
1. Responda de forma clara, natural e amigável.
2. Se o usuário pedir informações sobre um paciente ou medicamento que está na lista ou no estoque, forneça os detalhes com base nos dados.
3. Se a informação não estiver na lista, diga educadamente que não encontrou a informação no banco de dados.
4. Responda no idioma Português.
5. Seja proativa: se o usuário perguntar sobre um tratamento, verifique também no estoque se há o medicamento disponível e informe-o. Se o usuário perguntar se o remédio é suficiente, compare a dose/frequência com a quantidade no estoque.

=== DADOS DO BANCO DE DADOS ===
"""

_cache_contexto: dict = {}  # usuario_id -> {"dados": str, "expira_em": float}
CACHE_TTL = 0
LIMITE_CONTEXTO = 50  # máximo de tratamentos/itens de estoque no prompt


async def _montar_contexto_banco(usuario_id: int | None = None) -> str:
    """Monta o contexto com dados de tratamentos e estoque (do usuário logado) para o system prompt, com cache desativado."""
    agora = time.time()
    cache = _cache_contexto.get(usuario_id)
    if CACHE_TTL > 0 and cache and cache["expira_em"] > agora and cache["dados"]:
        return cache["dados"]

    # Busca em paralelo e lê só LIMITE_CONTEXTO + 1 linhas (a linha extra
    # serve apenas para saber se há registros omitidos).
    tratamentos, estoque = await asyncio.gather(
        tratamento_repo.listar_todos(usuario_id, limite=LIMITE_CONTEXTO + 1),
        estoque_repo.listar_todos(usuario_id, limite=LIMITE_CONTEXTO + 1),
    )
    
    # Limitar o contexto para evitar estourar o limite de tokens do LLM
    tratamentos_recentes = tratamentos[:LIMITE_CONTEXTO] if tratamentos else []
    estoque_recente = estoque[:LIMITE_CONTEXTO] if estoque else []
    
    resultado = ""

    if not tratamentos_recentes:
        resultado += "Atualmente não há tratamentos cadastrados no sistema.\n"
    else:
        resultado += "--- TRATAMENTOS EM ANDAMENTO ---\n"
        linhas_t = []
        for t in tratamentos_recentes:
            partes = []
            if t.get("paciente"): partes.append(f"Paciente: {t['paciente']}")
            if t.get("medicamento"): partes.append(f"Medicamento: {t['medicamento']}")
            if t.get("via"): partes.append(f"Via: {t['via']}")
            if t.get("dose"): partes.append(f"Dose: {t['dose']}")
            if t.get("frequencia"): partes.append(f"Frequencia: {t['frequencia']}")
            if t.get("inicio"): partes.append(f"Inicio: {t['inicio']}")
            if t.get("fim"): partes.append(f"Fim: {t['fim']}")
            if t.get("obs"): partes.append(f"Obs: {t['obs']}")
            linhas_t.append(f"- {' | '.join(partes)}")
        if len(tratamentos) > LIMITE_CONTEXTO:
            linhas_t.append("- ... (outros tratamentos omitidos)")
        resultado += "\n".join(linhas_t) + "\n=============================\n"

    if not estoque_recente:
        resultado += "Atualmente não há itens no estoque.\n"
    else:
        resultado += "--- ESTOQUE DE REMÉDIOS ---\n"
        linhas_e = []
        for e in estoque_recente:
            partes = []
            if e.get("medicamento"): partes.append(f"Medicamento: {e['medicamento']}")
            if e.get("quantidade"): partes.append(f"Quantidade: {e['quantidade']}")
            if e.get("via"): partes.append(f"Via: {e['via']}")
            if e.get("data_validade"): partes.append(f"Validade: {e['data_validade']}")
            if e.get("observacoes"): partes.append(f"Obs: {e['observacoes']}")
            linhas_e.append(f"- {' | '.join(partes)}")
        if len(estoque) > LIMITE_CONTEXTO:
            linhas_e.append("- ... (outros itens do estoque omitidos)")
        resultado += "\n".join(linhas_e) + "\n=============================\n"

    _cache_contexto[usuario_id] = {"dados": resultado, "expira_em": agora + CACHE_TTL}
    return resultado


async def build_system_prompt(usuario_id: int | None = None) -> str:
    """Constrói o system prompt completo com dados do banco."""
    contexto = await _montar_contexto_banco(usuario_id)
    return SYSTEM_PROMPT_BASE + contexto



async def montar_mensagens(mensagem: str, historico: list, usuario_id: int | None = None) -> list[dict]:
    """Monta a lista de mensagens para enviar ao Ollama, incluindo system prompt e histórico."""
    system_prompt = await build_system_prompt(usuario_id)
    messages = [{"role": "system", "content": system_prompt}]
    historico_recente = historico[-6:] if len(historico) > 6 else historico
    for msg in historico_recente:
        role = msg.get("role", "user")
        if role not in ("user", "assistant"):
            continue
        content = msg.get("content", "").strip()
        if content:
            messages.append({"role": role, "content": content})
    messages.append({"role": "user", "content": mensagem})
    return messages
