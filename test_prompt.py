import asyncio
from ekobelth.backend.database import create_pool, close_pool
from ekobelth.backend.services.ia_context import build_system_prompt

async def main():
    await create_pool()
    print(await build_system_prompt())
    await close_pool()

asyncio.run(main())
