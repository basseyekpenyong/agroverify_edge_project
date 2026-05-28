import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  TextInput,
  TouchableOpacity,
  ScrollView,
  StyleSheet,
  SafeAreaView,
  Alert,
} from 'react-native';
import { useNavigation } from '@react-navigation/native';
import { useDispatch, useSelector } from 'react-redux';
import Geolocation from 'react-native-geolocation-service';
import { v4 as uuidv4 } from 'uuid';
import { addTransaction } from '@store/slices/transactionSlice';
import { createTransaction } from '@services/database/transactionDao';
import { Colors } from '@constants/colors';
import { COMMODITIES, WEIGHT_UNITS } from '@constants/commodities';
import type { RootState } from '@store/index';

export default function NewTransactionScreen() {
  const navigation = useNavigation();
  const dispatch = useDispatch();
  const agent = useSelector((state: RootState) => state.auth.agent);

  const [commodityType, setCommodityType] = useState('');
  const [weight, setWeight] = useState('');
  const [unit, setUnit] = useState('kg');
  const [buyerId, setBuyerId] = useState('');
  const [sellerId, setSellerId] = useState('');
  const [notes, setNotes] = useState('');
  const [gps, setGps] = useState<{ lat: number; lng: number; accuracy: number } | null>(null);
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    Geolocation.getCurrentPosition(
      pos => setGps({ lat: pos.coords.latitude, lng: pos.coords.longitude, accuracy: pos.coords.accuracy }),
      () => {
        // Fallback: last known position handled by the GPS service
        Geolocation.getLastKnownPosition(
          pos => pos && setGps({ lat: pos.coords.latitude, lng: pos.coords.longitude, accuracy: pos.coords.accuracy }),
          () => {},
        );
      },
      { enableHighAccuracy: true, timeout: 10000, maximumAge: 30000 },
    );
  }, []);

  async function handleSave() {
    if (!commodityType || !weight || !buyerId || !sellerId) {
      Alert.alert('Missing fields', 'Fill in commodity, weight, buyer and seller.');
      return;
    }
    if (!gps) {
      Alert.alert('No GPS', 'Waiting for GPS signal. Try again in a moment.');
      return;
    }
    setSaving(true);
    try {
      const transaction = await createTransaction({
        commodityType,
        weight: parseFloat(weight),
        unit,
        buyerId,
        sellerId,
        gpsLat: gps.lat,
        gpsLng: gps.lng,
        gpsAccuracy: gps.accuracy,
        timestampUtc: new Date().toISOString(),
        agentId: agent!.id,
        notes: notes || undefined,
      });
      dispatch(addTransaction(transaction));
      navigation.goBack();
    } catch (e) {
      Alert.alert('Save failed', 'Could not save transaction. Try again.');
    } finally {
      setSaving(false);
    }
  }

  return (
    <SafeAreaView style={styles.container}>
      <ScrollView contentContainerStyle={styles.scroll} keyboardShouldPersistTaps="handled">
        <Text style={styles.title}>New Transaction</Text>

        <Text style={styles.label}>Commodity *</Text>
        <View style={styles.chipRow}>
          {COMMODITIES.map(c => (
            <TouchableOpacity
              key={c.id}
              style={[styles.chip, commodityType === c.id && styles.chipSelected]}
              onPress={() => setCommodityType(c.id)}>
              <Text style={[styles.chipText, commodityType === c.id && styles.chipTextSelected]}>
                {c.label}
              </Text>
            </TouchableOpacity>
          ))}
        </View>

        <Text style={styles.label}>Weight *</Text>
        <View style={styles.row}>
          <TextInput
            style={[styles.input, { flex: 1, marginRight: 8 }]}
            placeholder="0.00"
            placeholderTextColor={Colors.textMuted}
            keyboardType="decimal-pad"
            value={weight}
            onChangeText={setWeight}
          />
          <View style={styles.chipRow}>
            {WEIGHT_UNITS.map(u => (
              <TouchableOpacity
                key={u}
                style={[styles.chip, unit === u && styles.chipSelected]}
                onPress={() => setUnit(u)}>
                <Text style={[styles.chipText, unit === u && styles.chipTextSelected]}>{u}</Text>
              </TouchableOpacity>
            ))}
          </View>
        </View>

        <Text style={styles.label}>Buyer ID *</Text>
        <TextInput style={styles.input} placeholder="Buyer name or ID" placeholderTextColor={Colors.textMuted} value={buyerId} onChangeText={setBuyerId} />

        <Text style={styles.label}>Seller ID *</Text>
        <TextInput style={styles.input} placeholder="Seller name or ID" placeholderTextColor={Colors.textMuted} value={sellerId} onChangeText={setSellerId} />

        <Text style={styles.label}>Notes</Text>
        <TextInput style={[styles.input, { height: 80 }]} placeholder="Optional notes..." placeholderTextColor={Colors.textMuted} value={notes} onChangeText={setNotes} multiline />

        <View style={styles.metaRow}>
          <Text style={styles.metaLabel}>GPS</Text>
          <Text style={styles.metaValue}>
            {gps ? `${gps.lat.toFixed(5)}, ${gps.lng.toFixed(5)} (±${Math.round(gps.accuracy)}m)` : 'Acquiring...'}
          </Text>
        </View>
        <View style={styles.metaRow}>
          <Text style={styles.metaLabel}>Timestamp</Text>
          <Text style={styles.metaValue}>{new Date().toUTCString()}</Text>
        </View>

        <TouchableOpacity
          style={[styles.saveButton, saving && styles.saveButtonDisabled]}
          onPress={handleSave}
          disabled={saving}>
          <Text style={styles.saveButtonText}>{saving ? 'Saving...' : 'Save Transaction'}</Text>
        </TouchableOpacity>
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: Colors.background },
  scroll: { padding: 24, paddingBottom: 48 },
  title: { fontSize: 22, fontWeight: '700', color: Colors.textPrimary, marginBottom: 24 },
  label: { fontSize: 13, fontWeight: '600', color: Colors.textSecondary, marginBottom: 6, marginTop: 16, textTransform: 'uppercase', letterSpacing: 0.5 },
  input: { borderWidth: 1.5, borderColor: Colors.border, borderRadius: 10, padding: 14, fontSize: 16, color: Colors.textPrimary, backgroundColor: Colors.surface },
  row: { flexDirection: 'row', alignItems: 'center' },
  chipRow: { flexDirection: 'row', flexWrap: 'wrap', gap: 8 },
  chip: { borderWidth: 1.5, borderColor: Colors.border, borderRadius: 20, paddingHorizontal: 14, paddingVertical: 8 },
  chipSelected: { backgroundColor: Colors.primary, borderColor: Colors.primary },
  chipText: { fontSize: 14, color: Colors.textSecondary },
  chipTextSelected: { color: '#FFFFFF', fontWeight: '600' },
  metaRow: { flexDirection: 'row', justifyContent: 'space-between', paddingVertical: 8, borderBottomWidth: 1, borderBottomColor: Colors.border },
  metaLabel: { fontSize: 13, color: Colors.textMuted, fontWeight: '600' },
  metaValue: { fontSize: 13, color: Colors.textSecondary, flex: 1, textAlign: 'right' },
  saveButton: { marginTop: 32, backgroundColor: Colors.primary, borderRadius: 12, padding: 18, alignItems: 'center' },
  saveButtonDisabled: { opacity: 0.6 },
  saveButtonText: { color: '#FFFFFF', fontSize: 17, fontWeight: '700' },
});
