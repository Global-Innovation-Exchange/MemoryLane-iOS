// Import React, necessary UI modules from React native
import React from 'react';
import {StyleSheet, Text, View, TouchableOpacity, Alert} from 'react-native';
import {
  NavigationParams,
  NavigationScreenProp,
  NavigationState,
} from 'react-navigation';

const _showAlert = (navigation: any) => {
  Alert.alert(
    'Casting to TV',
    'In order to continue you need to cast content to a smart TV. Please follow the instruction',
    [
      {text: 'Cancel', onPress: () => {}, style: 'cancel'},
      {text: 'OK', onPress: () => navigation.navigate('Theme Selection')},
    ],
    {cancelable: false},
  );
};

var personName = 'Barbara';

interface Props {
  navigation: NavigationScreenProp<NavigationState, NavigationParams>;
}

const WelcomeScreen = ({navigation}: Props) => {
  return (
    <View style={styles.container}>
      {/* the screen title bar*/}
      <View style={styles.welcomeContainer}>
        <Text style={styles.welcomeText}>Welcome {personName},</Text>

        <Text style={styles.welcomeText}>
          Are you ready for some good time?
        </Text>
      </View>

      {/* content section*/}

      {/* controller btn lists */}
      <View style={styles.ControlsBtnsSection}>
        <TouchableOpacity
          style={styles.btnDesign}
          onPress={_showAlert.bind(null, navigation)}>
          <Text style={styles.btnText}>Start</Text>
        </TouchableOpacity>
      </View>
    </View>
  );
};

// Add some simple styles
const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#fff',
    alignItems: 'center',
    justifyContent: 'center',
  },

  welcomeContainer: {
    alignItems: 'center',
    justifyContent: 'center',
    marginTop: 10,
    marginBottom: 20,
    height: 50,
  },
  welcomeText: {
    fontSize: 36,
    fontWeight: '700',
    color: 'black',
  },

  ControlsBtnsSection: {
    justifyContent: 'center',
    alignItems: 'center',
  },
  btnDesign: {
    borderWidth: 0,
    alignItems: 'center',
    justifyContent: 'center',
    alignSelf: 'center',
    width: 300,
    height: 140,
    margin: 10,
    borderRadius: 10,
    backgroundColor: '#ADD9D5',
    marginTop: 90,
  },

  btnText: {
    fontSize: 33,
  },
});

export default WelcomeScreen;
