import logging
from .. import database

logger = logging.getLogger("ekobelth.repo.estoque")


def _filtro_usuario(usuario_id: int | None, prefixo: str = "WHERE") -> tuple[str, tuple]:
    """Monta o trecho SQL que limita os registros ao usuário logado (se informado)."""
    if usuario_id is None:
        return "", ()
    return f" {prefixo} usuario_id = %s", (usuario_id,)


async def criar(dados: dict, usuario_id: int | None = None) -> dict:
    """Insere um item no estoque e retorna o registro criado."""
    query = (
        "INSERT INTO estoque (medicamento, quantidade, via, data_validade, observacoes, usuario_id) "
        "VALUES (%(medicamento)s, %(quantidade)s, %(via)s, %(data_validade)s, %(observacoes)s, %(usuario_id)s)"
    )
    # Ensure default values are present to prevent KeyError
    dados.setdefault("medicamento", "")
    dados.setdefault("quantidade", "")
    dados.setdefault("via", "")
    dados.setdefault("data_validade", "")
    dados.setdefault("observacoes", "")
    dados["usuario_id"] = usuario_id

    async with database.db_pool.acquire() as conexao:
        async with conexao.cursor() as cursor:
            await cursor.execute(query, dados)
            novo_id = cursor.lastrowid
            await cursor.execute("SELECT * FROM estoque WHERE id = %s", (novo_id,))
            logger.info("Estoque criado: id=%d medicamento=%s usuario=%s", novo_id, dados["medicamento"], usuario_id)
            return await cursor.fetchone()


async def atualizar(item_id: int, dados: dict, usuario_id: int | None = None) -> dict | None:
    """Atualiza um item no estoque. Retorna o registro atualizado ou None se não encontrado."""
    filtro, filtro_params = _filtro_usuario(usuario_id, "AND")
    query = (
        "UPDATE estoque SET "
        "medicamento = %(medicamento)s, quantidade = %(quantidade)s, "
        "via = %(via)s, data_validade = %(data_validade)s, observacoes = %(observacoes)s "
        "WHERE id = %(id)s"
    )
    params = dict(dados)
    params["id"] = item_id
    params.setdefault("medicamento", "")
    params.setdefault("quantidade", "")
    params.setdefault("via", "")
    params.setdefault("data_validade", "")
    params.setdefault("observacoes", "")
    if usuario_id is not None:
        query += " AND usuario_id = %(usuario_id)s"
        params["usuario_id"] = usuario_id

    async with database.db_pool.acquire() as conexao:
        async with conexao.cursor() as cursor:
            await cursor.execute(query, params)
            await cursor.execute(
                "SELECT * FROM estoque WHERE id = %s" + filtro, (item_id, *filtro_params)
            )
            resultado = await cursor.fetchone()
            if not resultado:
                return None
            logger.info("Estoque atualizado: id=%d", item_id)
            return resultado


async def deletar(item_id: int, usuario_id: int | None = None) -> bool:
    """Remove um item do estoque. Retorna True se removeu, False se não encontrou."""
    filtro, filtro_params = _filtro_usuario(usuario_id, "AND")
    async with database.db_pool.acquire() as conexao:
        async with conexao.cursor() as cursor:
            await cursor.execute(
                "DELETE FROM estoque WHERE id = %s" + filtro, (item_id, *filtro_params)
            )
            if cursor.rowcount == 0:
                return False
            logger.info("Estoque deletado: id=%d", item_id)
            return True


async def buscar_por_id(item_id: int, usuario_id: int | None = None) -> dict | None:
    """Busca um item do estoque pelo ID. Retorna None se não encontrado."""
    filtro, filtro_params = _filtro_usuario(usuario_id, "AND")
    async with database.db_pool.acquire() as conexao:
        async with conexao.cursor() as cursor:
            await cursor.execute(
                "SELECT * FROM estoque WHERE id = %s" + filtro, (item_id, *filtro_params)
            )
            return await cursor.fetchone()


async def listar_todos(usuario_id: int | None = None, limite: int | None = None) -> list[dict]:
    """Lista todos os itens do estoque (do usuário, se informado).

    `limite` (opcional) restringe a quantidade de linhas lidas do banco.
    """
    pool = database.db_pool
    if not pool:
        return []
    filtro, filtro_params = _filtro_usuario(usuario_id)
    sql = "SELECT * FROM estoque" + filtro + " ORDER BY id DESC"
    if limite is not None:
        sql += " LIMIT %s"
        filtro_params = (*filtro_params, int(limite))
    async with pool.acquire() as conexao:
        async with conexao.cursor() as cursor:
            await cursor.execute(sql, filtro_params)
            return await cursor.fetchall()
