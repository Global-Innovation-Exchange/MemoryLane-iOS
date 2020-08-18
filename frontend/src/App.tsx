/**
 * Sample React Native App
 * https://github.com/facebook/react-native
 *
 * Generated with the TypeScript template
 * https://github.com/react-native-community/react-native-template-typescript
 *
 * @format
 */

import React from 'react';
import {NavigationContainer} from '@react-navigation/native';
import {createStackNavigator} from '@react-navigation/stack';
import Player from './screens/player';
import WelcomeScreen from './screens/welcome';
import ThemeScreen from './screens/theme';

const RootStack = createStackNavigator();

const App = () => {
  return (
    <NavigationContainer>
      <RootStack.Navigator>
        <RootStack.Screen name="Home" component={WelcomeScreen} />
        <RootStack.Screen name="Theme Selection" component={ThemeScreen} />
        <RootStack.Screen name="Player" component={Player} />
      </RootStack.Navigator>
    </NavigationContainer>
  );
};

export default App;
