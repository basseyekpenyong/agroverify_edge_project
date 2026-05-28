import React from 'react';
import { View, Text, ScrollView, StyleSheet, SafeAreaView } from 'react-native';
import { useRoute } from '@react-navigation/native';
import { useSelector } from 'react-redux';
import type { RouteProp } from '@react-navigation/native';
import type { RootStackParamList } from '@navigation/AppNavigator';
import type { RootState } from '@store/index';
import { Colors } from '@constants/colors';

type Route = RouteProp<RootStackParamList, 'TransactionDetail'>;

export default function TransactionDetailScreen() {
  const route = useRoute<Route>();
  const transaction = useSelector((state: RootState) =>
    state.transactions.items.find(t => t.id === route.params.transactionId),
  );

  if (!transaction) {
    return (
      <SafeAreaView style={styles.container}>
        <Text style={styles.notFound}>Transaction not found.</Text>
      </SafeAreaView>
    );
  }

  return (
    <SafeAreaView style={styles.container}>
      <ScrollView contentContainerStyle={styles.scroll}>
        <Text style={styles.title}>{transaction.commodityType.toUpperCase()}</Text>
        <Text style={styles.weight}>{transaction.weight} {transaction.unit}</Text>

        <Section label="Parties">
          <Row label="Buyer" value={transaction.buyerId} />
          <Row label="Seller" value={transaction.sellerId} />
        </Section>

        <Section label="Location & Time">
          <Row label="GPS" value={`${transaction.gpsLat.toFixed(5)}, ${transaction.gpsLng.toFixed(5)}`} />
          <Row label="Accuracy" value={`±${Math.round(transaction.gpsAccuracy)}m`} />
          <Row label="Timestamp" value={new Date(transaction.timestampUtc).toLocaleString()} />
        </Section>

        <Section label="Integrity">
          <Row label="Hash" value={transaction.integrityHash.slice(0, 20) + '...'} mono />
          <Row label="Sync" value={transaction.syncStatus} />
        </Section>

        {transaction.notes && (
          <Section label="Notes">
            <Text style={styles.notes}>{transaction.notes}</Text>
          </Section>
        )}
      </ScrollView>
    </SafeAreaView>
  );
}

function Section({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <View style={styles.section}>
      <Text style={styles.sectionLabel}>{label}</Text>
      {children}
    </View>
  );
}

function Row({ label, value, mono }: { label: string; value: string; mono?: boolean }) {
  return (
    <View style={styles.row}>
      <Text style={styles.rowLabel}>{label}</Text>
      <Text style={[styles.rowValue, mono && styles.mono]}>{value}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: Colors.background },
  scroll: { padding: 24 },
  title: { fontSize: 14, fontWeight: '700', color: Colors.primary, letterSpacing: 1, marginBottom: 4 },
  weight: { fontSize: 32, fontWeight: '800', color: Colors.textPrimary, marginBottom: 24 },
  section: { marginBottom: 24 },
  sectionLabel: { fontSize: 11, fontWeight: '700', color: Colors.textMuted, letterSpacing: 1, textTransform: 'uppercase', marginBottom: 8 },
  row: { flexDirection: 'row', justifyContent: 'space-between', paddingVertical: 8, borderBottomWidth: 1, borderBottomColor: Colors.border },
  rowLabel: { fontSize: 14, color: Colors.textSecondary },
  rowValue: { fontSize: 14, color: Colors.textPrimary, fontWeight: '500', flex: 1, textAlign: 'right' },
  mono: { fontFamily: 'monospace', fontSize: 12 },
  notes: { fontSize: 14, color: Colors.textSecondary, lineHeight: 22 },
  notFound: { textAlign: 'center', marginTop: 80, fontSize: 16, color: Colors.textMuted },
});
