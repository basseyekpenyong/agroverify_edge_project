import React from 'react';
import { View, Text, FlatList, TouchableOpacity, StyleSheet, SafeAreaView } from 'react-native';
import { useNavigation } from '@react-navigation/native';
import { useSelector } from 'react-redux';
import type { NativeStackNavigationProp } from '@react-navigation/native-stack';
import type { RootStackParamList } from '@navigation/AppNavigator';
import type { RootState } from '@store/index';
import type { Transaction } from '@types/index';
import { Colors } from '@constants/colors';

type Nav = NativeStackNavigationProp<RootStackParamList>;

const SYNC_COLOR: Record<string, string> = {
  pending: Colors.syncPending,
  syncing: Colors.syncInProgress,
  synced: Colors.syncSynced,
  failed: Colors.syncFailed,
};

export default function TransactionListScreen() {
  const navigation = useNavigation<Nav>();
  const transactions = useSelector((state: RootState) => state.transactions.items);

  function renderItem({ item }: { item: Transaction }) {
    return (
      <TouchableOpacity
        style={styles.card}
        onPress={() => navigation.navigate('TransactionDetail', { transactionId: item.id })}>
        <View style={styles.cardHeader}>
          <Text style={styles.commodity}>{item.commodityType.toUpperCase()}</Text>
          <View style={[styles.syncBadge, { backgroundColor: SYNC_COLOR[item.syncStatus] }]}>
            <Text style={styles.syncBadgeText}>{item.syncStatus}</Text>
          </View>
        </View>
        <Text style={styles.weight}>{item.weight} {item.unit}</Text>
        <Text style={styles.meta}>{new Date(item.createdAt).toLocaleString()}</Text>
      </TouchableOpacity>
    );
  }

  return (
    <SafeAreaView style={styles.container}>
      <Text style={styles.title}>Transactions</Text>
      <FlatList
        data={transactions}
        keyExtractor={item => item.id}
        renderItem={renderItem}
        contentContainerStyle={styles.list}
        ListEmptyComponent={<Text style={styles.empty}>No transactions yet. Tap + to create one.</Text>}
      />
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: Colors.background },
  title: { fontSize: 22, fontWeight: '700', color: Colors.textPrimary, padding: 24, paddingBottom: 12 },
  list: { paddingHorizontal: 24, paddingBottom: 32 },
  card: { backgroundColor: Colors.surface, borderRadius: 12, padding: 16, marginBottom: 12, borderWidth: 1, borderColor: Colors.border },
  cardHeader: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginBottom: 4 },
  commodity: { fontSize: 13, fontWeight: '700', color: Colors.primary, letterSpacing: 0.5 },
  syncBadge: { borderRadius: 10, paddingHorizontal: 10, paddingVertical: 3 },
  syncBadgeText: { color: '#FFFFFF', fontSize: 11, fontWeight: '600' },
  weight: { fontSize: 20, fontWeight: '700', color: Colors.textPrimary, marginBottom: 4 },
  meta: { fontSize: 12, color: Colors.textMuted },
  empty: { textAlign: 'center', color: Colors.textMuted, marginTop: 64, fontSize: 15 },
});
