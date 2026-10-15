import asyncio
import logging

import pymysql
from fastapi import APIRouter, HTTPException, status

from ..schemas.auth import LoginInput, RegistroInput, UsuarioResponse
from ..repositories import usuario_repo
from ..security import hash_senha, verificar_senha

logger = logging.getLogger("ekobelth.router.auth")

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/login", response_model=UsuarioResponse)
async def login(dados: LoginInput):
    """Confere email e senha no banco e devolve os dados do usuário (inclui o id)."""
    usuario = await usuario_repo.buscar_por_email(dados.email)
    # PBKDF2 é pesado (200k iterações): roda numa thread para não travar
    # o event loop e as outras requisições durante o login.
    if not usuario or not await asyncio.to_thread(
        verificar_senha, dados.senha, usuario["senha_hash"]
    ):
        raise HTTPException(status_code=401, detail="Email ou senha inválidos")
    logger.info("Login realizado: id=%d", usuario["id"])
    return usuario


@router.post("/registrar", response_model=UsuarioResponse, status_code=status.HTTP_201_CREATED)
async def registrar(dados: RegistroInput):
    """Cadastra um novo usuário (apenas dados de autenticação)."""
    if "@" not in dados.email:
        raise HTTPException(status_code=400, detail="Email inválido")
    if await usuario_repo.buscar_por_email(dados.email):
        raise HTTPException(status_code=409, detail="Email já cadastrado")
    try:
        senha_hash = await asyncio.to_thread(hash_senha, dados.senha)
        return await usuario_repo.criar(dados.nome, dados.email, senha_hash)
    except pymysql.err.IntegrityError:
        raise HTTPException(status_code=409, detail="Email já cadastrado")


@router.get("/usuarios/{usuario_id}", response_model=UsuarioResponse)
async def buscar_usuario(usuario_id: int):
    usuario = await usuario_repo.buscar_por_id(usuario_id)
    if not usuario:
        raise HTTPException(status_code=404, detail="Usuário não encontrado")
    return usuario
