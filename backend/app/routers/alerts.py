from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from ..db.database import get_db
from ..db.models import IntegrityAlert
from ..core.security import require_role

router = APIRouter(prefix="/alerts", tags=["alerts"])
_admin_only = require_role("admin")


@router.get("/integrity")
async def list_integrity_alerts(
    resolved: bool = False,
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(_admin_only),
):
    result = await db.execute(
        select(IntegrityAlert)
        .where(IntegrityAlert.resolved == resolved)
        .order_by(IntegrityAlert.flagged_at.desc())
    )
    alerts = result.scalars().all()
    return [
        {
            "id": str(a.id),
            "transaction_id": str(a.transaction_id),
            "agent_id": str(a.agent_id),
            "expected_hash": a.expected_hash,
            "received_hash": a.received_hash,
            "resolved": a.resolved,
            "flagged_at": a.flagged_at.isoformat(),
        }
        for a in alerts
    ]
