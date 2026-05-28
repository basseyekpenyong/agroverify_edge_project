import React from 'react';
import {
  View,
  Text,
  TouchableOpacity,
  StyleSheet,
  SafeAreaView,
  StatusBar,
} from 'react-native';
import { useNavigation } from '@react-navigation/native';
import { useSelector } from 'react-redux';
import type { NativeStackNavigationProp } from '@react-navigation/native-stack';
import type { RootStackParamList } from '@navigation/AppNavigator';
import type { RootState } from '@store/index';
import { Colors } from '@constants/colors';

type Nav = NativeStackNavigationProp<RootStackParamList>;

export default function HomeScreen() {
  const navigation = useNavigation<Nav>();
  const { agent } = useSelector((state: RootState) => state.auth);
  const { connectivityStatus, pendingCount } = useSelector((state: RootState) => state.sync);

  const statusColor =
    connectivityStatus === 'syncing'
      ? Colors.syncInProgress
      : connectivityStatus === 'online'
      ? Colors.syncSynced
      : Colors.syncPending;

  return (
    <SafeAreaView style={styles.container}>
      <StatusBar barStyle="dark-content" backgroundColor={Colors.background} />

      {/* Connectivity banner */}
      {connectivityStatus === 'offline' && (
        <View style={styles.offlineBanner}>
          <Text style={styles.offlineText}>⚠ Offline — transactions will sync when connected</Text>
        </View>
      )}

      <View style={styles.header}>
        <Text style={styles.greeting}>Hello, {agent?.name ?? 'Agent'}</Text>
        <View style={[styles.statusDot, { backgroundColor: statusColor }]} />
      </View>

      {pendingCount > 0 && (
        <View style={styles.pendingChip}>
          <Text style={styles.pendingText}>{pendingCount} transaction{pendingCount !== 1 ? 's' : ''} pending sync</Text>
        </View>
      )}

      {/* Primary CTA — reachable in 1 tap */}
      <TouchableOpacity
        style={styles.captureButton}
        onPress={() => navigation.navigate('NewTransaction')}
        activeOpacity={0.85}>
        <Text style={styles.captureIcon}>+</Text>
        <Text style={styles.captureLabel}>New Transaction</Text>
      </TouchableOpacity>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: Colors.background },
  offlineBanner: {
    backgroundColor: Colors.offlineBg,
    paddingVertical: 10,
    paddingHorizontal: 16,
  },
  offlineText: { color: Colors.offlineText, fontSize: 13, fontWeight: '600', textAlign: 'center' },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: 24,
    paddingTop: 24,
    paddingBottom: 12,
  },
  greeting: { fontSize: 22, fontWeight: '700', color: Colors.textPrimary },
  statusDot: { width: 12, height: 12, borderRadius: 6 },
  pendingChip: {
    marginHorizontal: 24,
    backgroundColor: Colors.primaryLight,
    borderRadius: 8,
    padding: 10,
    marginBottom: 16,
  },
  pendingText: { color: Colors.primaryDark, fontSize: 13, fontWeight: '600', textAlign: 'center' },
  captureButton: {
    margin: 24,
    backgroundColor: Colors.primary,
    borderRadius: 16,
    paddingVertical: 32,
    alignItems: 'center',
    justifyContent: 'center',
    elevation: 4,
  },
  captureIcon: { fontSize: 48, color: '#FFFFFF', fontWeight: '300', lineHeight: 56 },
  captureLabel: { fontSize: 20, color: '#FFFFFF', fontWeight: '700', marginTop: 4 },
});
