"""Cadastra um usuário (apenas dados de autenticação) direto no banco.

Uso:
    source .venv/bin/activate
    python -m backend.criar_usuario "Nome" email@exemplo.com senha
"""
import sys

import pymysql

from .config import DB_CONFIG, DB_NAME
from .database import bootstrap_database
from .security import hash_senha


def main():
    if len(sys.argv) != 4:
        print(__doc__)
        sys.exit(1)

    nome, email, senha = sys.argv[1], sys.argv[2].strip().lower(), sys.argv[3]
    bootstrap_database()  # garante que a tabela usuarios existe

    conn = pymysql.connect(**DB_CONFIG, database=DB_NAME)
    try:
        with conn.cursor() as cursor:
            cursor.execute(
                "INSERT INTO usuarios (nome, email, senha_hash) VALUES (%s, %s, %s)",
                (nome, email, hash_senha(senha)),
            )
            conn.commit()
            print(f"Usuário criado: id={cursor.lastrowid} email={email}")
    except pymysql.err.IntegrityError:
        print(f"Erro: o email '{email}' já está cadastrado.")
        sys.exit(1)
    finally:
        conn.close()


if __name__ == "__main__":
    main()
