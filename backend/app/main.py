from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from .routers import auth, transactions, agents, alerts, webhooks, ota

app = FastAPI(
    title="AgroVerify Edge API",
    description="Offline-first agricultural supply chain verification backend",
    version="1.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/health", tags=["health"])
async def health():
    return {"status": "ok"}


api = app
api.include_router(auth.router, prefix="/api/v1")
api.include_router(transactions.router, prefix="/api/v1")
api.include_router(agents.router, prefix="/api/v1")
api.include_router(alerts.router, prefix="/api/v1")
api.include_router(webhooks.router, prefix="/api/v1")
api.include_router(ota.router, prefix="/api/v1")
