// Import React, necessary UI modules from React native
import React, {useState} from 'react';
import {
  SectionList,
  StyleSheet,
  Text,
  View,
  TouchableOpacity,
} from 'react-native';
import {
  NavigationParams,
  NavigationScreenProp,
  NavigationState,
} from 'react-navigation';

// Themes btns data (lists)
const fixedThemes = [
  {
    id: 1,
    name: 'Life Album',
    btncolor: '#9B3D3D',
  },
  {
    id: 2,
    name: 'Favorites',
    btncolor: '#6E8D71',
  },
  {
    id: 3,
    name: 'Random',
    btncolor: '#8EEEE5',
  },
];

const CommonThemes = [
  {
    id: 4,
    name: 'Music Industry',
    btncolor: '#D08363',
  },
  {
    id: 5,
    name: 'Television',
    btncolor: '#ACB9E8',
  },
  {
    id: 6,
    name: 'Reading',
    btncolor: '#F0DFBB',
  },
];

const SuggestedThemes = [
  {
    id: 7,
    name: 'Hobbies',
    btncolor: '#FDB367',
  },
  {
    id: 8,
    name: 'Traditions',
    btncolor: '#FBF6C2',
  },
  {
    id: 9,
    name: 'Natural Life',
    btncolor: '#E69C9E',
  },
];

interface Props {
  navigation: NavigationScreenProp<NavigationState, NavigationParams>;
}

const ThemeScreen = ({navigation}: Props) => {
  const [, setSelectedTheme] = useState('');
  return (
    <View style={styles.container}>
      {/* the screen title bar*/}
      <View style={styles.welcomeContainer}>
        <Text style={styles.welcomeText}>Hello</Text>
      </View>

      {/* content section*/}
      <View style={styles.controlContainer}>
        <View style={styles.promptCastSection}>
          {/* promote choosing a theme*/}
          <View style={styles.promotContainer}>
            <Text style={styles.controlText}>
              {' '}
              What theme do you want to explore?{' '}
            </Text>
          </View>

          {/* stop casting btn*/}
          {/* <TouchableOpacity>
            <View style={styles.controlCast}>
              <Feather name={'cast'}
                size={40}
                color="black" />
              <Text style={styles.castText}> stop TV </Text>
            </View>
          </TouchableOpacity> */}
        </View>

        {/* theme btn lists */}
        <View style={styles.ControlsBtnsSection}>
          <SectionList
            horizontal
            sections={[
              {
                title: '',
                data: fixedThemes,
                renderItem: ({item}) => (
                  <TouchableOpacity
                    style={[styles.btnDesign, {backgroundColor: item.btncolor}]}
                    onPress={() => setSelectedTheme(item.name)}>
                    <Text style={styles.btnText}>{item.name}</Text>
                  </TouchableOpacity>
                ),
              },
            ]}
            keyExtractor={(item, index) => item.name + index}
          />

          <SectionList
            horizontal
            sections={[
              {
                title: '',
                data: CommonThemes,
                renderItem: ({item}) => (
                  <TouchableOpacity
                    style={[styles.btnDesign, {backgroundColor: item.btncolor}]}
                    onPress={() => setSelectedTheme(item.name)}>
                    <Text style={styles.btnText}>{item.name}</Text>
                  </TouchableOpacity>
                ),
              },
            ]}
            keyExtractor={(item, index) => item.name + index}
          />

          <SectionList
            horizontal
            sections={[
              {
                title: '',
                data: SuggestedThemes,
                renderItem: ({item}) => (
                  <TouchableOpacity
                    style={[styles.btnDesign, {backgroundColor: item.btncolor}]}
                    onPress={() => {
                      setSelectedTheme(item.name);
                      navigation.navigate('Player');
                    }}>
                    <Text style={styles.btnText}>{item.name}</Text>
                  </TouchableOpacity>
                ),
              },
            ]}
            keyExtractor={(item, index) => item.name + index}
          />
        </View>
      </View>
    </View>
  );
};

// // Create and export Home screen component
// export default class ThemeScreen extends React.Component {
//   static navigationOptions = {
//     header: null, // disable app header
//   };

//   state = {
//     selectedTheme: '',
//   };

//   render() {

//   }
// }

// Add some simple styles
const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#fff',
    // marginTop: Constants.statusBarHeight,
  },

  welcomeContainer: {
    alignItems: 'center',
    marginTop: 10,
    marginBottom: 20,
    height: 50,
    backgroundColor: '#E3E1E1',
  },
  welcomeText: {
    fontSize: 36,
    fontWeight: '700',
    color: 'black',
  },

  controlContainer: {
    marginHorizontal: 20,
    borderWidth: 2,
    borderColor: '#EDD5A6',
  },
  controlText: {
    fontSize: 40,
    textAlign: 'center',
    justifyContent: 'center',
    marginTop: 20,
  },
  castText: {
    fontSize: 17,
  },
  promptCastSection: {
    justifyContent: 'space-between',
    flexDirection: 'row',
    marginBottom: 20,
  },
  controlCast: {
    alignItems: 'center',
    justifyContent: 'center',
    marginTop: 5,
  },
  promotContainer: {flexGrow: 1},

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
  },

  btnText: {
    fontSize: 33,
  },
});

export default ThemeScreen;