from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.gzip import GZipMiddleware
import logging

from .database import bootstrap_database, create_pool, close_pool
from .routers import tratamentos, lembretes, health, estoque, auth

# Notas de execução:
# source .venv/bin/activate
# python -m backend.main_api
# Ou: scripts/run_main.sh
#adb reverse tcp:8000 tcp:8000
#adb reverse tcp:8001 tcp:8001

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("ekobelth")


@asynccontextmanager
async def lifespan(app: FastAPI):
    bootstrap_database()
    await create_pool()
    yield
    await close_pool()


app = FastAPI(title="Ekobelth API", version="1.0.0", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Comprime respostas JSON maiores que 1 KB (menos dados em redes móveis).
# O app (dart:io / navegador) descomprime automaticamente.
app.add_middleware(GZipMiddleware, minimum_size=1000)

app.include_router(tratamentos.router)
app.include_router(lembretes.router)
app.include_router(health.router)
app.include_router(estoque.router)
app.include_router(auth.router)


if __name__ == "__main__":
    import uvicorn
    uvicorn.run("backend.main_api:app", host="0.0.0.0", port=8000, reload=True)
