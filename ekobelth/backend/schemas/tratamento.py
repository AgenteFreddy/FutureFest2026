from pydantic import BaseModel, Field


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
