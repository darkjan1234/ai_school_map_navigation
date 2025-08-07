import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(NavApp());
}

class NavApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Indoor Navigation',
      home: NavHomePage(),
    );
  }
}

class NavHomePage extends StatefulWidget {
  @override
  _NavHomePageState createState() => _NavHomePageState();
}

class _NavHomePageState extends State<NavHomePage> {
  final List<List<int>> map = [
    [0, 0, 0, 0, 1, 0],
    [1, 1, 1, 0, 1, 0],
    [0, 0, 0, 0, 0, 0],
    [0, 1, 1, 1, 1, 1],
    [0, 0, 0, 0, 0, 0],
  ];

  final List<List<int>> roomPositions = [
    [0, 0], [0, 3], [2, 0], [2, 5], [4, 0], [4, 5]
  ];

  int? startIndex;
  int? endIndex;
  List<List<int>> path = [];

  Future<void> fetchPath(List<int> start, List<int> end) async {
    // final uri = Uri.parse('http://10.0.2.2:5000/path'); 
    final uri = Uri.parse('http://192.168.110.229:5000/path');
    // final uri = Uri.parse('http://192.168.137.1:5000/path');
    final response = await http.post(uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'start': start, 'end': end}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        path = List<List<int>>.from(data['path'].map((e) => List<int>.from(e)));
      });
    } else {
      print('Error: ${response.statusCode}');
    }
  }

  bool isPathCell(int row, int col) {
    return path.any((pos) => pos[0] == row && pos[1] == col);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('AI Indoor Navigation')),
      body: Column(
        children: [
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              DropdownButton<int>(
                hint: Text('Start'),
                value: startIndex,
                onChanged: (val) => setState(() => startIndex = val),
                items: List.generate(roomPositions.length, (index) {
                  return DropdownMenuItem(
                    value: index,
                    child: Text('Room ${index + 1}'),
                  );
                }),
              ),
              DropdownButton<int>(
                hint: Text('Destination'),
                value: endIndex,
                onChanged: (val) => setState(() => endIndex = val),
                items: List.generate(roomPositions.length, (index) {
                  return DropdownMenuItem(
                    value: index,
                    child: Text('Room ${index + 1}'),
                  );
                }),
              ),
              ElevatedButton(
                onPressed: () {
                  if (startIndex != null && endIndex != null) {
                    fetchPath(roomPositions[startIndex!], roomPositions[endIndex!]);
                  }
                },
                child: Text('Navigate'),
              )
            ],
          ),
          SizedBox(height: 20),
          Expanded(
            child: GridView.builder(
              itemCount: map.length * map[0].length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: map[0].length,
              ),
              itemBuilder: (context, index) {
                int row = index ~/ map[0].length;
                int col = index % map[0].length;

                Color color;
                if (map[row][col] == 1) {
                  color = Colors.black;
                } else if (isPathCell(row, col)) {
                  color = Colors.green;
                } else {
                  color = Colors.white;
                }

                return Container(
                  margin: EdgeInsets.all(1),
                  color: color,
                  child: Center(
                    child: Text(''),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}
