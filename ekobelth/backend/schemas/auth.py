from pydantic import BaseModel, Field


class LoginInput(BaseModel):
    email: str = Field(..., min_length=3, max_length=255)
    senha: str = Field(..., min_length=1, max_length=255)


class RegistroInput(BaseModel):
    nome: str = Field(..., min_length=1, max_length=255)
    email: str = Field(..., min_length=3, max_length=255)
    senha: str = Field(..., min_length=4, max_length=255)


class UsuarioResponse(BaseModel):
    id: int
    nome: str
    email: str
