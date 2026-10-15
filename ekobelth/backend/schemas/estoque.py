from pydantic import BaseModel
from typing import Optional

class RemedioEstoqueBase(BaseModel):
    medicamento: str
    quantidade: str
    via: str = ""
    data_validade: str = ""
    observacoes: str = ""

class RemedioEstoqueCreate(RemedioEstoqueBase):
    pass

class RemedioEstoqueResponse(RemedioEstoqueBase):
    id: int

    class Config:
        from_attributes = True
