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
import {View, TouchableOpacity, StyleSheet, Button, Text} from 'react-native';
import {Appbar, Avatar, Card, Title, Paragraph} from 'react-native-paper';
import {NavigationContainer} from '@react-navigation/native';
import {createStackNavigator} from '@react-navigation/stack';

const styles = StyleSheet.create({
  header: {
    backgroundColor: 'gray',
  },
  container: {
    flex: 1,
    justifyContent: 'center',
  },
  avatar: {
    // flex: 1,
    // flexDirection: 'row',
    justifyContent: 'center',
    alignItems: 'center',
  },
});

const Stack = createStackNavigator();

const HomeScreen = ({navigation}) => {
  return (
    <View style={styles.container}>
      <TouchableOpacity
        style={styles.avatar}
        activeOpacity={0.4}
        onPress={() => navigation.navigate('Profile', {name: 'Barbara'})}>
        <Avatar.Image size={180} source={require('../assets/avatar.png')} />
        <Button
          title="Go to Barbara's profile"
          onPress={() => navigation.navigate('Profile', {name: 'Barbara'})}
        />
      </TouchableOpacity>
    </View>
  );
};

const ProfileScreen = () => {
  return (
    // <FlatList
    <TouchableOpacity activeOpacity={0.4}>
      <Card>
        <Card.Content>
          <Title>Life Album</Title>
          <Paragraph>Card content</Paragraph>
        </Card.Content>
      </Card>
    </TouchableOpacity>
    // />
  );
};

const App = () => {
  return (
    // <View>
    //   <Appbar.Header style={styles.header}>
    //     {/* <Appbar.BackAction onPress={() => {}} /> */}
    //     <Appbar.Content title="Hello Barbara" />
    //   </Appbar.Header>
    //   <View style={styles.container}>
    //     <TouchableOpacity
    //       activeOpacity={0.4}
    //       onPress={() => navigation.navigate('Home')}>
    //       <Avatar.Image size={180} source={require('./assets/avatar.png')} />
    //     </TouchableOpacity>
    //   </View>
    // </View>
    <NavigationContainer>
      <Stack.Navigator>
        <Stack.Screen name="Home" component={HomeScreen} />
        <Stack.Screen name="Profile" component={ProfileScreen} />
      </Stack.Navigator>
    </NavigationContainer>
  );
};

export default App;
