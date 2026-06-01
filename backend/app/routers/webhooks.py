from fastapi import APIRouter, Depends
from pydantic import BaseModel, HttpUrl
from sqlalchemy.ext.asyncio import AsyncSession
from ..db.database import get_db
from ..db.models import ErpWebhook
from ..core.security import require_role
import secrets

router = APIRouter(prefix="/webhooks", tags=["webhooks"])
_admin_only = require_role("admin")


class RegisterWebhookRequest(BaseModel):
    tenant_id: str
    url: HttpUrl


@router.post("/erp", status_code=201)
async def register_erp_webhook(
    body: RegisterWebhookRequest,
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(_admin_only),
):
    wh = ErpWebhook(
        tenant_id=body.tenant_id,
        url=str(body.url),
        secret=secrets.token_hex(32),
    )
    db.add(wh)
    await db.commit()
    await db.refresh(wh)
    return {"id": str(wh.id), "tenant_id": wh.tenant_id, "secret": wh.secret}
