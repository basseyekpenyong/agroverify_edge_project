import { createSlice, type PayloadAction } from '@reduxjs/toolkit';
import type { Agent } from '@types/index';

interface AuthState {
  isAuthenticated: boolean;
  agent: Agent | null;
  sessionExpiresAt: string | null;
}

const initialState: AuthState = {
  isAuthenticated: false,
  agent: null,
  sessionExpiresAt: null,
};

const authSlice = createSlice({
  name: 'auth',
  initialState,
  reducers: {
    loginSuccess(state, action: PayloadAction<{ agent: Agent; expiresAt: string }>) {
      state.isAuthenticated = true;
      state.agent = action.payload.agent;
      state.sessionExpiresAt = action.payload.expiresAt;
    },
    logout(state) {
      state.isAuthenticated = false;
      state.agent = null;
      state.sessionExpiresAt = null;
    },
  },
});

export const { loginSuccess, logout } = authSlice.actions;
export default authSlice.reducer;
