import uuid
from datetime import datetime, timezone
from sqlalchemy import Boolean, DateTime, Enum, ForeignKey, Numeric, String, Text, Integer
from sqlalchemy.orm import Mapped, mapped_column, relationship
from .database import Base


def _now() -> datetime:
    return datetime.now(timezone.utc)


class Agent(Base):
    __tablename__ = "agents"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    name: Mapped[str] = mapped_column(String, nullable=False)
    pin_hash: Mapped[str] = mapped_column(String, nullable=False)
    region: Mapped[str] = mapped_column(String, nullable=False)
    cooperative_id: Mapped[str] = mapped_column(String, nullable=False)
    role: Mapped[str] = mapped_column(
        Enum("field_agent", "cooperative_manager", "admin", "enterprise", name="user_role"),
        nullable=False,
        default="field_agent",
    )
    active: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    last_active: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False, default=_now)

    transactions: Mapped[list["Transaction"]] = relationship(back_populates="agent")


class Transaction(Base):
    __tablename__ = "transactions"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True)
    commodity_type: Mapped[str] = mapped_column(String, nullable=False)
    weight: Mapped[float] = mapped_column(Numeric(12, 3), nullable=False)
    unit: Mapped[str] = mapped_column(String, nullable=False)
    buyer_id: Mapped[str] = mapped_column(String, nullable=False)
    seller_id: Mapped[str] = mapped_column(String, nullable=False)
    gps_lat: Mapped[float] = mapped_column(Numeric(10, 6), nullable=False)
    gps_lng: Mapped[float] = mapped_column(Numeric(10, 6), nullable=False)
    gps_accuracy: Mapped[float | None] = mapped_column(Numeric(8, 2), nullable=True)
    timestamp_utc: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    integrity_hash: Mapped[str] = mapped_column(String, nullable=False)
    sync_status: Mapped[str] = mapped_column(String, nullable=False, default="synced")
    agent_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("agents.id"), nullable=False)
    notes: Mapped[str | None] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False, default=_now)
    synced_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False, default=_now)

    agent: Mapped["Agent"] = relationship(back_populates="transactions")


class IntegrityAlert(Base):
    __tablename__ = "integrity_alerts"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    transaction_id: Mapped[uuid.UUID] = mapped_column(nullable=False)
    agent_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("agents.id"), nullable=False)
    expected_hash: Mapped[str] = mapped_column(String, nullable=False)
    received_hash: Mapped[str] = mapped_column(String, nullable=False)
    resolved: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    flagged_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False, default=_now)


class ErpWebhook(Base):
    __tablename__ = "erp_webhooks"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    tenant_id: Mapped[str] = mapped_column(String, nullable=False)
    url: Mapped[str] = mapped_column(String, nullable=False)
    secret: Mapped[str] = mapped_column(String, nullable=False)
    active: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False, default=_now)


class ModelManifest(Base):
    __tablename__ = "model_manifests"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    model_type: Mapped[str] = mapped_column(
        Enum("voice", "vision", name="model_type"), nullable=False
    )
    version: Mapped[str] = mapped_column(String, nullable=False)
    url: Mapped[str] = mapped_column(String, nullable=False)
    checksum: Mapped[str] = mapped_column(String, nullable=False)
    active: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False, default=_now)
