from fastapi import APIRouter, HTTPException

from ..config import DB_NAME
from .. import database

router = APIRouter(tags=["health"])


@router.get("/health")
async def health_check():
    try:
        if not database.db_pool:
            raise Exception("Pool nao inicializado")
        async with database.db_pool.acquire() as conexao:
            async with conexao.cursor() as cursor:
                await cursor.execute("SELECT 1")
        return {"status": "ok", "database": DB_NAME}
    except Exception as e:
        raise HTTPException(status_code=503, detail=f"Banco indisponivel: {e}")
