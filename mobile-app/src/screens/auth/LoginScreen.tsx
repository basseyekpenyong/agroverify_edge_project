import React, { useState } from 'react';
import {
  View,
  Text,
  TextInput,
  TouchableOpacity,
  StyleSheet,
  SafeAreaView,
  Alert,
} from 'react-native';
import { useDispatch } from 'react-redux';
import { loginSuccess } from '@store/slices/authSlice';
import { Colors } from '@constants/colors';

export default function LoginScreen() {
  const dispatch = useDispatch();
  const [agentId, setAgentId] = useState('');
  const [pin, setPin] = useState('');
  const [loading, setLoading] = useState(false);

  async function handleLogin() {
    if (!agentId.trim() || pin.length < 4) {
      Alert.alert('Error', 'Enter your Agent ID and 4-digit PIN.');
      return;
    }
    setLoading(true);
    try {
      // TODO: replace with real auth service (offline PIN verification)
      const expiresAt = new Date(Date.now() + 8 * 60 * 60 * 1000).toISOString();
      dispatch(loginSuccess({
        agent: {
          id: agentId,
          name: 'Agent',
          region: 'default',
          cooperativeId: 'default',
          role: 'field_agent',
          lastActive: new Date().toISOString(),
        },
        expiresAt,
      }));
    } catch {
      Alert.alert('Login failed', 'Invalid credentials. Try again.');
    } finally {
      setLoading(false);
    }
  }

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.inner}>
        <Text style={styles.logo}>🌾 AgroVerify Edge</Text>
        <Text style={styles.subtitle}>Field Agent Login</Text>

        <TextInput
          style={styles.input}
          placeholder="Agent ID"
          placeholderTextColor={Colors.textMuted}
          value={agentId}
          onChangeText={setAgentId}
          autoCapitalize="none"
        />
        <TextInput
          style={styles.input}
          placeholder="PIN"
          placeholderTextColor={Colors.textMuted}
          value={pin}
          onChangeText={setPin}
          keyboardType="numeric"
          secureTextEntry
          maxLength={6}
        />

        <TouchableOpacity
          style={[styles.button, loading && styles.buttonDisabled]}
          onPress={handleLogin}
          disabled={loading}>
          <Text style={styles.buttonText}>{loading ? 'Signing in...' : 'Sign In'}</Text>
        </TouchableOpacity>
      </View>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: Colors.background },
  inner: { flex: 1, justifyContent: 'center', paddingHorizontal: 32 },
  logo: { fontSize: 28, fontWeight: 'bold', color: Colors.primary, textAlign: 'center', marginBottom: 8 },
  subtitle: { fontSize: 16, color: Colors.textSecondary, textAlign: 'center', marginBottom: 40 },
  input: {
    borderWidth: 1.5,
    borderColor: Colors.border,
    borderRadius: 10,
    padding: 16,
    fontSize: 16,
    color: Colors.textPrimary,
    marginBottom: 16,
    backgroundColor: Colors.surface,
  },
  button: {
    backgroundColor: Colors.primary,
    borderRadius: 10,
    padding: 18,
    alignItems: 'center',
    marginTop: 8,
  },
  buttonDisabled: { opacity: 0.6 },
  buttonText: { color: '#FFFFFF', fontSize: 16, fontWeight: '700' },
});
