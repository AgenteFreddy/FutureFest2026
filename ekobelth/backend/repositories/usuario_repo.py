import logging

from .. import database

logger = logging.getLogger("ekobelth.repo.usuario")

_CAMPOS_PUBLICOS = "id, nome, email, criado_em"


async def buscar_por_email(email: str) -> dict | None:
    """Busca um usuário pelo email (inclui senha_hash, uso interno)."""
    async with database.db_pool.acquire() as conexao:
        async with conexao.cursor() as cursor:
            await cursor.execute(
                "SELECT * FROM usuarios WHERE email = %s", (email.strip().lower(),)
            )
            return await cursor.fetchone()


async def buscar_por_id(usuario_id: int) -> dict | None:
    """Busca os dados públicos de um usuário pelo id."""
    async with database.db_pool.acquire() as conexao:
        async with conexao.cursor() as cursor:
            await cursor.execute(
                f"SELECT {_CAMPOS_PUBLICOS} FROM usuarios WHERE id = %s", (usuario_id,)
            )
            return await cursor.fetchone()


async def criar(nome: str, email: str, senha_hash: str) -> dict:
    """Insere um usuário e retorna seus dados públicos."""
    async with database.db_pool.acquire() as conexao:
        async with conexao.cursor() as cursor:
            await cursor.execute(
                "INSERT INTO usuarios (nome, email, senha_hash) VALUES (%s, %s, %s)",
                (nome.strip(), email.strip().lower(), senha_hash),
            )
            novo_id = cursor.lastrowid
            await cursor.execute(
                f"SELECT {_CAMPOS_PUBLICOS} FROM usuarios WHERE id = %s", (novo_id,)
            )
            logger.info("Usuário criado: id=%d email=%s", novo_id, email)
            return await cursor.fetchone()
