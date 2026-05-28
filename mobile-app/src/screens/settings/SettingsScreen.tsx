import React from 'react';
import { View, Text, TouchableOpacity, StyleSheet, SafeAreaView, Alert } from 'react-native';
import { useDispatch, useSelector } from 'react-redux';
import { logout } from '@store/slices/authSlice';
import type { RootState } from '@store/index';
import { Colors } from '@constants/colors';

export default function SettingsScreen() {
  const dispatch = useDispatch();
  const agent = useSelector((state: RootState) => state.auth.agent);

  function handleLogout() {
    Alert.alert('Sign Out', 'Are you sure you want to sign out?', [
      { text: 'Cancel', style: 'cancel' },
      { text: 'Sign Out', style: 'destructive', onPress: () => dispatch(logout()) },
    ]);
  }

  return (
    <SafeAreaView style={styles.container}>
      <Text style={styles.title}>Settings</Text>

      <View style={styles.profileCard}>
        <Text style={styles.agentName}>{agent?.name}</Text>
        <Text style={styles.agentMeta}>{agent?.role?.replace('_', ' ').toUpperCase()} · {agent?.region}</Text>
        <Text style={styles.agentMeta}>Cooperative: {agent?.cooperativeId}</Text>
      </View>

      <TouchableOpacity style={styles.logoutButton} onPress={handleLogout}>
        <Text style={styles.logoutText}>Sign Out</Text>
      </TouchableOpacity>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: Colors.background, padding: 24 },
  title: { fontSize: 22, fontWeight: '700', color: Colors.textPrimary, marginBottom: 24 },
  profileCard: { backgroundColor: Colors.surface, borderRadius: 12, padding: 20, borderWidth: 1, borderColor: Colors.border, marginBottom: 24 },
  agentName: { fontSize: 20, fontWeight: '700', color: Colors.textPrimary, marginBottom: 4 },
  agentMeta: { fontSize: 14, color: Colors.textSecondary, marginTop: 2 },
  logoutButton: { borderWidth: 1.5, borderColor: Colors.danger, borderRadius: 10, padding: 16, alignItems: 'center' },
  logoutText: { color: Colors.danger, fontSize: 16, fontWeight: '700' },
});
