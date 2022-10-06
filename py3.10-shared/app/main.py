import threading, os
from fastapi import FastAPI
import logging
from .cache_utils import DictCache

logger = logging.getLogger("uvicorn.error")
logger.propagate = False
app = FastAPI()

cache = DictCache("tokens")


@app.get("/")
def root():
    counter = cache.get("counter", None)
    if counter is None:
        counter = 0
    else:
        counter += 1
    cache[f"data{counter}"] = [counter] * 1_000_000
    cache["counter"] = counter

    message = f"process={os.getpid()} thread={threading.get_ident()}"
    logger.info(message)

    return {"message": counter}
