"""Funções de hash e verificação de senha (somente biblioteca padrão)."""
import hashlib
import hmac
import secrets

_ALGORITMO = "pbkdf2_sha256"
_ITERACOES = 200_000


def hash_senha(senha: str) -> str:
    """Gera o hash de uma senha no formato: algoritmo$iteracoes$salt$hash."""
    salt = secrets.token_hex(16)
    digest = hashlib.pbkdf2_hmac("sha256", senha.encode("utf-8"), salt.encode("utf-8"), _ITERACOES)
    return f"{_ALGORITMO}${_ITERACOES}${salt}${digest.hex()}"


def verificar_senha(senha: str, senha_hash: str) -> bool:
    """Confere se a senha informada corresponde ao hash salvo no banco."""
    try:
        algoritmo, iteracoes, salt, esperado = senha_hash.split("$")
        if algoritmo != _ALGORITMO:
            return False
        digest = hashlib.pbkdf2_hmac(
            "sha256", senha.encode("utf-8"), salt.encode("utf-8"), int(iteracoes)
        )
        return hmac.compare_digest(digest.hex(), esperado)
    except (ValueError, AttributeError):
        return False
