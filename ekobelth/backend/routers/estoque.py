from fastapi import APIRouter, HTTPException, Query, status
from ..schemas.estoque import RemedioEstoqueCreate, RemedioEstoqueResponse
from ..repositories import estoque_repo
import logging

router = APIRouter(prefix="/estoque", tags=["Estoque"])
logger = logging.getLogger("ekobelth.router.estoque")

# id do usuário logado (usuarios.id). Quando informado, os dados ficam restritos a ele.
UsuarioIdQuery = Query(None, description="ID do usuário logado")

@router.get("/", response_model=list[RemedioEstoqueResponse])
async def get_estoque(usuario_id: int | None = UsuarioIdQuery):
    try:
        itens = await estoque_repo.listar_todos(usuario_id)
        return itens
    except Exception as e:
        logger.error("Erro ao listar estoque: %s", e)
        raise HTTPException(status_code=500, detail="Erro interno ao listar estoque")

@router.get("/{item_id}", response_model=RemedioEstoqueResponse)
async def get_estoque_item(item_id: int, usuario_id: int | None = UsuarioIdQuery):
    try:
        item = await estoque_repo.buscar_por_id(item_id, usuario_id)
        if not item:
            raise HTTPException(status_code=404, detail="Item não encontrado")
        return item
    except HTTPException:
        raise
    except Exception as e:
        logger.error("Erro ao buscar item no estoque: %s", e)
        raise HTTPException(status_code=500, detail="Erro interno")

@router.post("/", response_model=RemedioEstoqueResponse, status_code=status.HTTP_201_CREATED)
async def create_estoque_item(item: RemedioEstoqueCreate, usuario_id: int | None = UsuarioIdQuery):
    try:
        novo_item = await estoque_repo.criar(item.model_dump(), usuario_id)
        return novo_item
    except Exception as e:
        logger.error("Erro ao inserir item no estoque: %s", e)
        raise HTTPException(status_code=500, detail="Erro interno ao adicionar ao estoque")

@router.put("/{item_id}", response_model=RemedioEstoqueResponse)
async def update_estoque_item(item_id: int, item: RemedioEstoqueCreate, usuario_id: int | None = UsuarioIdQuery):
    try:
        atualizado = await estoque_repo.atualizar(item_id, item.model_dump(), usuario_id)
        if not atualizado:
            raise HTTPException(status_code=404, detail="Item não encontrado")
        return atualizado
    except HTTPException:
        raise
    except Exception as e:
        logger.error("Erro ao atualizar item: %s", e)
        raise HTTPException(status_code=500, detail="Erro interno")

@router.delete("/{item_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_estoque_item(item_id: int, usuario_id: int | None = UsuarioIdQuery):
    try:
        sucesso = await estoque_repo.deletar(item_id, usuario_id)
        if not sucesso:
            raise HTTPException(status_code=404, detail="Item não encontrado")
        return None
    except HTTPException:
        raise
    except Exception as e:
        logger.error("Erro ao deletar item: %s", e)
        raise HTTPException(status_code=500, detail="Erro interno")
