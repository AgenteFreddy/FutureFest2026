"""
Script de inicialização e verificação do Banco de Dados MySQL para o Ekobelth.
Compatível com Windows, Linux e macOS.
"""
import os
import sys
from pathlib import Path

# Adiciona o diretório ekobelth ao path se necessário
raiz = Path(__file__).resolve().parent.parent.parent
sys.path.insert(0, str(raiz / "ekobelth"))

try:
    from dotenv import load_dotenv
    # Carrega .env do ekobelth ou da raiz
    if (raiz / "ekobelth" / ".env").exists():
        load_dotenv(raiz / "ekobelth" / ".env")
    elif (raiz / ".env").exists():
        load_dotenv(raiz / ".env")
except ImportError:
    pass

import pymysql

DB_HOST = os.getenv("EKOBELTH_DB_HOST", "localhost")
DB_USER = os.getenv("EKOBELTH_DB_USER", "root")
DB_PASSWORD = os.getenv("EKOBELTH_DB_PASSWORD", "")
DB_NAME = os.getenv("EKOBELTH_DB_NAME", "ekobelth")
DB_PORT = int(os.getenv("EKOBELTH_DB_PORT", "3306"))

print("=" * 60)
print("  EKOBELTH - CONFIGURADOR DE BANCO DE DADOS (MySQL)")
print("=" * 60)
print(f"Host:     {DB_HOST}:{DB_PORT}")
print(f"Usuario:  {DB_USER}")
print(f"Banco:    {DB_NAME}")
print("=" * 60)

def testar_e_criar():
    try:
        print("[1/4] Conectando ao MySQL Server...")
        conn = pymysql.connect(
            host=DB_HOST,
            port=DB_PORT,
            user=DB_USER,
            password=DB_PASSWORD,
            charset="utf8mb4",
            autocommit=True
        )
        print("  -> Conexao estabelecida com sucesso!")

        with conn.cursor() as cur:
            print(f"[2/4] Verificando se o banco '{DB_NAME}' existe...")
            cur.execute(f"CREATE DATABASE IF NOT EXISTS `{DB_NAME}` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;")
            print(f"  -> Banco '{DB_NAME}' verificado/criado.")

        conn.close()

        print(f"[3/4] Conectando ao banco '{DB_NAME}'...")
        conn_db = pymysql.connect(
            host=DB_HOST,
            port=DB_PORT,
            user=DB_USER,
            password=DB_PASSWORD,
            database=DB_NAME,
            charset="utf8mb4",
            autocommit=True
        )

        with conn_db.cursor() as cur:
            print("[4/4] Criando tabelas...")
            sql_file = Path(__file__).resolve().parent / "database.sql"
            if sql_file.exists():
                conteudo = sql_file.read_text(encoding="utf-8")
                # Executa comandos individuais do arquivo SQL
                comandos = [cmd.strip() for cmd in conteudo.split(";") if cmd.strip()]
                for cmd in comandos:
                    # Ignora USE ou CREATE USER se falhar
                    try:
                        cur.execute(cmd)
                    except Exception as sql_err:
                        # Se já existir tabela ou usuário, segue
                        if "already exists" in str(sql_err).lower() or "duplicate" in str(sql_err).lower():
                            pass
                        else:
                            print(f"    (Aviso SQL: {sql_err})")
                print("  -> Tabelas 'usuarios', 'tratamentos' e 'estoque' prontas!")
            else:
                print("  -> database.sql nao encontrado localmente, as tabelas serao criadas pelo backend automaticamente no primeiro inicio.")

        conn_db.close()
        print("\n" + "=" * 60)
        print(" [SUCESSO] Banco de Dados configurado e pronto para uso!")
        print("=" * 60)
        return True

    except pymysql.err.OperationalError as e:
        print("\n[ERRO DE CONEXAO AO MYSQL]")
        print(f"Detalhes: {e}")
        print("\nDicas para solucionar:")
        print(" 1. Verifique se o MySQL ou XAMPP esta em execucao.")
        print(" 2. Verifique o usuario e senha no arquivo .env")
        print(" 3. Se estiver usando root sem senha, defina EKOBELTH_DB_PASSWORD=")
        return False
    except Exception as e:
        print(f"\n[ERRO INESPERADO]: {e}")
        return False

if __name__ == "__main__":
    sucesso = testar_e_criar()
    sys.exit(0 if sucesso else 1)
