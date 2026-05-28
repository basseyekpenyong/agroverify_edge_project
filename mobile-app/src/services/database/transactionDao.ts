import { v4 as uuidv4 } from 'uuid';
import { getDatabase } from './db';
import { generateTransactionHash } from '@utils/hashEngine';
import type { Transaction, SyncStatus } from '@types/index';

export async function createTransaction(
  params: Omit<Transaction, 'id' | 'integrityHash' | 'syncStatus' | 'createdAt'>,
): Promise<Transaction> {
  const db = getDatabase();
  const id = uuidv4();
  const integrityHash = generateTransactionHash({
    weight: params.weight,
    gpsLat: params.gpsLat,
    gpsLng: params.gpsLng,
    timestampUtc: params.timestampUtc,
    agentId: params.agentId,
  });

  const transaction: Transaction = {
    ...params,
    id,
    integrityHash,
    syncStatus: 'pending',
    createdAt: new Date().toISOString(),
  };

  await db.executeSql(
    `INSERT INTO transactions
      (id, commodity_type, weight, unit, buyer_id, seller_id, gps_lat, gps_lng,
       gps_accuracy, timestamp_utc, integrity_hash, sync_status, agent_id, notes, created_at)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
    [
      transaction.id, transaction.commodityType, transaction.weight, transaction.unit,
      transaction.buyerId, transaction.sellerId, transaction.gpsLat, transaction.gpsLng,
      transaction.gpsAccuracy, transaction.timestampUtc, transaction.integrityHash,
      transaction.syncStatus, transaction.agentId, transaction.notes ?? null,
      transaction.createdAt,
    ],
  );

  // Add to sync queue
  await db.executeSql(
    `INSERT INTO sync_queue (transaction_id, status) VALUES (?, 'pending')`,
    [id],
  );

  return transaction;
}

export async function getTransactionById(id: string): Promise<Transaction | null> {
  const db = getDatabase();
  const [result] = await db.executeSql(
    'SELECT * FROM transactions WHERE id = ?',
    [id],
  );
  if (result.rows.length === 0) return null;
  return mapRow(result.rows.item(0));
}

export async function listTransactions(agentId: string): Promise<Transaction[]> {
  const db = getDatabase();
  const [result] = await db.executeSql(
    'SELECT * FROM transactions WHERE agent_id = ? ORDER BY created_at DESC',
    [agentId],
  );
  return Array.from({ length: result.rows.length }, (_, i) => mapRow(result.rows.item(i)));
}

export async function updateTransactionSyncStatus(
  id: string,
  status: SyncStatus,
): Promise<void> {
  const db = getDatabase();
  await db.executeSql(
    'UPDATE transactions SET sync_status = ? WHERE id = ?',
    [status, id],
  );
}

export async function getPendingTransactions(): Promise<Transaction[]> {
  const db = getDatabase();
  const [result] = await db.executeSql(
    "SELECT * FROM transactions WHERE sync_status = 'pending' ORDER BY created_at ASC",
  );
  return Array.from({ length: result.rows.length }, (_, i) => mapRow(result.rows.item(i)));
}

function mapRow(row: Record<string, unknown>): Transaction {
  return {
    id: row.id as string,
    commodityType: row.commodity_type as string,
    weight: row.weight as number,
    unit: row.unit as string,
    buyerId: row.buyer_id as string,
    sellerId: row.seller_id as string,
    gpsLat: row.gps_lat as number,
    gpsLng: row.gps_lng as number,
    gpsAccuracy: row.gps_accuracy as number,
    timestampUtc: row.timestamp_utc as string,
    integrityHash: row.integrity_hash as string,
    syncStatus: row.sync_status as SyncStatus,
    agentId: row.agent_id as string,
    notes: row.notes as string | undefined,
    createdAt: row.created_at as string,
  };
}
