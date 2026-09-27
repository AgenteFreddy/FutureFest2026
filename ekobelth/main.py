from contextlib import contextmanager
from fastapi import FastAPI, Request, HTTPException
from fastapi.middleware.cors import CORSMiddleware
import logging
import os
import re
import pymysql
from dotenv import load_dotenv
from pydantic import BaseModel, Field

#Não apagar notação abaixo
#source .venv/bin/activate
#uvicorn main:app --reload

load_dotenv()

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("ekobelth")

app = FastAPI(title="Ekobelth API", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

DB_NAME = os.getenv("EKOBELTH_DB_NAME", "ekobelth")

if not re.fullmatch(r"[A-Za-z0-9_]+", DB_NAME):
    raise RuntimeError("EKOBELTH_DB_NAME deve conter apenas letras, numeros e _")

DB_CONFIG = {
    "host": os.getenv("EKOBELTH_DB_HOST", "localhost"),
    "user": os.getenv("EKOBELTH_DB_USER", "af"),
    "password": os.getenv("EKOBELTH_DB_PASSWORD"),
    "cursorclass": pymysql.cursors.DictCursor,
    "charset": "utf8mb4",
}

CREATE_DATABASE_SQL = f"CREATE DATABASE IF NOT EXISTS {DB_NAME} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci"

CREATE_TABLE_SQL = "CREATE TABLE IF NOT EXISTS tratamentos (id INT AUTO_INCREMENT PRIMARY KEY, paciente VARCHAR(255) NOT NULL, medicamento VARCHAR(255) NOT NULL, via VARCHAR(100) NOT NULL DEFAULT '', dose VARCHAR(100) NOT NULL DEFAULT '', frequencia VARCHAR(100) NOT NULL DEFAULT '', estoque VARCHAR(50) NOT NULL DEFAULT '', inicio VARCHAR(20) NOT NULL DEFAULT '', fim VARCHAR(20) NOT NULL DEFAULT '', obs TEXT NOT NULL, criado_em TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP)"

CAMPOS_TRATAMENTO = {
    "paciente", "medicamento", "via", "dose",
    "frequencia", "estoque", "inicio", "fim", "obs",
}

class TratamentoInput(BaseModel):
    paciente: str = Field(..., min_length=1, max_length=255)
    medicamento: str = Field(..., min_length=1, max_length=255)
    via: str = Field("", max_length=100)
    dose: str = Field("", max_length=100)
    frequencia: str = Field("", max_length=100)
    estoque: str = Field("", max_length=50)
    inicio: str = Field("", max_length=20)
    fim: str = Field("", max_length=20)
    obs: str = Field("")

@contextmanager
def get_db_connection(database: bool = True):
    config = DB_CONFIG.copy()
    if database:
        config["database"] = DB_NAME
    conexao = None
    try:
        conexao = pymysql.connect(**config)
        yield conexao
    except pymysql.MySQLError as e:
        logger.error("Erro de conexao com o banco: %s", e)
        raise HTTPException(status_code=500, detail=f"Erro de conexao com o banco: {e}")
    finally:
        if conexao:
            conexao.close()

@app.on_event("startup")
def preparar_banco():
    with get_db_connection(database=False) as conexao:
        try:
            with conexao.cursor() as cursor:
                cursor.execute(CREATE_DATABASE_SQL)
                cursor.execute(f"USE {DB_NAME}")
                cursor.execute(CREATE_TABLE_SQL)
                conexao.commit()
                logger.info("Banco de dados '%s' pronto.", DB_NAME)
        except pymysql.MySQLError as e:
            raise RuntimeError(f"Erro ao preparar banco de dados: {e}")

@app.post("/tratamentos/", status_code=201)
async def criar_tratamento(dados: TratamentoInput):
    query = "INSERT INTO tratamentos (paciente, medicamento, via, dose, frequencia, estoque, inicio, fim, obs) VALUES (%(paciente)s, %(medicamento)s, %(via)s, %(dose)s, %(frequencia)s, %(estoque)s, %(inicio)s, %(fim)s, %(obs)s)"

    with get_db_connection() as conexao:
        try:
            with conexao.cursor() as cursor:
                cursor.execute(query, dados.model_dump())
                conexao.commit()
                novo_id = cursor.lastrowid
                cursor.execute(
                    "SELECT * FROM tratamentos WHERE id = %s", (novo_id,)
                )
                logger.info("Tratamento criado: id=%d paciente=%s", novo_id, dados.paciente)
                return cursor.fetchone()
        except pymysql.MySQLError as e:
            conexao.rollback()
            logger.error("Erro ao inserir tratamento: %s", e)
            raise HTTPException(status_code=400, detail=f"Erro ao inserir no banco: {e}")

@app.put("/tratamentos/{tratamento_id}")
async def atualizar_tratamento(tratamento_id: int, dados: TratamentoInput):
    query = "UPDATE tratamentos SET paciente = %(paciente)s, medicamento = %(medicamento)s, via = %(via)s, dose = %(dose)s, frequencia = %(frequencia)s, estoque = %(estoque)s, inicio = %(inicio)s, fim = %(fim)s, obs = %(obs)s WHERE id = %(id)s"
    params = dados.model_dump()
    params["id"] = tratamento_id

    with get_db_connection() as conexao:
        try:
            with conexao.cursor() as cursor:
                cursor.execute(query, params)
                if cursor.rowcount == 0:
                    raise HTTPException(
                        status_code=404, detail="Tratamento nao encontrado"
                    )
                conexao.commit()
                cursor.execute(
                    "SELECT * FROM tratamentos WHERE id = %s", (tratamento_id,)
                )
                logger.info("Tratamento atualizado: id=%d", tratamento_id)
                return cursor.fetchone()
        except HTTPException:
            conexao.rollback()
            raise
        except pymysql.MySQLError as e:
            conexao.rollback()
            logger.error("Erro ao atualizar tratamento %d: %s", tratamento_id, e)
            raise HTTPException(
                status_code=400, detail=f"Erro ao atualizar no banco: {e}"
            )

@app.delete("/tratamentos/{tratamento_id}")
async def deletar_tratamento(tratamento_id: int):
    with get_db_connection() as conexao:
        try:
            with conexao.cursor() as cursor:
                cursor.execute(
                    "DELETE FROM tratamentos WHERE id = %s", (tratamento_id,)
                )
                if cursor.rowcount == 0:
                    raise HTTPException(
                        status_code=404, detail="Tratamento nao encontrado"
                    )
                conexao.commit()
                logger.info("Tratamento deletado: id=%d", tratamento_id)
                return {"detail": "Tratamento deletado com sucesso"}
        except HTTPException:
            raise
        except pymysql.MySQLError as e:
            conexao.rollback()
            logger.error("Erro ao deletar tratamento %d: %s", tratamento_id, e)
            raise HTTPException(
                status_code=400, detail=f"Erro ao deletar: {e}"
            )

@app.get("/tratamentos/{tratamento_id}")
def buscar_tratamento(tratamento_id: int):
    with get_db_connection() as conexao:
        with conexao.cursor() as cursor:
            cursor.execute(
                "SELECT * FROM tratamentos WHERE id = %s", (tratamento_id,)
            )
            resultado = cursor.fetchone()
            if not resultado:
                raise HTTPException(
                    status_code=404, detail="Tratamento nao encontrado"
                )
            return resultado

@app.get("/tratamentos/")
def listar_tratamentos():
    with get_db_connection() as conexao:
        with conexao.cursor() as cursor:
            cursor.execute("SELECT * FROM tratamentos ORDER BY inicio ASC")
            return cursor.fetchall()

@app.get("/lembretes/")
def listar_lembretes():
    with get_db_connection() as conexao:
        with conexao.cursor() as cursor:
            cursor.execute(
                "SELECT * FROM tratamentos WHERE inicio <> '' ORDER BY inicio"
            )
            return cursor.fetchall()

@app.get("/health")
def health_check():
    try:
        with get_db_connection() as conexao:
            with conexao.cursor() as cursor:
                cursor.execute("SELECT 1")
        return {"status": "ok", "database": DB_NAME}
    except Exception as e:
        raise HTTPException(status_code=503, detail=f"Banco indisponivel: {e}")
