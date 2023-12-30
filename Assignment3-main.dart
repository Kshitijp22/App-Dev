import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class Album {
  final int userId;
  final int id;
  final String title;

  Album({
    required this.userId,
    required this.id,
    required this.title,
  });

  factory Album.fromJson(Map<String, dynamic> json) {
    return Album(
      userId: json['userId'] as int,
      id: json['id'] as int,
      title: json['title'] as String,
    );
  }
}

Future<List<Album>> fetchAlbum() async {
  final response =
      await http.get(Uri.parse('https://jsonplaceholder.typicode.com/albums'));

  if (response.statusCode == 200) {
    List<dynamic> data = jsonDecode(response.body);
    List<Album> albums = data.map((json) => Album.fromJson(json)).toList();
    return albums;
  } else {
    throw Exception('Failed to load albums');
  }
}

Future<Album> createAlbum(String title) async {
  final response = await http.post(
    Uri.parse('https://jsonplaceholder.typicode.com/albums'),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode(<String, String>{
      'title': title,
    }),
  );

  if (response.statusCode == 201) {
    // If the server did return a 201 CREATED response,
    // then parse the JSON.
    return Album.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  } else {
    // If the server did not return a 201 CREATED response,
    // then throw an exception.
    throw Exception('Failed to create album.');
  }
}

Future<void> deleteAlbum(
    int id, List<Album> albumList, Function setState) async {
  final response = await http.delete(
    Uri.parse('https://jsonplaceholder.typicode.com/albums/$id'),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
  );

  if (response.statusCode == 200) {
    albumList.removeWhere((album) => album.id == id);
    setState(() {
      print('Album deleted successfully');
    });
  } else {
    throw Exception('Failed to delete album');
  }
}

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Future<List<Album>> futureAlbum;
  final TextEditingController _title = TextEditingController();

  @override
  void initState() {
    super.initState();
    futureAlbum = fetchAlbum();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Album App',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
      ),
      home: Scaffold(
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            _showAddAlbumDialog();
          },
          child: Icon(Icons.add),
        ),
        appBar: AppBar(
          title: const Text('Album App'),
        ),
        body: Center(
          child: FutureBuilder<List<Album>>(
            future: futureAlbum,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                List<Album> albumList = snapshot.data!;
                return ListView.builder(
                  itemCount: albumList.length,
                  itemBuilder: (context, index) {
                    Album album = albumList[index];
                    return Card(
                      elevation: 3,
                      child: ListTile(
                        title: Text(album.title),
                        subtitle: Text('ID: ${album.id}'),
                        trailing: IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () async {
                            await deleteAlbum(album.id, albumList, setState);
                          },
                        ),
                      ),
                    );
                  },
                );
              } else if (snapshot.hasError) {
                return Text('${snapshot.error}');
              }

              return const CircularProgressIndicator();
            },
          ),
        ),
      ),
    );
  }

  Future<void> _showAddAlbumDialog() async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add New Album'),
          content: TextField(
            controller: _title,
            decoration: InputDecoration(labelText: 'Album Title'),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Add'),
              onPressed: () async {
                Navigator.of(context).pop();
                await createAlbum(_title.text.toString());
                setState(() {
                  futureAlbum = fetchAlbum();
                });
              },
            ),
          ],
        );
      },
    );
  }
}
