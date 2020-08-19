// Import React, necessary UI modules from React native
import React from 'react';
import {
  SectionList,
  StyleSheet,
  Text,
  View,
  TouchableOpacity,
} from 'react-native';
import MaterialIcons from 'react-native-vector-icons/MaterialIcons';
import AntDesign from 'react-native-vector-icons/AntDesign';
import Feather from 'react-native-vector-icons/Feather';
import GoogleCast, {CastButton} from 'react-native-google-cast';

// btns controls data (lists)
///////////////////////////////// this part updated starting here //////////////
const volControls = [
  {
    id: 1,
    name: 'Voulme -',
    icon: 'volume-1',
    btncolor: '#8EEEE5',
  },
  {
    id: 2,
    name: 'Volume +',
    icon: 'volume-2',
    btncolor: '#D08363',
  },
];

const conControl = [
  {
    id: 1,
    name: 'Previous',
    icon: 'skip-previous',
    btncolor: '#ACB9E8',
  },
  {
    id: 2,
    name: 'Pause',
    icon: 'pause',
    btncolor: '#F0DFBB',
  },
  {
    id: 3,
    name: 'Next',
    icon: 'skip-next',
    btncolor: '#FDB367',
  },
];

const leaveControls = [
  {
    id: 1,
    name: 'EXIT',
    btncolor: '#9B3D3D',
  },
  {
    id: 2,
    name: 'HOME',
    btncolor: '#6E8D71',
  },
];

const feedbackControls = [
  {
    id: 1,
    name: 'Like',
    icon: 'like2',
    btncolor: '#FBF6C2',
    feedbackIcon: 'like1',
    clicked: false,
  },
  {
    id: 2,
    name: 'Dislike',
    icon: 'dislike2',
    btncolor: '#E69C9E',
    feedbackIcon: 'dislike1',
    clicked: false,
  },
  {
    id: 3,
    name: 'Favorite',
    icon: 'staro',
    btncolor: '#D2D2D2',
    feedbackIcon: 'star',
    clicked: false,
  },
];

// Create and export Home screen component
class ControllerScreen extends React.Component {
  constructor(props: any) {
    super(props);
    this.cast = this.cast.bind(this);
    const data = require('../content.json');
    this.state = {
      videos: data.categories[0].videos.map((video) => ({
        title: video.title,
        subtitle: video.subtitle,
        studio: video.identifier,
        duration: video.streamDuration,
        contentType: video.contentType,
        mediaUrl: video.mediaUrl,
        imageUrl: video.imageUrl,
        playPosition: video.playPosition,
      })),
      playingTitle: '',
      volume: 10,
      selectedButton: 'all',
      paused: false,
      liked: false,
      disliked: false,
      fav: false,
    };
  }

  static navigationOptions = {
    header: null, // disable app header
  };

  componentDidMount() {
    this.registerListeners();
    this.cast(0);
  }

  cast(index) {
    const {videos} = this.state;
    // GoogleCast.getCastDevice().then(console.log);
    GoogleCast.castMedia(videos[index]);
    this.setState({playingTitle: videos[index].title});
    this.sendMessage();
  }

  sendMessage() {
    const channel = 'urn:x-cast:com.reactnative.googlecast.example';
    GoogleCast.initChannel(channel)
      .then(() => {
        GoogleCast.sendMessage(channel, JSON.stringify({message: 'Hello'}));
      })
      .then(null, (err) => console.log('err: ', err));
  }

  registerListeners() {
    const events = `
      SESSION_STARTING SESSION_STARTED SESSION_START_FAILED SESSION_SUSPENDED
      SESSION_RESUMING SESSION_RESUMED SESSION_ENDING SESSION_ENDED
      MEDIA_STATUS_UPDATED MEDIA_PLAYBACK_STARTED MEDIA_PLAYBACK_ENDED MEDIA_PROGRESS_UPDATED
      CHANNEL_CONNECTED CHANNEL_DISCONNECTED CHANNEL_MESSAGE_RECEIVED
    `
      .trim()
      .split(/\s+/);
    // console.log(events);
    events.forEach((event) => {
      GoogleCast.EventEmitter.addListener(GoogleCast[event], function () {
        // console.log(event, arguments);
      });
    });
  }
  handleChange = (item: any) => {
    console.log(item.name);
    if (item.name === 'Favorite' && this.state.fav === false) {
      this.setState({fav: true});
    } else if (item.name === 'Favorite' && this.state.fav === true) {
      this.setState({fav: false});
    }
    if (item.name === 'Like' && this.state.liked === false) {
      this.setState({liked: true, disliked: false});
    } else if (item.name === 'Like' && this.state.liked === true) {
      this.setState({liked: false});
    }
    if (item.name === 'Dislike' && this.state.disliked === false) {
      this.setState({disliked: true, liked: false});
    } else if (item.name === 'Dislike' && this.state.disliked === true) {
      this.setState({disliked: false});
    }
  };

  ////////// first part update ends here //////////////////////////////////

  selectedColor = '#EDD5A6'; //when media type selected

  render() {
    const {playingTitle} = this.state;
    console.log(playingTitle);
    return (
      <View style={styles.container}>
        {/* the screen title bar*/}
        <View style={styles.welcomeContainer}>
          <Text style={styles.welcomeText}>Theme: Your Favoritesrr</Text>
        </View>

        {/* Media Selection Nav*/}
        <View style={styles.navContainer}>
          <TouchableOpacity
            style={[
              styles.navItem,
              {
                backgroundColor:
                  this.state.selectedButton === 'audios'
                    ? this.selectedColor
                    : 'white',
              },
            ]}
            onPress={() => this.setState({selectedButton: 'audios'})}>
            <Text style={styles.navText}> Audios </Text>
          </TouchableOpacity>

          <TouchableOpacity
            style={[
              styles.navItem,
              {
                backgroundColor:
                  this.state.selectedButton === 'videos'
                    ? this.selectedColor
                    : 'white',
              },
            ]}
            onPress={() => this.setState({selectedButton: 'videos'})}>
            <Text style={styles.navText}> Videos </Text>
          </TouchableOpacity>

          <TouchableOpacity
            style={[
              styles.navItem,
              {
                backgroundColor:
                  this.state.selectedButton === 'photographs'
                    ? this.selectedColor
                    : 'white',
              },
            ]}
            onPress={() => this.setState({selectedButton: 'photographs'})}>
            <Text style={styles.navText}> Photographs </Text>
          </TouchableOpacity>
          <TouchableOpacity
            style={[
              styles.navItem,
              {
                backgroundColor:
                  this.state.selectedButton === 'all'
                    ? this.selectedColor
                    : 'white',
              },
            ]}
            onPress={() => this.setState({selectedButton: 'all'})}>
            <Text style={styles.navText}> All Media </Text>
          </TouchableOpacity>
        </View>

        {/* content section*/}
        <View style={styles.controlContainer}>
          <View style={styles.promptCastSection}>
            {/* prompt Q*/}
            <View style={styles.promotContainer}>
              <Text style={styles.controlText}>
                {' '}
                Have you ever watched this before?{' '}
              </Text>
            </View>

            {/* stop casting btn*/}
            <TouchableOpacity>
              <View style={styles.controlCast}>
                <CastButton style={styles.castButtonIOS} />
                <Text style={styles.castText}> stop TV </Text>
              </View>
            </TouchableOpacity>
          </View>

          {/* what's playing on TV section */}
          <View style={styles.playingContainer}>
            <Text style={styles.playingText}>
              {' '}
              Plyaing on TV: {playingTitle}{' '}
            </Text>
          </View>

          {/* controller btn lists */}
          <View style={styles.ControlsBtnsSection}>
            <View style={styles.btnSectionContainer}>
              <SectionList
                horizontal
                renderSectionHeader={({section: {title}}) => (
                  <Text>{title}</Text>
                )}
                sections={[
                  {
                    title: '',
                    data: volControls,
                    renderItem: ({item}) => (
                      <TouchableOpacity
                        style={[
                          styles.btnDesign,
                          {backgroundColor: item.btncolor},
                        ]}
                        onPress={() => {
                          GoogleCast.setVolume(10);
                        }}>
                        <Text style={styles.btnText}>{item.name}</Text>
                        <Feather name={item.icon} style={styles.iconStyle} />
                      </TouchableOpacity>
                    ),
                  },
                ]}
                keyExtractor={(item, index) => item.name + index}
              />
            </View>

            <View style={styles.btnSectionContainer}>
              {/*////////// second part update starts here //////////////////////////////////*/}
              <SectionList
                horizontal
                renderSectionHeader={({section: {title}}) => (
                  <Text>{title}</Text>
                )}
                sections={[
                  {
                    title: '',
                    data: conControl,
                    renderItem: ({item}) => (
                      <TouchableOpacity
                        style={[
                          styles.btnDesign,
                          {backgroundColor: item.btncolor},
                        ]}
                        onPress={() => {
                          if (item.name === 'Pause') {
                            if (this.state.paused === false) {
                              this.setState({paused: true});
                              GoogleCast.pause();
                            }
                            if (this.state.paused === true) {
                              this.setState({paused: false});
                              GoogleCast.play();
                            }
                          }
                          if (item.name === 'Next') {
                            this.cast(1);
                          } else if (item.name === 'Previous') {
                            this.cast(0);
                          }
                        }}>
                        <Text style={styles.btnText}>
                          {' '}
                          {item.name === 'Pause' && this.state.paused === true
                            ? 'Play'
                            : item.name}
                        </Text>
                        <MaterialIcons
                          name={
                            item.name === 'Pause' && this.state.paused === true
                              ? 'play-arrow'
                              : item.icon
                          }
                          style={styles.iconStyle}
                        />
                      </TouchableOpacity>
                    ),
                  },
                ]}
                keyExtractor={(item, index) => item.name + index}
              />

              {/*////////// second part update ends here //////////////////////////////////*/}
            </View>
          </View>

          <View style={styles.ControlsBtnsSection}>
            <View style={[styles.btnSectionContainer, {marginTop: 5}]}>
              <SectionList
                horizontal
                renderSectionHeader={({section: {title}}) => (
                  <Text>{title}</Text>
                )}
                sections={[
                  {
                    title: '',
                    data: leaveControls,
                    renderItem: ({item}) => (
                      <TouchableOpacity
                        style={[
                          styles.btnDesign,
                          {backgroundColor: item.btncolor},
                        ]}>
                        <Text style={[styles.btnText, {color: 'white'}]}>
                          {item.name}
                        </Text>
                      </TouchableOpacity>
                    ),
                  },
                ]}
                keyExtractor={(item, index) => item.name + index}
              />
            </View>
            <View style={[styles.btnSectionContainer, {marginTop: 5}]}>
              <SectionList
                horizontal
                renderSectionHeader={({section: {title}}) => (
                  <Text>{title}</Text>
                )}
                sections={[
                  {
                    title: '',
                    data: feedbackControls,
                    renderItem: ({item}) => (
                      <TouchableOpacity
                        style={[
                          styles.btnDesign,
                          {backgroundColor: item.btncolor},
                        ]}
                        onPress={() => this.handleChange(item)}>
                        <Text style={styles.btnText}>{item.name}</Text>
                        <AntDesign
                          name={
                            (item.name === 'Favorite' &&
                              this.state.fav === true) ||
                            (item.name === 'Like' &&
                              this.state.liked === true) ||
                            (item.name === 'Dislike' &&
                              this.state.disliked === true)
                              ? item.feedbackIcon
                              : item.icon
                          }
                          style={styles.iconStyle}
                        />
                      </TouchableOpacity>
                    ),
                  },
                ]}
                keyExtractor={(item, index) => item.name + index}
              />
            </View>
            {/* //////////////////////// third part updated ends here */}
          </View>
        </View>
      </View>
    );
  }
}

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
  navContainer: {
    alignItems: 'flex-start',
    flexDirection: 'row',
    marginHorizontal: 20,
  },
  welcomeText: {
    fontSize: 36,
    fontWeight: '700',
    color: 'black',
  },

  navItem: {
    borderWidth: 3,
    borderColor: '#EDD5A6',
    alignItems: 'center',
    justifyContent: 'center',
    width: 230,
    height: 65,
    marginRight: 15,
    borderRadius: 10,
    borderBottomLeftRadius: 0,
    borderBottomRightRadius: 0,
    borderBottomWidth: 0,
  },

  navText: {
    fontSize: 36,
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
  },
  controlCast: {
    alignItems: 'center',
    justifyContent: 'center',
    marginTop: 5,
  },
  promotContainer: {flexGrow: 1},
  playingContainer: {
    alignItems: 'center',
    justifyContent: 'center',
  },
  playingText: {
    fontSize: 30,
    fontWeight: 'bold',
    marginTop: 15,
  },

  ControlsBtnsSection: {
    justifyContent: 'space-between',
    flexDirection: 'row',
  },
  btnSectionContainer: {
    borderWidth: 3,
    borderRadius: 10,
    borderColor: '#EDD5A6',
    marginTop: 5,
    margin: 8,
    padding: 2,
  },
  btnDesign: {
    borderWidth: 0,
    alignItems: 'center',
    justifyContent: 'center',
    width: 160,
    height: 160,
    margin: 10,
    backgroundColor: '#fff',
    borderRadius: 160,
  },
  btnText: {
    fontSize: 33,
  },
  iconStyle: {
    fontSize: 50,
    color: 'black',
  },
  castButtonIOS: {
    height: 40,
    width: 40,
    marginRight: 10,
    alignSelf: 'flex-end',
    tintColor: 'black',
  },
});

export default ControllerScreen;
