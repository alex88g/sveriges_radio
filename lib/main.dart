import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';

// Huvudfunktionen som kör appen.
void main() => runApp(MyApp());

// Klassen Channel representerar en radiokanal.
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

  // Factory-konstruktor för att skapa en Channel från en JSON-struktur.
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

// MyApp är roten för din applikation.
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // MaterialApp är rotnoden i din app som innehåller teman och navigation.
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

// MyScreen är skärmen som visar en lista över kanaler.
class MyScreen extends StatefulWidget {
  @override
  _MyScreenState createState() => _MyScreenState();
}

// _MyScreenState är tillståndet för MyScreen.
class _MyScreenState extends State<MyScreen> with TickerProviderStateMixin {
  List<Channel> channels = [];
  late Map<int, AnimationController> _animationControllers;

  // initState körs när widgeten först skapas.
  @override
  void initState() {
    super.initState();
    fetchData();
    _animationControllers = {};
  }

  // dispose körs när widgeten tas bort från trädstrukturen.
  @override
  void dispose() {
    // AnimationController-objekten måste tas bort för att frigöra resurser.
    _animationControllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  // fetchData hämtar kanaldata från ett API.
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
      // Om datan inte kunde hämtas kastas ett undantag.
      throw Exception('Failed to load channel data');
    }
  }

  // _initializeAnimationControllers skapar en AnimationController för varje kanalkort.
  void _initializeAnimationControllers() {
    channels.forEach((channel) {
      _animationControllers[channel.id] = AnimationController(
        duration: const Duration(milliseconds: 200),
        vsync: this,
      );
    });
  }

  // _playAnimation kör en animation när ett kort trycks.
  void _playAnimation(int id) async {
    if (_animationControllers[id] != null) {
      _animationControllers[id]!.forward().then((_) {
        _animationControllers[id]!.reverse();
      });
    }
  }

  // build bygger användargränssnittet för MyScreen.
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

  // _buildCard skapar ett kort för en enskild kanal.
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

// RadioPlayerScreen är skärmen som spelar upp ljud för en kanal.
class RadioPlayerScreen extends StatefulWidget {
  final Channel channel;

  RadioPlayerScreen({Key? key, required this.channel}) : super(key: key);

  @override
  _RadioPlayerScreenState createState() => _RadioPlayerScreenState();
}

// _RadioPlayerScreenState är tillståndet för RadioPlayerScreen.
class _RadioPlayerScreenState extends State<RadioPlayerScreen> with SingleTickerProviderStateMixin {
  late AudioPlayer _audioPlayer;
  late AnimationController _animationController;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  // initState körs när widgeten först skapas.
  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    // Lägg till lyssnare för förändringar i ljudströmmens längd och position.
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

    // Spela upp ljudet.
    _playRadio();
  }

  // _playRadio startar uppspelningen av ljudströmmen.
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

  // dispose körs när widgeten tas bort från trädstrukturen.
  @override
  void dispose() {
    _audioPlayer.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // _togglePlay växlar uppspelningsstatus mellan spela och pausa.
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

  // _fastForward spolar framåt i ljudströmmen med 10 sekunder.
  Future<void> _fastForward() async {
    final newPosition = _position + Duration(seconds: 10);
    if (newPosition < _duration) {
      await _audioPlayer.seek(newPosition);
    }
  }

  // _rewind spolar bakåt i ljudströmmen med 10 sekunder.
  Future<void> _rewind() async {
    final newPosition = _position - Duration(seconds: 10);
    if (newPosition > Duration.zero) {
      await _audioPlayer.seek(newPosition);
    } else {
      await _audioPlayer.seek(Duration.zero);
    }
  }

  // build bygger användargränssnittet för RadioPlayerScreen.
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
