import React from 'react';
import { NavigationContainer } from '@react-navigation/native';
import { createNativeStackNavigator } from '@react-navigation/native-stack';
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';
import { useSelector } from 'react-redux';
import type { RootState } from '@store/index';

// Screen imports (stubs — implemented in Phase 1)
import LoginScreen from '@screens/auth/LoginScreen';
import HomeScreen from '@screens/home/HomeScreen';
import NewTransactionScreen from '@screens/transactions/NewTransactionScreen';
import TransactionListScreen from '@screens/transactions/TransactionListScreen';
import TransactionDetailScreen from '@screens/transactions/TransactionDetailScreen';
import SyncDashboardScreen from '@screens/sync/SyncDashboardScreen';
import SettingsScreen from '@screens/settings/SettingsScreen';

export type RootStackParamList = {
  Login: undefined;
  Main: undefined;
  NewTransaction: undefined;
  TransactionDetail: { transactionId: string };
};

export type MainTabParamList = {
  Home: undefined;
  Transactions: undefined;
  SyncDashboard: undefined;
  Settings: undefined;
};

const Stack = createNativeStackNavigator<RootStackParamList>();
const Tab = createBottomTabNavigator<MainTabParamList>();

function MainTabs() {
  return (
    <Tab.Navigator screenOptions={{ headerShown: false }}>
      <Tab.Screen name="Home" component={HomeScreen} />
      <Tab.Screen name="Transactions" component={TransactionListScreen} />
      <Tab.Screen name="SyncDashboard" component={SyncDashboardScreen} />
      <Tab.Screen name="Settings" component={SettingsScreen} />
    </Tab.Navigator>
  );
}

export default function AppNavigator() {
  const isAuthenticated = useSelector((state: RootState) => state.auth.isAuthenticated);

  return (
    <NavigationContainer>
      <Stack.Navigator screenOptions={{ headerShown: false }}>
        {!isAuthenticated ? (
          <Stack.Screen name="Login" component={LoginScreen} />
        ) : (
          <>
            <Stack.Screen name="Main" component={MainTabs} />
            <Stack.Screen name="NewTransaction" component={NewTransactionScreen} />
            <Stack.Screen name="TransactionDetail" component={TransactionDetailScreen} />
          </>
        )}
      </Stack.Navigator>
    </NavigationContainer>
  );
}
