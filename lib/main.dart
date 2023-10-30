import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.teal,
        hintColor: Colors.tealAccent,
        cardTheme: CardTheme(
          elevation: 8.0, // Increased the elevation for more depth
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

class MyScreen extends StatefulWidget {
  @override
  _MyScreenState createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> {
  List<dynamic> scheduleData = [];

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    final response = await http.get(Uri.parse(
        'https://api.sr.se/api/v2/scheduledepisodes?channelid=164&format=json'));
    if (response.statusCode == 200) {
      setState(() {
        scheduleData = json.decode(response.body)['schedule'];
      });
    } else {
      throw Exception('Failed to load data');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Schedule App")),
      body: scheduleData.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: scheduleData.length,
              itemBuilder: (context, index) {
                final item = scheduleData[index];
                final imageUrl = item['imageurl'];

                return Transform(
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001) // perspective
                    ..rotateY(-0.05), // slight Y axis rotation for 3D effect
                  child: Card(
                    child: Padding(
                      padding: EdgeInsets.all(10),
                      child: Row(
                        children: [
                          // Image display with placeholder if no image
                          if (imageUrl != null && imageUrl.isNotEmpty)
                            ClipOval(
                              child: Image.network(
                                imageUrl,
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                              ),
                            )
                          else
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.image_not_supported, color: Colors.grey[500]),
                            ),
                          
                          SizedBox(width: 15), // spacing

                          // Title and description
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item['title'] ?? '', style: Theme.of(context).textTheme.headline5),
                                SizedBox(height: 5),
                                Text(item['description'] ?? '', style: Theme.of(context).textTheme.subtitle1, maxLines: 2, overflow: TextOverflow.ellipsis),
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
