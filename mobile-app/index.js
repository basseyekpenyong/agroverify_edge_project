import { AppRegistry } from 'react-native';
import React from 'react';
import { Provider } from 'react-redux';
import { store } from './src/store';
import AppNavigator from './src/navigation/AppNavigator';
import { name as appName } from './app.json';

function App() {
  return (
    <Provider store={store}>
      <AppNavigator />
    </Provider>
  );
}

AppRegistry.registerComponent(appName, () => App);
