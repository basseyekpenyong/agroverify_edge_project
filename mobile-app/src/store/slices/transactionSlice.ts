import { createSlice, type PayloadAction } from '@reduxjs/toolkit';
import type { Transaction } from '@types/index';

interface TransactionState {
  items: Transaction[];
  loading: boolean;
  error: string | null;
}

const initialState: TransactionState = {
  items: [],
  loading: false,
  error: null,
};

const transactionSlice = createSlice({
  name: 'transactions',
  initialState,
  reducers: {
    setTransactions(state, action: PayloadAction<Transaction[]>) {
      state.items = action.payload;
    },
    addTransaction(state, action: PayloadAction<Transaction>) {
      state.items.unshift(action.payload);
    },
    updateTransaction(state, action: PayloadAction<Transaction>) {
      const index = state.items.findIndex(t => t.id === action.payload.id);
      if (index !== -1) state.items[index] = action.payload;
    },
    setLoading(state, action: PayloadAction<boolean>) {
      state.loading = action.payload;
    },
    setError(state, action: PayloadAction<string | null>) {
      state.error = action.payload;
    },
  },
});

export const { setTransactions, addTransaction, updateTransaction, setLoading, setError } =
  transactionSlice.actions;
export default transactionSlice.reducer;
