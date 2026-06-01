from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from ..db.database import get_db
from ..db.models import Agent
from ..core.security import require_role, hash_pin

router = APIRouter(prefix="/agents", tags=["agents"])
_admin_only = require_role("admin")


class CreateAgentRequest(BaseModel):
    name: str
    pin: str
    region: str
    cooperative_id: str
    role: str = "field_agent"


class UpdateAgentStatusRequest(BaseModel):
    active: bool


@router.post("", status_code=201)
async def create_agent(
    body: CreateAgentRequest,
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(_admin_only),
):
    agent = Agent(
        name=body.name,
        pin_hash=hash_pin(body.pin),
        region=body.region,
        cooperative_id=body.cooperative_id,
        role=body.role,
    )
    db.add(agent)
    await db.commit()
    await db.refresh(agent)
    return {"id": str(agent.id), "name": agent.name, "role": agent.role}


@router.patch("/{agent_id}/status")
async def update_agent_status(
    agent_id: str,
    body: UpdateAgentStatusRequest,
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(_admin_only),
):
    result = await db.execute(select(Agent).where(Agent.id == agent_id))
    agent = result.scalar_one_or_none()
    if not agent:
        raise HTTPException(status_code=404, detail="Agent not found")
    agent.active = body.active
    await db.commit()
    return {"id": str(agent.id), "active": agent.active}
