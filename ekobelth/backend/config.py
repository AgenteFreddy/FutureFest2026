import os
import re
from dotenv import load_dotenv

load_dotenv()

DB_NAME = os.getenv("EKOBELTH_DB_NAME", "ekobelth")

if not re.fullmatch(r"[A-Za-z0-9_]+", DB_NAME):
    raise RuntimeError("EKOBELTH_DB_NAME deve conter apenas letras, numeros e _")

DB_CONFIG = {
    "host": os.getenv("EKOBELTH_DB_HOST", "localhost"),
    "user": os.getenv("EKOBELTH_DB_USER", "af"),
    "password": os.getenv("EKOBELTH_DB_PASSWORD"),
    "charset": "utf8mb4",
}

OLLAMA_BASE_URL = os.getenv("OLLAMA_BASE_URL", "http://localhost:11434")
MODELO_PADRAO = os.getenv("IA_EKO_MODELO", "qwen2.5:1.5b")
OLLAMA_TIMEOUT = int(os.getenv("IA_EKO_TIMEOUT", "120"))

CREATE_DATABASE_SQL = f"CREATE DATABASE IF NOT EXISTS {DB_NAME} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci"

# ── Autenticação ──
# Usuário administrador criado automaticamente para fins de teste.
ADMIN_EMAIL = os.getenv("EKOBELTH_ADMIN_EMAIL", "admin@admin.com")
ADMIN_SENHA = os.getenv("EKOBELTH_ADMIN_SENHA", "admin")
ADMIN_NOME = os.getenv("EKOBELTH_ADMIN_NOME", "Admin")

CREATE_TABLE_USUARIOS_SQL = (
    "CREATE TABLE IF NOT EXISTS usuarios ("
    "id INT AUTO_INCREMENT PRIMARY KEY, "
    "nome VARCHAR(255) NOT NULL, "
    "email VARCHAR(255) NOT NULL UNIQUE, "
    "senha_hash VARCHAR(255) NOT NULL, "
    "criado_em TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP)"
)

# Tabelas que pertencem a um usuário (ligadas por usuarios.id)
TABELAS_COM_USUARIO = ("tratamentos", "estoque")

CREATE_TABLE_SQL = (
    "CREATE TABLE IF NOT EXISTS tratamentos ("
    "id INT AUTO_INCREMENT PRIMARY KEY, "
    "paciente VARCHAR(255) NOT NULL, "
    "medicamento VARCHAR(255) NOT NULL, "
    "via VARCHAR(100) NOT NULL DEFAULT '', "
    "dose VARCHAR(100) NOT NULL DEFAULT '', "
    "frequencia VARCHAR(100) NOT NULL DEFAULT '', "
    "inicio VARCHAR(20) NOT NULL DEFAULT '', "
    "fim VARCHAR(20) NOT NULL DEFAULT '', "
    "obs TEXT NOT NULL, "
    "criado_em TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP)"
)

CREATE_TABLE_ESTOQUE_SQL = (
    "CREATE TABLE IF NOT EXISTS estoque ("
    "id INT AUTO_INCREMENT PRIMARY KEY, "
    "medicamento VARCHAR(255) NOT NULL, "
    "quantidade VARCHAR(100) NOT NULL DEFAULT '', "
    "via VARCHAR(100) NOT NULL DEFAULT '', "
    "data_validade VARCHAR(50) NOT NULL DEFAULT '', "
    "observacoes TEXT NOT NULL, "
    "criado_em TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP)"
)
