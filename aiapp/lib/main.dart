import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'models/room.dart';
import 'map_screen.dart';
import 'pathfinding_service.dart';

void main() {
  runApp(NavApp());
}

class NavApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tupi SEAIT Navigation',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: NavHomePage(),
    );
  }

  Widget _buildRoomSelector(
    String label,
    Room? selectedRoom,
    Function(Room?) onChanged,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 8),
          if (selectedRoom != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  selectedRoom.name,
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  'Floor ${selectedRoom.floor} • ${selectedRoom.type}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 8),
                TextButton(
                  onPressed: () => onChanged(null),
                  child: Text('Clear'),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                  ),
                ),
              ],
            )
          else
            Text(
              'Tap a room below to select',
              style: TextStyle(
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (searchResults.isEmpty && !isSearching) {
      return Center(
        child: Text(
          'No rooms found for "${searchController.text}"',
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }

    return ListView.builder(
      itemCount: searchResults.length,
      itemBuilder: (context, index) {
        final room = searchResults[index];
        return _buildRoomTile(room);
      },
    );
  }

  Widget _buildRoomList() {
    if (building == null) return SizedBox();

    final allRooms = building!.getAllRooms();

    return ListView.builder(
      itemCount: allRooms.length,
      itemBuilder: (context, index) {
        final room = allRooms[index];
        return _buildRoomTile(room);
      },
    );
  }

  Widget _buildRoomTile(Room room) {
    final isStartRoom = room == startRoom;
    final isEndRoom = room == endRoom;

    return Card(
      margin: EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isStartRoom
              ? Colors.green
              : isEndRoom
                  ? Colors.red
                  : Colors.blue,
          child: Text(
            room.id,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        title: Text(room.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Floor ${room.floor} • ${room.type}'),
            if (room.department != null)
              Text(
                room.department!,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isStartRoom)
              IconButton(
                icon: Icon(Icons.play_arrow, color: Colors.green),
                onPressed: () => setState(() => startRoom = room),
                tooltip: 'Set as start',
              ),
            if (!isEndRoom)
              IconButton(
                icon: Icon(Icons.flag, color: Colors.red),
                onPressed: () => setState(() => endRoom = room),
                tooltip: 'Set as destination',
              ),
          ],
        ),
        onTap: () => _showRoomDetails(room),
      ),
    );
  }

  void _showRoomDetails(Room room) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(room.name),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDetailRow('Type', room.type),
            if (room.department != null)
              _buildDetailRow('Department', room.department!),
            _buildDetailRow('Floor', room.floor.toString()),
            _buildDetailRow('Position', '(${room.position.row}, ${room.position.col})'),
            _buildDetailRow('Accessible', room.isAccessible ? 'Yes' : 'No'),
            if (room.description != null)
              _buildDetailRow('Description', room.description!),
            if (room.amenities.isNotEmpty)
              _buildDetailRow('Amenities', room.amenities.join(', ')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
          if (room != startRoom)
            TextButton(
              onPressed: () {
                setState(() => startRoom = room);
                Navigator.pop(context);
              },
              child: Text('Set as Start'),
            ),
          if (room != endRoom)
            TextButton(
              onPressed: () {
                setState(() => endRoom = room);
                Navigator.pop(context);
              },
              child: Text('Set as Destination'),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}

class NavHomePage extends StatefulWidget {
  @override
  _NavHomePageState createState() => _NavHomePageState();
}

class _NavHomePageState extends State<NavHomePage> {
  Building? building;
  Room? startRoom;
  Room? endRoom;
  List<List<int>>? currentPath;
  List<Room> searchResults = [];
  bool isLoading = false;
  bool isSearching = false;
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSampleBuilding();
  }

  Future<void> _loadSampleBuilding() async {
    setState(() => isLoading = true);

    try {
      // Try to load from backend first
      final loadedBuilding = await PathfindingService.loadBuildingData('tupi_seait_main');
      if (loadedBuilding != null) {
        setState(() {
          building = loadedBuilding;
          isLoading = false;
        });
        return;
      }

      // Fallback to loading sample data from assets
      await _loadSampleData();
    } catch (e) {
      print('Error loading building: $e');
      await _loadSampleData();
    }
  }

  Future<void> _loadSampleData() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/maps/tupi_seait_sample.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      setState(() {
        building = Building.fromJson(jsonData);
        isLoading = false;
      });
    } catch (e) {
      print('Error loading sample data: $e');
      // Create a minimal building if all else fails
      _createMinimalBuilding();
    }
  }

  void _createMinimalBuilding() {
    final sampleGrid = [
      [1, 1, 1, 1, 1, 1],
      [1, 0, 0, 0, 0, 1],
      [1, 0, 1, 1, 0, 1],
      [1, 0, 0, 0, 0, 1],
      [1, 1, 1, 1, 1, 1],
    ];

    final sampleRooms = [
      Room(
        id: '101',
        name: 'Room 101',
        type: 'classroom',
        floor: 1,
        position: Position(row: 1, col: 1),
        department: 'General',
      ),
      Room(
        id: '102',
        name: 'Room 102',
        type: 'classroom',
        floor: 1,
        position: Position(row: 1, col: 4),
        department: 'General',
      ),
    ];

    final floor = Floor(
      number: 1,
      name: 'Ground Floor',
      grid: sampleGrid,
      rooms: sampleRooms,
    );

    setState(() {
      building = Building(
        id: 'sample',
        name: 'Sample Building',
        floors: [floor],
      );
      isLoading = false;
    });
  }

  Future<void> _searchRooms(String query) async {
    if (query.isEmpty) {
      setState(() {
        searchResults = [];
        isSearching = false;
      });
      return;
    }

    setState(() => isSearching = true);

    try {
      // Try backend search first
      final results = await PathfindingService.searchRooms(query);
      if (results != null) {
        setState(() {
          searchResults = results;
          isSearching = false;
        });
        return;
      }

      // Fallback to local search
      if (building != null) {
        final localResults = building!.searchRooms(query);
        setState(() {
          searchResults = localResults;
          isSearching = false;
        });
      }
    } catch (e) {
      print('Search error: $e');
      setState(() => isSearching = false);
    }
  }

  Future<void> _findPath() async {
    if (startRoom == null || endRoom == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select both start and destination rooms')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final path = await PathfindingService.findPath(startRoom!, endRoom!);
      setState(() {
        currentPath = path;
        isLoading = false;
      });

      if (path != null) {
        _showMapView();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not find a path between the selected rooms')),
        );
      }
    } catch (e) {
      print('Pathfinding error: $e');
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error finding path: $e')),
      );
    }
  }

  void _showMapView() {
    if (building == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapScreen(
          building: building!,
          path: currentPath,
          startRoom: startRoom,
          endRoom: endRoom,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Tupi SEAIT Navigation')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (building == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Tupi SEAIT Navigation')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text('Failed to load building data'),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadSampleBuilding,
                child: Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Tupi SEAIT Navigation'),
        actions: [
          IconButton(
            icon: Icon(Icons.map),
            onPressed: _showMapView,
            tooltip: 'View Map',
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Search bar
            TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search for rooms, departments, or facilities...',
                prefixIcon: Icon(Icons.search),
                suffixIcon: isSearching
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear),
                            onPressed: () {
                              searchController.clear();
                              _searchRooms('');
                            },
                          )
                        : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: _searchRooms,
            ),

            SizedBox(height: 16),

            // Room selection
            Row(
              children: [
                Expanded(
                  child: _buildRoomSelector(
                    'From',
                    startRoom,
                    (room) => setState(() => startRoom = room),
                    Colors.green,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _buildRoomSelector(
                    'To',
                    endRoom,
                    (room) => setState(() => endRoom = room),
                    Colors.red,
                  ),
                ),
              ],
            ),

            SizedBox(height: 16),

            // Navigation button
            ElevatedButton.icon(
              onPressed: _findPath,
              icon: Icon(Icons.navigation),
              label: Text('Find Route'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
                textStyle: TextStyle(fontSize: 18),
              ),
            ),

            SizedBox(height: 16),

            // Search results or room list
            Expanded(
              child: searchController.text.isNotEmpty
                  ? _buildSearchResults()
                  : _buildRoomList(),
            ),
          ],
        ),
      ),
    );
  }
