from fastapi import APIRouter, Query

from ..repositories import tratamento_repo

router = APIRouter(prefix="/lembretes", tags=["lembretes"])


@router.get("/")
async def listar_lembretes(usuario_id: int | None = Query(None, description="ID do usuário logado")):
    return await tratamento_repo.listar_lembretes(usuario_id)
