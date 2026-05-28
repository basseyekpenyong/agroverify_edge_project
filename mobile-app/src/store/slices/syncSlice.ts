import { createSlice, type PayloadAction } from '@reduxjs/toolkit';

type ConnectivityStatus = 'offline' | 'online' | 'syncing';

interface SyncState {
  connectivityStatus: ConnectivityStatus;
  pendingCount: number;
  lastSyncedAt: string | null;
  syncError: string | null;
}

const initialState: SyncState = {
  connectivityStatus: 'offline',
  pendingCount: 0,
  lastSyncedAt: null,
  syncError: null,
};

const syncSlice = createSlice({
  name: 'sync',
  initialState,
  reducers: {
    setConnectivityStatus(state, action: PayloadAction<ConnectivityStatus>) {
      state.connectivityStatus = action.payload;
    },
    setPendingCount(state, action: PayloadAction<number>) {
      state.pendingCount = action.payload;
    },
    syncCompleted(state, action: PayloadAction<string>) {
      state.connectivityStatus = 'online';
      state.lastSyncedAt = action.payload;
      state.syncError = null;
    },
    syncFailed(state, action: PayloadAction<string>) {
      state.connectivityStatus = 'online';
      state.syncError = action.payload;
    },
  },
});

export const { setConnectivityStatus, setPendingCount, syncCompleted, syncFailed } =
  syncSlice.actions;
export default syncSlice.reducer;
