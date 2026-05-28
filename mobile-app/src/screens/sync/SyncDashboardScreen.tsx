import React from 'react';
import { View, Text, StyleSheet, SafeAreaView } from 'react-native';
import { useSelector } from 'react-redux';
import type { RootState } from '@store/index';
import { Colors } from '@constants/colors';

export default function SyncDashboardScreen() {
  const { connectivityStatus, pendingCount, lastSyncedAt, syncError } = useSelector(
    (state: RootState) => state.sync,
  );

  const statusLabel = {
    offline: 'Offline',
    online: 'Online',
    syncing: 'Syncing...',
  }[connectivityStatus];

  const statusColor = {
    offline: Colors.syncPending,
    online: Colors.syncSynced,
    syncing: Colors.syncInProgress,
  }[connectivityStatus];

  return (
    <SafeAreaView style={styles.container}>
      <Text style={styles.title}>Sync Status</Text>

      <View style={[styles.statusCard, { borderLeftColor: statusColor }]}>
        <Text style={styles.statusLabel}>Connection</Text>
        <Text style={[styles.statusValue, { color: statusColor }]}>{statusLabel}</Text>
      </View>

      <View style={styles.row}>
        <View style={styles.metricCard}>
          <Text style={styles.metricValue}>{pendingCount}</Text>
          <Text style={styles.metricLabel}>Pending Sync</Text>
        </View>
        <View style={styles.metricCard}>
          <Text style={styles.metricValue}>{lastSyncedAt ? new Date(lastSyncedAt).toLocaleTimeString() : '—'}</Text>
          <Text style={styles.metricLabel}>Last Synced</Text>
        </View>
      </View>

      {syncError && (
        <View style={styles.errorCard}>
          <Text style={styles.errorText}>⚠ {syncError}</Text>
        </View>
      )}
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: Colors.background, padding: 24 },
  title: { fontSize: 22, fontWeight: '700', color: Colors.textPrimary, marginBottom: 24 },
  statusCard: { backgroundColor: Colors.surface, borderRadius: 12, padding: 20, borderLeftWidth: 4, marginBottom: 16, borderWidth: 1, borderColor: Colors.border },
  statusLabel: { fontSize: 12, color: Colors.textMuted, fontWeight: '600', textTransform: 'uppercase' },
  statusValue: { fontSize: 24, fontWeight: '700', marginTop: 4 },
  row: { flexDirection: 'row', gap: 12, marginBottom: 16 },
  metricCard: { flex: 1, backgroundColor: Colors.surface, borderRadius: 12, padding: 20, borderWidth: 1, borderColor: Colors.border, alignItems: 'center' },
  metricValue: { fontSize: 22, fontWeight: '800', color: Colors.textPrimary },
  metricLabel: { fontSize: 12, color: Colors.textMuted, marginTop: 4, fontWeight: '600' },
  errorCard: { backgroundColor: '#FEF2F2', borderRadius: 10, padding: 14, borderWidth: 1, borderColor: '#FECACA' },
  errorText: { color: Colors.danger, fontSize: 14 },
});
