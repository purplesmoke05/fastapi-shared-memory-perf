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
    if counter >= 250:
        counter = 250
    cache["counter"] = counter
    ret = cache.get(f"data{counter}", None)
    if ret is None:
        cache[f"data{counter}"] = [0] * 100_000
        ret = cache[f"data{counter}"]

    message = f"process={os.getpid()} thread={threading.get_ident()}"
    logger.info(message)

    return {"message": "Hello World"}
