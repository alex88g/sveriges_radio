import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';

// Main function that runs the app.
void main() => runApp(MyApp());

// Class Channel represents the Model in MVVM.
class Channel {
  final int id;
  final String name;
  final String imageUrl;
  final String color;
  final String tagline;
  final String siteUrl;
  final String streamUrl;
  final String scheduleUrl;
  final String channelType;

  Channel({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.color,
    required this.tagline,
    required this.siteUrl,
    required this.streamUrl,
    required this.scheduleUrl,
    required this.channelType,
  });

  // Factory constructor to create a Channel from JSON data.
  factory Channel.fromJson(Map<String, dynamic> json) {
    return Channel(
      id: json['id'],
      name: json['name'],
      imageUrl: json['image'] ?? '',
      color: json['color'] ?? 'FFFFFF',
      tagline: json['tagline'] ?? '',
      siteUrl: json['siteurl'] ?? '',
      streamUrl: json['liveaudio'] != null ? json['liveaudio']['url'] : '',
      scheduleUrl: json['scheduleurl'] ?? '',
      channelType: json['channeltype'] ?? 'Unknown',
    );
  }
}

// MyApp is the root of your application.
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // MaterialApp is the root node in your app that contains themes and navigation.
    return MaterialApp(
      title: 'Radio Station App',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        hintColor: Colors.tealAccent,
        cardTheme: CardTheme(
          elevation: 8.0,
          margin: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        textTheme: TextTheme(
          headline5: TextStyle(fontWeight: FontWeight.bold),
          subtitle1: TextStyle(color: Colors.grey[600]),
        ),
      ),
      home: MyScreen(),
    );
  }
}

// MyScreen is the screen that displays a list of channels.
class MyScreen extends StatefulWidget {
  @override
  _MyScreenState createState() => _MyScreenState();
}

// _MyScreenState is the state for MyScreen, serving as the ViewModel in MVVM.
class _MyScreenState extends State<MyScreen> with TickerProviderStateMixin {
  // List of channels is part of the ViewModel.
  List<Channel> channels = [];
  // AnimationControllers are part of the ViewModel.
  late Map<int, AnimationController> _animationControllers;

  // This method is called when the widget is first created.
  @override
  void initState() {
    super.initState();
    fetchData();
    _animationControllers = {};
  }

  // This method is called when the widget is removed from the widget tree.
  @override
  void dispose() {
    // Dispose of AnimationController objects to release resources.
    _animationControllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  // This method fetches data from an API, which is a ViewModel responsibility.
  Future<void> fetchData() async {
    final response = await http.get(Uri.parse('http://api.sr.se/api/v2/channels?format=json&pagination=false'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<Channel> fetchedChannels = (data['channels'] as List)
          .map((channelJson) => Channel.fromJson(channelJson))
          .toList();
      setState(() {
        channels = fetchedChannels;
        _initializeAnimationControllers();
      });
    } else {
      // Throw an exception if data cannot be fetched.
      throw Exception('Failed to load channel data');
    }
  }

  // This method initializes AnimationController objects for each channel card.
  void _initializeAnimationControllers() {
    channels.forEach((channel) {
      _animationControllers[channel.id] = AnimationController(
        duration: const Duration(milliseconds: 200),
        vsync: this,
      );
    });
  }

  // This method plays an animation when a card is tapped.
  void _playAnimation(int id) async {
    if (_animationControllers[id] != null) {
      _animationControllers[id]!.forward().then((_) {
        _animationControllers[id]!.reverse();
      });
    }
  }

  // This method builds the user interface for MyScreen, which is the View.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Swedish Radio Channels")),
      body: channels.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: channels.length,
              itemBuilder: (context, index) {
                return _buildCard(channels[index]);
              },
            ),
    );
  }

  // This method builds a card for an individual channel.
  Widget _buildCard(Channel channel) {
    final Animation<double> scaleAnimation = Tween(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _animationControllers[channel.id]!,
        curve: Curves.easeInOut,
      ),
    );

    return GestureDetector(
      onTap: () {
        _playAnimation(channel.id);
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => RadioPlayerScreen(channel: channel),
        ));
      },
      child: AnimatedBuilder(
        animation: _animationControllers[channel.id]!,
        builder: (context, child) {
          return Transform.scale(
            scale: scaleAnimation.value,
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(10),
                child: Row(
                  children: [
                    ClipOval(
                      child: Image.network(
                        channel.imageUrl,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                      ),
                    ),
                    SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(channel.name, style: Theme.of(context).textTheme.headline5),
                          SizedBox(height: 5),
                          Text(
                            channel.tagline,
                            style: Theme.of(context).textTheme.subtitle1,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// RadioPlayerScreen is the screen that plays audio for a channel.
class RadioPlayerScreen extends StatefulWidget {
  final Channel channel;

  RadioPlayerScreen({Key? key, required this.channel}) : super(key: key);

  @override
  _RadioPlayerScreenState createState() => _RadioPlayerScreenState();
}

// _RadioPlayerScreenState is the state for RadioPlayerScreen, serving as the ViewModel in MVVM.
class _RadioPlayerScreenState extends State<RadioPlayerScreen> with SingleTickerProviderStateMixin {
  // AudioPlayer and related variables are part of the ViewModel.
  late AudioPlayer _audioPlayer;
  late AnimationController _animationController;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  // This method is called when the widget is first created.
  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    // Add listeners for changes in audio stream duration and position.
    _audioPlayer.onDurationChanged.listen((newDuration) {
      setState(() {
        _duration = newDuration;
      });
    });

    _audioPlayer.onPositionChanged.listen((newPosition) {
      setState(() {
        _position = newPosition;
      });
    });

    // Start playing the audio.
    _playRadio();
  }

  // This method starts the playback of the audio stream.
  Future<void> _playRadio() async {
    try {
      await _audioPlayer.setSource(UrlSource(widget.channel.streamUrl));
      await _audioPlayer.resume();
      setState(() {
        _isPlaying = true;
      });
    } catch (e) {
      print('Error setting audio source: $e');
    }
  }

  // This method is called when the widget is removed from the widget tree.
  @override
  void dispose() {
    _audioPlayer.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // This method toggles the playback status between play and pause.
  void _togglePlay() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.resume();
    }
    setState(() {
      _isPlaying = !_isPlaying;
    });
  }

  // This method fast-forwards the audio stream by 10 seconds.
  Future<void> _fastForward() async {
    final newPosition = _position + Duration(seconds: 10);
    if (newPosition < _duration) {
      await _audioPlayer.seek(newPosition);
    }
  }

  // This method rewinds the audio stream by 10 seconds.
  Future<void> _rewind() async {
    final newPosition = _position - Duration(seconds: 10);
    if (newPosition > Duration.zero) {
      await _audioPlayer.seek(newPosition);
    } else {
      await _audioPlayer.seek(Duration.zero);
    }
  }

  // This method builds the user interface for RadioPlayerScreen, which is the View.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.channel.name),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (widget.channel.imageUrl.isNotEmpty)
              Image.network(
                widget.channel.imageUrl,
                width: 120,
                height: 120,
                fit: BoxFit.cover,
              ),
            SizedBox(height: 20),
            Text(
              widget.channel.name,
              style: Theme.of(context).textTheme.headline5,
            ),
            Text(
              "${_position.toString().split('.').first} / ${_duration.toString().split('.').first}",
              style: TextStyle(fontSize: 24),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(Icons.replay_10),
                  onPressed: _rewind,
                ),
                IconButton(
                  iconSize: 64.0,
                  icon: AnimatedIcon(
                    icon: AnimatedIcons.play_pause,
                    progress: _animationController,
                  ),
                  onPressed: () {
                    _togglePlay();
                    if (_isPlaying) {
                      _animationController.forward();
                    } else {
                      _animationController.reverse();
                    }
                  },
                ),
                IconButton(
                  icon: Icon(Icons.forward_10),
                  onPressed: _fastForward,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
