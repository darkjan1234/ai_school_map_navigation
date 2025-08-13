import 'package:flutter/material.dart';
import 'models/room.dart';
import 'dart:convert';

class MapScreen extends StatefulWidget {
  final Building building;
  final List<List<int>>? path;
  final Room? startRoom;
  final Room? endRoom;

  const MapScreen({
    Key? key,
    required this.building,
    this.path,
    this.startRoom,
    this.endRoom,
  }) : super(key: key);

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  int currentFloor = 1;
  double zoomLevel = 1.0;

  @override
  Widget build(BuildContext context) {
    final floor = widget.building.getFloor(currentFloor);
    if (floor == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Map View')),
        body: Center(child: Text('Floor $currentFloor not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.building.name} - ${floor.name}'),
        actions: [
          IconButton(
            icon: Icon(Icons.zoom_in),
            onPressed: () => setState(() => zoomLevel = (zoomLevel * 1.2).clamp(0.5, 3.0)),
          ),
          IconButton(
            icon: Icon(Icons.zoom_out),
            onPressed: () => setState(() => zoomLevel = (zoomLevel / 1.2).clamp(0.5, 3.0)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Floor selector
          if (widget.building.floors.length > 1)
            Container(
              height: 60,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: widget.building.floors.length,
                itemBuilder: (context, index) {
                  final floorNum = widget.building.floors[index].number;
                  final isSelected = floorNum == currentFloor;
                  return Padding(
                    padding: EdgeInsets.all(8.0),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isSelected ? Colors.blue : Colors.grey[300],
                        foregroundColor: isSelected ? Colors.white : Colors.black,
                      ),
                      onPressed: () => setState(() => currentFloor = floorNum),
                      child: Text('Floor $floorNum'),
                    ),
                  );
                },
              ),
            ),

          // Map legend
          Container(
            padding: EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildLegendItem(Colors.white, 'Walkable', Icons.directions_walk),
                _buildLegendItem(Colors.black, 'Wall', Icons.block),
                _buildLegendItem(Colors.orange, 'Stairs', Icons.stairs),
                _buildLegendItem(Colors.blue, 'Elevator', Icons.elevator),
                _buildLegendItem(Colors.green, 'Path', Icons.navigation),
              ],
            ),
          ),

          // Map grid
          Expanded(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 3.0,
              child: Center(
                child: Transform.scale(
                  scale: zoomLevel,
                  child: _buildMapGrid(floor),
                ),
              ),
            ),
          ),

          // Room info panel
          if (widget.startRoom != null || widget.endRoom != null)
            Container(
              padding: EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                border: Border(top: BorderSide(color: Colors.grey[300]!)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.startRoom != null)
                    Text('From: ${widget.startRoom!.name}',
                         style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                  if (widget.endRoom != null)
                    Text('To: ${widget.endRoom!.name}',
                         style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                  if (widget.path != null)
                    Text('Path length: ${widget.path!.length} steps'),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: Colors.grey),
          ),
        ),
        SizedBox(width: 4),
        Icon(icon, size: 16),
        SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildMapGrid(Floor floor) {
    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: floor.grid.length * floor.grid[0].length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: floor.grid[0].length,
      ),
      itemBuilder: (context, index) {
        int row = index ~/ floor.grid[0].length;
        int col = index % floor.grid[0].length;

        return _buildMapCell(floor, row, col);
      },
    );
  }

  Widget _buildMapCell(Floor floor, int row, int col) {
    Color cellColor = _getCellColor(floor.grid[row][col]);
    Widget? cellContent;

    // Check if this cell is on the path
    if (widget.path != null && _isPathCell(row, col)) {
      cellColor = Colors.green.withOpacity(0.7);
    }

    // Check if this cell contains a room
    final room = _getRoomAtPosition(floor, row, col);
    if (room != null) {
      cellContent = _buildRoomMarker(room);
    }

    // Check for special locations
    final specialLocation = _getSpecialLocationAtPosition(floor, row, col);
    if (specialLocation != null) {
      cellContent = _buildSpecialLocationMarker(specialLocation);
    }

    return GestureDetector(
      onTap: () => _onCellTapped(floor, row, col),
      child: Container(
        margin: EdgeInsets.all(0.5),
        decoration: BoxDecoration(
          color: cellColor,
          border: Border.all(color: Colors.grey[400]!, width: 0.5),
        ),
        child: cellContent,
      ),
    );
  }

  Color _getCellColor(int cellType) {
    switch (cellType) {
      case 0: return Colors.white; // Walkable
      case 1: return Colors.black; // Wall
      case 2: return Colors.orange; // Stairs
      case 3: return Colors.blue; // Elevator
      default: return Colors.grey;
    }
  }

  bool _isPathCell(int row, int col) {
    return widget.path?.any((pos) => pos[0] == row && pos[1] == col) ?? false;
  }

  Room? _getRoomAtPosition(Floor floor, int row, int col) {
    return floor.rooms.firstWhere(
      (room) => room.position.row == row && room.position.col == col,
      orElse: () => null as Room,
    );
  }

  String? _getSpecialLocationAtPosition(Floor floor, int row, int col) {
    for (var entry in floor.specialLocations.entries) {
      if (entry.value.row == row && entry.value.col == col) {
        return entry.key;
      }
    }
    return null;
  }

  Widget _buildRoomMarker(Room room) {
    Color markerColor = Colors.purple;
    if (room == widget.startRoom) markerColor = Colors.green;
    if (room == widget.endRoom) markerColor = Colors.red;

    return Container(
      decoration: BoxDecoration(
        color: markerColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: Text(
          room.id,
          style: TextStyle(
            color: Colors.white,
            fontSize: 8,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildSpecialLocationMarker(String locationType) {
    IconData icon;
    Color color;

    if (locationType.contains('stairs')) {
      icon = Icons.stairs;
      color = Colors.orange;
    } else if (locationType.contains('elevator')) {
      icon = Icons.elevator;
      color = Colors.blue;
    } else if (locationType.contains('entrance')) {
      icon = Icons.door_front_door;
      color = Colors.green;
    } else {
      icon = Icons.location_on;
      color = Colors.purple;
    }

    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(icon, color: Colors.white, size: 16),
    );
  }

  void _onCellTapped(Floor floor, int row, int col) {
    final room = _getRoomAtPosition(floor, row, col);
    if (room != null) {
      _showRoomDetails(room);
    }

    final specialLocation = _getSpecialLocationAtPosition(floor, row, col);
    if (specialLocation != null) {
      _showSpecialLocationInfo(specialLocation, row, col);
    }
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
            Text('Type: ${room.type}'),
            if (room.department != null) Text('Department: ${room.department}'),
            if (room.description != null) Text('Description: ${room.description}'),
            Text('Floor: ${room.floor}'),
            Text('Position: (${room.position.row}, ${room.position.col})'),
            Text('Accessible: ${room.isAccessible ? "Yes" : "No"}'),
            if (room.amenities.isNotEmpty)
              Text('Amenities: ${room.amenities.join(", ")}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showSpecialLocationInfo(String locationType, int row, int col) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(locationType.replaceAll('_', ' ').toUpperCase()),
        content: Text('Location: ($row, $col)'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }
}