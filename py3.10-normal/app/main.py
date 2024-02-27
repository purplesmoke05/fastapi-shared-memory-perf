import threading, os
from fastapi import FastAPI
import logging

logger = logging.getLogger("uvicorn.error")
logger.propagate = False
app = FastAPI()


@app.get("/")
async def root():
    data = [0] * 1_000_000

    message = f"process={os.getpid()} thread={threading.get_ident()}"
    logger.info(message)
    return {"message": data}
