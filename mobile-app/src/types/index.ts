export type SyncStatus = 'pending' | 'syncing' | 'synced' | 'failed';

export type UserRole = 'field_agent' | 'cooperative_manager' | 'admin' | 'enterprise';

export interface Agent {
  id: string;
  name: string;
  region: string;
  cooperativeId: string;
  role: UserRole;
  lastActive: string;
}

export interface Transaction {
  id: string;
  commodityType: string;
  weight: number;
  unit: string;
  buyerId: string;
  sellerId: string;
  gpsLat: number;
  gpsLng: number;
  gpsAccuracy: number;
  timestampUtc: string;
  integrityHash: string;
  syncStatus: SyncStatus;
  agentId: string;
  notes?: string;
  createdAt: string;
}

export interface TransactionImage {
  id: string;
  transactionId: string;
  filePath: string;
  capturedAt: string;
  gpsLat: number;
  gpsLng: number;
  imageType: 'commodity' | 'scale_proof' | 'delivery_evidence';
}

export interface AIInference {
  id: string;
  transactionId: string;
  modelVersion: string;
  result: string;
  confidence: number;
  inferredAt: string;
}

export interface IntegrityAlert {
  id: string;
  transactionId: string;
  expectedHash: string;
  receivedHash: string;
  flaggedAt: string;
}

export interface SyncQueueItem {
  transactionId: string;
  retryCount: number;
  lastAttempt: string | null;
  status: SyncStatus;
}
