from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from ..db.database import get_db
from ..db.models import ModelManifest
from ..core.security import get_current_agent

router = APIRouter(prefix="/models", tags=["ota"])


@router.get("/latest")
async def get_latest_models(
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_agent),
):
    result = await db.execute(
        select(ModelManifest).where(ModelManifest.active == True)
    )
    manifests = result.scalars().all()
    return [
        {
            "model_type": m.model_type,
            "version": m.version,
            "url": m.url,
            "checksum": m.checksum,
        }
        for m in manifests
    ]
