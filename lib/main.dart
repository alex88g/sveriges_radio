import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';

void main() => runApp(MyApp());

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

// MyApp is the root widget that initializes the app theme and home screen.
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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

// MyScreen is the main screen widget that displays the list of data.
class MyScreen extends StatefulWidget {
  @override
  _MyScreenState createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> {
  List<Channel> channels = []; // Holds the fetched channel data.

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    final response = await http.get(Uri.parse('http://api.sr.se/api/v2/channels?format=json&pagination=false'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<Channel> fetchedChannels = (data['channels'] as List)
          .map((channelJson) => Channel.fromJson(channelJson))
          .toList();
      setState(() {
        channels = fetchedChannels;
      });
    } else {
      throw Exception('Failed to load channel data');
    }
  }
  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Swedish Radio Channels")),
      body: channels.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: channels.length,
              itemBuilder: (context, index) {
                return _buildCard(channels[index]); // This will call _buildCard for each channel
              },
            ),
    );
  }

  // Creates a 3D effect for the card.
  Matrix4 _3dEffectTransform() {
    return Matrix4.identity()
      ..setEntry(3, 2, 0.001)
      ..rotateY(-0.05);
  }
   // Constructs a card for displaying an individual channel.
  Widget _buildCard(Channel channel) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => RadioPlayerScreen(radioUrl: channel.streamUrl),
        ));
      },
      child: Transform(
        transform: _3dEffectTransform(),
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(10),
            child: Row(
              children: [
                _buildImage(channel.imageUrl),
                SizedBox(width: 15),
                _buildTextContent(channel),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Displays the image of the schedule item or a placeholder if no image is available.
 Widget _buildImage(String imageUrl) {
  print('Image URL: $imageUrl'); // Log the URL to the console for debugging
  if (imageUrl.isNotEmpty) {
    return ClipOval(
      child: Image.network(
        imageUrl,
        width: 60,
        height: 60,
        fit: BoxFit.cover,
      ),
    );
  } else {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.image_not_supported, color: Colors.grey[500]),
    );
  }
}

  // Constructs the text content (title and description) of the schedule item.
  Widget _buildTextContent(Channel channel) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(channel.name, style: Theme.of(context).textTheme.headline5),
          SizedBox(height: 5),
          Text(channel.tagline, style: Theme.of(context).textTheme.subtitle1, maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

// RadioPlayerScreen is a new screen that will play the radio station.
class RadioPlayerScreen extends StatefulWidget {
  final String radioUrl;

  // Mark the radioUrl as required using the required keyword.
  RadioPlayerScreen({Key? key, required this.radioUrl}) : super(key: key);
  Future<String?> _getAudioUrl() async {
  try {
    final response = await http.get(Uri.parse('http://api.sr.se/api/v2/audiourltemplates/liveaudiotypes'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final audioUrl = data['url'] as String?;
      return audioUrl;
    } else {
      throw Exception('Failed to load audio URL');
    }
  } catch (e) {
    print('Error fetching audio URL: $e');
    return null;
  }
}

  @override
  _RadioPlayerScreenState createState() => _RadioPlayerScreenState();
}

class _RadioPlayerScreenState extends State<RadioPlayerScreen> {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _playRadio();
  }

 Future<void> _playRadio() async {
  try {
    // Set the source of the audio to the provided URL and then play
    await _audioPlayer.setSource(UrlSource(widget.radioUrl));
    setState(() {
      _isPlaying = true;
    });
  } catch (e) {
    // Handle the error, possibly indicating that the URL is not valid
    print('Error setting audio source: $e');
  }
}
  @override
  void dispose() {
    _audioPlayer.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Radio Player'),
      ),
      body: Center(
        child: IconButton(
          icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
          onPressed: () {
            if (_isPlaying) {
              _audioPlayer.pause();
            } else {
              _audioPlayer.resume();
            }
            setState(() {
              _isPlaying = !_isPlaying;
            });
          },
        ),
      ),
    );
  }
}
