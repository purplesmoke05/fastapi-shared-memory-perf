import threading, os
import random
from fastapi import FastAPI
import logging

logger = logging.getLogger("uvicorn.error")
logger.propagate = False
app = FastAPI()


@app.get("/")
async def root():
    v = random.random()
    data = [v] * 5_000_000

    message = f"process={os.getpid()} thread={threading.get_ident()}"
    logger.info(message)
    return {"message": data}
