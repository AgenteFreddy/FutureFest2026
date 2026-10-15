import logging

from fastapi import APIRouter, HTTPException, Query

from ..schemas.tratamento import TratamentoInput
from ..repositories import tratamento_repo

logger = logging.getLogger("ekobelth")

router = APIRouter(prefix="/tratamentos", tags=["tratamentos"])

# id do usuário logado (usuarios.id). Quando informado, os dados ficam restritos a ele.
UsuarioIdQuery = Query(None, description="ID do usuário logado")


@router.post("/", status_code=201)
async def criar_tratamento(dados: TratamentoInput, usuario_id: int | None = UsuarioIdQuery):
    try:
        return await tratamento_repo.criar(dados.model_dump(), usuario_id)
    except Exception as e:
        logger.error("Erro ao inserir tratamento: %s", e)
        raise HTTPException(status_code=400, detail=f"Erro ao inserir no banco: {e}")


@router.put("/{tratamento_id}")
async def atualizar_tratamento(
    tratamento_id: int, dados: TratamentoInput, usuario_id: int | None = UsuarioIdQuery
):
    try:
        resultado = await tratamento_repo.atualizar(tratamento_id, dados.model_dump(), usuario_id)
        if resultado is None:
            raise HTTPException(status_code=404, detail="Tratamento nao encontrado")
        return resultado
    except HTTPException:
        raise
    except Exception as e:
        logger.error("Erro ao atualizar tratamento %d: %s", tratamento_id, e)
        raise HTTPException(status_code=400, detail=f"Erro ao atualizar no banco: {e}")


@router.delete("/{tratamento_id}")
async def deletar_tratamento(tratamento_id: int, usuario_id: int | None = UsuarioIdQuery):
    try:
        removido = await tratamento_repo.deletar(tratamento_id, usuario_id)
        if not removido:
            raise HTTPException(status_code=404, detail="Tratamento nao encontrado")
        return {"detail": "Tratamento deletado com sucesso"}
    except HTTPException:
        raise
    except Exception as e:
        logger.error("Erro ao deletar tratamento %d: %s", tratamento_id, e)
        raise HTTPException(status_code=400, detail=f"Erro ao deletar: {e}")


@router.get("/")
async def listar_tratamentos(usuario_id: int | None = UsuarioIdQuery):
    return await tratamento_repo.listar_todos(usuario_id)


@router.get("/{tratamento_id}")
async def buscar_tratamento(tratamento_id: int, usuario_id: int | None = UsuarioIdQuery):
    resultado = await tratamento_repo.buscar_por_id(tratamento_id, usuario_id)
    if not resultado:
        raise HTTPException(status_code=404, detail="Tratamento nao encontrado")
    return resultado
