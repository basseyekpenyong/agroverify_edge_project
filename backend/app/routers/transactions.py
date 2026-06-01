import uuid
from datetime import datetime, timezone
from fastapi import APIRouter, BackgroundTasks, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from ..db.database import get_db
from ..db.models import Transaction, IntegrityAlert, ErpWebhook
from ..core.security import get_current_agent
from ..core.crypto import verify_transaction_hash
from ..core.config import settings
import httpx

router = APIRouter(prefix="/transactions", tags=["transactions"])


class TransactionIn(BaseModel):
    id: str
    commodity_type: str
    weight: float
    unit: str
    buyer_id: str
    seller_id: str
    gps_lat: float
    gps_lng: float
    gps_accuracy: float | None = None
    timestamp_utc: str
    integrity_hash: str
    agent_id: str
    notes: str | None = None


class BatchSyncRequest(BaseModel):
    transactions: list[TransactionIn]


class BatchSyncResponse(BaseModel):
    accepted: list[str]
    rejected: list[dict]


async def _fire_erp_webhooks(transaction_id: str, db: AsyncSession) -> None:
    result = await db.execute(select(ErpWebhook).where(ErpWebhook.active == True))
    webhooks = result.scalars().all()
    async with httpx.AsyncClient(timeout=settings.WEBHOOK_TIMEOUT_SECONDS) as client:
        for wh in webhooks:
            try:
                await client.post(wh.url, json={"transaction_id": transaction_id, "event": "transaction.verified"})
            except Exception:
                pass  # retry logic handled by webhook delivery queue (Phase 3)


@router.post("/batch", response_model=BatchSyncResponse)
async def batch_sync(
    body: BatchSyncRequest,
    background: BackgroundTasks,
    db: AsyncSession = Depends(get_db),
    agent: dict = Depends(get_current_agent),
):
    accepted, rejected = [], []

    for txn in body.transactions:
        hash_ok = verify_transaction_hash(
            expected_hash=txn.integrity_hash,
            weight=txn.weight,
            gps_lat=txn.gps_lat,
            gps_lng=txn.gps_lng,
            timestamp_utc=txn.timestamp_utc,
            agent_id=txn.agent_id,
        )

        if not hash_ok:
            alert = IntegrityAlert(
                transaction_id=uuid.UUID(txn.id),
                agent_id=uuid.UUID(txn.agent_id),
                expected_hash=txn.integrity_hash,
                received_hash="MISMATCH",
            )
            db.add(alert)
            rejected.append({"id": txn.id, "reason": "hash_mismatch"})
            continue

        record = Transaction(
            id=uuid.UUID(txn.id),
            commodity_type=txn.commodity_type,
            weight=txn.weight,
            unit=txn.unit,
            buyer_id=txn.buyer_id,
            seller_id=txn.seller_id,
            gps_lat=txn.gps_lat,
            gps_lng=txn.gps_lng,
            gps_accuracy=txn.gps_accuracy,
            timestamp_utc=datetime.fromisoformat(txn.timestamp_utc),
            integrity_hash=txn.integrity_hash,
            agent_id=uuid.UUID(txn.agent_id),
            notes=txn.notes,
            synced_at=datetime.now(timezone.utc),
        )
        db.add(record)
        accepted.append(txn.id)
        background.add_task(_fire_erp_webhooks, txn.id, db)

    await db.commit()
    return BatchSyncResponse(accepted=accepted, rejected=rejected)


@router.get("/{transaction_id}")
async def get_transaction(
    transaction_id: str,
    db: AsyncSession = Depends(get_db),
    agent: dict = Depends(get_current_agent),
):
    result = await db.execute(select(Transaction).where(Transaction.id == uuid.UUID(transaction_id)))
    txn = result.scalar_one_or_none()
    if not txn:
        raise HTTPException(status_code=404, detail="Transaction not found")
    return txn
