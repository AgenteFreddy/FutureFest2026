import logging
import pymysql
import aiomysql
from .config import (
    DB_NAME,
    DB_CONFIG,
    CREATE_DATABASE_SQL,
    CREATE_TABLE_SQL,
    CREATE_TABLE_ESTOQUE_SQL,
    CREATE_TABLE_USUARIOS_SQL,
    TABELAS_COM_USUARIO,
    ADMIN_EMAIL,
    ADMIN_SENHA,
    ADMIN_NOME,
)
from .security import hash_senha

logger = logging.getLogger("ekobelth.db")

db_pool = None


def _coluna_existe(cursor, tabela: str, coluna: str) -> bool:
    cursor.execute(
        "SELECT COUNT(*) FROM information_schema.COLUMNS "
        "WHERE TABLE_SCHEMA = %s AND TABLE_NAME = %s AND COLUMN_NAME = %s",
        (DB_NAME, tabela, coluna),
    )
    return cursor.fetchone()[0] > 0


def _adicionar_usuario_id(cursor):
    """Adiciona a coluna usuario_id (FK -> usuarios.id) nas tabelas que ainda não têm."""
    for tabela in TABELAS_COM_USUARIO:
        if _coluna_existe(cursor, tabela, "usuario_id"):
            continue
        cursor.execute(f"ALTER TABLE {tabela} ADD COLUMN usuario_id INT NULL")
        cursor.execute(
            f"ALTER TABLE {tabela} ADD CONSTRAINT fk_{tabela}_usuario "
            f"FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE"
        )
        logger.info("Coluna usuario_id adicionada em '%s'.", tabela)


def _garantir_admin(cursor) -> int:
    """Cria o usuário admin de testes (se não existir) e retorna o id dele."""
    cursor.execute("SELECT id FROM usuarios WHERE email = %s", (ADMIN_EMAIL,))
    linha = cursor.fetchone()
    if linha:
        return linha[0]
    cursor.execute(
        "INSERT INTO usuarios (nome, email, senha_hash) VALUES (%s, %s, %s)",
        (ADMIN_NOME, ADMIN_EMAIL, hash_senha(ADMIN_SENHA)),
    )
    logger.info("Usuário admin de testes criado: %s", ADMIN_EMAIL)
    return cursor.lastrowid


def bootstrap_database():
    try:
        conn = pymysql.connect(**DB_CONFIG)
        with conn.cursor() as cursor:
            cursor.execute(CREATE_DATABASE_SQL)
            conn.commit()
        conn.close()

        conn = pymysql.connect(**DB_CONFIG, database=DB_NAME)
        with conn.cursor() as cursor:
            cursor.execute(CREATE_TABLE_USUARIOS_SQL)
            cursor.execute(CREATE_TABLE_SQL)
            cursor.execute(CREATE_TABLE_ESTOQUE_SQL)
            _adicionar_usuario_id(cursor)
            admin_id = _garantir_admin(cursor)
            # Registros antigos (criados antes do login existir) passam a ser do admin
            for tabela in TABELAS_COM_USUARIO:
                cursor.execute(
                    f"UPDATE {tabela} SET usuario_id = %s WHERE usuario_id IS NULL",
                    (admin_id,),
                )
            conn.commit()
        conn.close()
        logger.info("Banco de dados '%s' preparado.", DB_NAME)
    except pymysql.MySQLError as e:
        logger.error("Erro ao preparar banco de dados: %s", e)



async def create_pool():
    global db_pool
    db_pool = await aiomysql.create_pool(
        host=DB_CONFIG["host"],
        user=DB_CONFIG["user"],
        password=DB_CONFIG["password"],
        db=DB_NAME,
        charset=DB_CONFIG["charset"],
        cursorclass=aiomysql.DictCursor,
        autocommit=True,
        minsize=1,
        maxsize=10,
    )
    logger.info("Pool assíncrono de conexão com banco criado.")


async def close_pool():
    global db_pool
    if db_pool:
        db_pool.close()
        await db_pool.wait_closed()
