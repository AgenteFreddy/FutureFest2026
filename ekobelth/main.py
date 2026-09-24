from fastapi import FastAPI, Request, HTTPException
from fastapi.middleware.cors import CORSMiddleware
import os
import re
import pymysql
from dotenv import load_dotenv

app = FastAPI(title="Ekobelth API")
#Não apagar notação abaixo
#source .venv/bin/activate
#uvicorn main:app --reload
load_dotenv()
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

DB_NAME = os.getenv("EKOBELTH_DB_NAME", "ekobelth")

if not re.fullmatch(r"[A-Za-z0-9_]+", DB_NAME):
    raise RuntimeError("EKOBELTH_DB_NAME deve conter apenas letras, números e _")

DB_CONFIG = {
    "host": "localhost",
    "user": "af",
    "password": os.getenv("EKOBELTH_DB_PASSWORD"),
    "cursorclass": pymysql.cursors.DictCursor,
}

CREATE_DATABASE_SQL = f"""
CREATE DATABASE IF NOT EXISTS {DB_NAME}
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci
"""

CREATE_TABLE_SQL = """
CREATE TABLE IF NOT EXISTS tratamentos (
  id INT AUTO_INCREMENT PRIMARY KEY,
  paciente VARCHAR(255) NOT NULL,
  medicamento VARCHAR(255) NOT NULL,
  via VARCHAR(100) NOT NULL DEFAULT '',
  dose VARCHAR(100) NOT NULL DEFAULT '',
  frequencia VARCHAR(100) NOT NULL DEFAULT '',
  estoque VARCHAR(50) NOT NULL DEFAULT '',
  inicio VARCHAR(20) NOT NULL DEFAULT '',
  fim VARCHAR(20) NOT NULL DEFAULT '',
  obs TEXT NOT NULL,
  criado_em TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
)
"""

def get_db_connection(database=True):
    try:
        config = DB_CONFIG.copy()
        if database:
            config["database"] = DB_NAME
        return pymysql.connect(**config)
    except pymysql.MySQLError as e:
        raise HTTPException(status_code=500, detail=f"Erro de conexão com o banco: {e}")

@app.on_event("startup")
def preparar_banco():
    conexao = get_db_connection(database=False)
    try:
        with conexao.cursor() as cursor:
            cursor.execute(CREATE_DATABASE_SQL)
            cursor.execute(f"USE {DB_NAME}")
            cursor.execute(CREATE_TABLE_SQL)
            conexao.commit()
    except pymysql.MySQLError as e:
        raise RuntimeError(f"Erro ao preparar banco de dados: {e}")
    finally:
        conexao.close()

@app.post("/tratamentos/")
async def criar_tratamento(request: Request):
    dados = await request.json()

    query = """
        INSERT INTO tratamentos
        (paciente, medicamento, via, dose, frequencia, estoque, inicio, fim, obs)
        VALUES (%(paciente)s, %(medicamento)s, %(via)s, %(dose)s, %(frequencia)s, %(estoque)s, %(inicio)s, %(fim)s, %(obs)s)
    """

    conexao = get_db_connection()
    try:
        with conexao.cursor() as cursor:
            cursor.execute(query, dados)
            conexao.commit()
            novo_id = cursor.lastrowid

            cursor.execute("SELECT * FROM tratamentos WHERE id = %s", (novo_id,))
            return cursor.fetchone()
    except pymysql.MySQLError as e:
        conexao.rollback()
        raise HTTPException(status_code=400, detail=f"Erro ao inserir no banco: {e}")
    finally:
        conexao.close()

@app.put("/tratamentos/{tratamento_id}")
async def atualizar_tratamento(tratamento_id: int, request: Request):
    dados = await request.json()

    query = """
        UPDATE tratamentos
        SET paciente = %(paciente)s,
            medicamento = %(medicamento)s,
            via = %(via)s,
            dose = %(dose)s,
            frequencia = %(frequencia)s,
            estoque = %(estoque)s,
            inicio = %(inicio)s,
            fim = %(fim)s,
            obs = %(obs)s
        WHERE id = %(id)s
    """
    dados["id"] = tratamento_id

    conexao = get_db_connection()
    try:
        with conexao.cursor() as cursor:
            cursor.execute(query, dados)
            if cursor.rowcount == 0:
                raise HTTPException(status_code=404, detail="Tratamento não encontrado")
            conexao.commit()

            cursor.execute("SELECT * FROM tratamentos WHERE id = %s", (tratamento_id,))
            return cursor.fetchone()
    except HTTPException:
        conexao.rollback()
        raise
    except pymysql.MySQLError as e:
        conexao.rollback()
        raise HTTPException(status_code=400, detail=f"Erro ao atualizar no banco: {e}")
    finally:
        conexao.close()

@app.get("/tratamentos/")
def listar_tratamentos():
    conexao = get_db_connection()
    try:
        with conexao.cursor() as cursor:
            cursor.execute("SELECT * FROM tratamentos")
            return cursor.fetchall()
    finally:
        conexao.close()

@app.get("/lembretes/")
def listar_lembretes():
    conexao = get_db_connection()
    try:
        with conexao.cursor() as cursor:
            cursor.execute("SELECT * FROM tratamentos WHERE inicio <> '' ORDER BY inicio")
            return cursor.fetchall()
    finally:
        conexao.close()
