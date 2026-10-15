from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import logging

from .database import bootstrap_database, create_pool, close_pool
from .routers import ia_eko

# Notas de execução:
# source .venv/bin/activate
# python -m backend.ia_eko_api
# Ou: scripts/run_api.sh

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("ia_eko")


@asynccontextmanager
async def lifespan(app: FastAPI):
    bootstrap_database()
    await create_pool()
    yield
    await ia_eko.fechar_cliente_ollama()
    await close_pool()


app = FastAPI(title="IA Eko API", version="1.0.0", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(ia_eko.router)


if __name__ == "__main__":
    import uvicorn
    uvicorn.run("backend.ia_eko_api:app", host="0.0.0.0", port=8001, reload=True)
