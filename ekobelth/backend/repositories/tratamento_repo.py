import logging

from .. import database

logger = logging.getLogger("ekobelth.repo")


def _filtro_usuario(usuario_id: int | None, prefixo: str = "WHERE") -> tuple[str, tuple]:
    """Monta o trecho SQL que limita os registros ao usuário logado (se informado)."""
    if usuario_id is None:
        return "", ()
    return f" {prefixo} usuario_id = %s", (usuario_id,)


async def criar(dados: dict, usuario_id: int | None = None) -> dict:
    """Insere um tratamento e retorna o registro criado."""
    query = (
        "INSERT INTO tratamentos "
        "(paciente, medicamento, via, dose, frequencia, inicio, fim, obs, usuario_id) "
        "VALUES (%(paciente)s, %(medicamento)s, %(via)s, %(dose)s, "
        "%(frequencia)s, %(inicio)s, %(fim)s, %(obs)s, %(usuario_id)s)"
    )
    params = dict(dados)
    params["usuario_id"] = usuario_id
    async with database.db_pool.acquire() as conexao:
        async with conexao.cursor() as cursor:
            await cursor.execute(query, params)
            novo_id = cursor.lastrowid
            await cursor.execute(
                "SELECT * FROM tratamentos WHERE id = %s", (novo_id,)
            )
            logger.info(
                "Tratamento criado: id=%d paciente=%s usuario=%s",
                novo_id, dados["paciente"], usuario_id,
            )
            return await cursor.fetchone()


async def atualizar(tratamento_id: int, dados: dict, usuario_id: int | None = None) -> dict | None:
    """Atualiza um tratamento. Retorna o registro atualizado ou None se não encontrado."""
    filtro, filtro_params = _filtro_usuario(usuario_id, "AND")
    query = (
        "UPDATE tratamentos SET "
        "paciente = %(paciente)s, medicamento = %(medicamento)s, "
        "via = %(via)s, dose = %(dose)s, frequencia = %(frequencia)s, "
        "inicio = %(inicio)s, fim = %(fim)s, "
        "obs = %(obs)s WHERE id = %(id)s"
    )
    params = dict(dados)
    params["id"] = tratamento_id
    if usuario_id is not None:
        query += " AND usuario_id = %(usuario_id)s"
        params["usuario_id"] = usuario_id

    async with database.db_pool.acquire() as conexao:
        async with conexao.cursor() as cursor:
            await cursor.execute(query, params)
            await cursor.execute(
                "SELECT * FROM tratamentos WHERE id = %s" + filtro,
                (tratamento_id, *filtro_params),
            )
            resultado = await cursor.fetchone()
            if not resultado:
                return None
            logger.info("Tratamento atualizado: id=%d", tratamento_id)
            return resultado


async def deletar(tratamento_id: int, usuario_id: int | None = None) -> bool:
    """Remove um tratamento. Retorna True se removeu, False se não encontrou."""
    filtro, filtro_params = _filtro_usuario(usuario_id, "AND")
    async with database.db_pool.acquire() as conexao:
        async with conexao.cursor() as cursor:
            await cursor.execute(
                "DELETE FROM tratamentos WHERE id = %s" + filtro,
                (tratamento_id, *filtro_params),
            )
            if cursor.rowcount == 0:
                return False
            logger.info("Tratamento deletado: id=%d", tratamento_id)
            return True


async def buscar_por_id(tratamento_id: int, usuario_id: int | None = None) -> dict | None:
    """Busca um tratamento pelo ID. Retorna None se não encontrado."""
    filtro, filtro_params = _filtro_usuario(usuario_id, "AND")
    async with database.db_pool.acquire() as conexao:
        async with conexao.cursor() as cursor:
            await cursor.execute(
                "SELECT * FROM tratamentos WHERE id = %s" + filtro,
                (tratamento_id, *filtro_params),
            )
            return await cursor.fetchone()


async def listar_todos(usuario_id: int | None = None, limite: int | None = None) -> list[dict]:
    """Lista todos os tratamentos (do usuário, se informado) ordenados por início.

    `limite` (opcional) restringe a quantidade de linhas lidas do banco.
    """
    filtro, filtro_params = _filtro_usuario(usuario_id)
    sql = "SELECT * FROM tratamentos" + filtro + " ORDER BY inicio ASC"
    if limite is not None:
        sql += " LIMIT %s"
        filtro_params = (*filtro_params, int(limite))
    async with database.db_pool.acquire() as conexao:
        async with conexao.cursor() as cursor:
            await cursor.execute(sql, filtro_params)
            return await cursor.fetchall()


async def listar_lembretes(usuario_id: int | None = None) -> list[dict]:
    """Lista tratamentos com data de início definida (lembretes)."""
    filtro, filtro_params = _filtro_usuario(usuario_id, "AND")
    async with database.db_pool.acquire() as conexao:
        async with conexao.cursor() as cursor:
            await cursor.execute(
                "SELECT * FROM tratamentos WHERE inicio <> ''" + filtro + " ORDER BY inicio",
                filtro_params,
            )
            return await cursor.fetchall()
