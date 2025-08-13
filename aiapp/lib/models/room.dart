class Room {
  final String id;
  final String name;
  final String type; // classroom, office, laboratory, restroom, etc.
  final int floor;
  final Position position;
  final String? description;
  final String? department;
  final bool isAccessible; // wheelchair accessible
  final List<String> amenities; // projector, computer, etc.

  Room({
    required this.id,
    required this.name,
    required this.type,
    required this.floor,
    required this.position,
    this.description,
    this.department,
    this.isAccessible = true,
    this.amenities = const [],
  });

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: json['id'],
      name: json['name'],
      type: json['type'],
      floor: json['floor'],
      position: Position.fromJson(json['position']),
      description: json['description'],
      department: json['department'],
      isAccessible: json['isAccessible'] ?? true,
      amenities: List<String>.from(json['amenities'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'floor': floor,
      'position': position.toJson(),
      'description': description,
      'department': department,
      'isAccessible': isAccessible,
      'amenities': amenities,
    };
  }
}

class Position {
  final int row;
  final int col;
  final double? x; // Real-world coordinates (optional)
  final double? y; // Real-world coordinates (optional)

  Position({
    required this.row,
    required this.col,
    this.x,
    this.y,
  });

  factory Position.fromJson(Map<String, dynamic> json) {
    return Position(
      row: json['row'],
      col: json['col'],
      x: json['x']?.toDouble(),
      y: json['y']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'row': row,
      'col': col,
      'x': x,
      'y': y,
    };
  }

  List<int> toList() => [row, col];
}

class Floor {
  final int number;
  final String name;
  final List<List<int>> grid; // 0 = walkable, 1 = wall, 2 = stairs, 3 = elevator
  final List<Room> rooms;
  final Map<String, Position> specialLocations; // stairs, elevators, entrances

  Floor({
    required this.number,
    required this.name,
    required this.grid,
    required this.rooms,
    this.specialLocations = const {},
  });

  factory Floor.fromJson(Map<String, dynamic> json) {
    return Floor(
      number: json['number'],
      name: json['name'],
      grid: List<List<int>>.from(
        json['grid'].map((row) => List<int>.from(row))
      ),
      rooms: List<Room>.from(
        json['rooms'].map((room) => Room.fromJson(room))
      ),
      specialLocations: Map<String, Position>.from(
        json['specialLocations']?.map(
          (key, value) => MapEntry(key, Position.fromJson(value))
        ) ?? {}
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'number': number,
      'name': name,
      'grid': grid,
      'rooms': rooms.map((room) => room.toJson()).toList(),
      'specialLocations': specialLocations.map(
        (key, value) => MapEntry(key, value.toJson())
      ),
    };
  }
}

class Building {
  final String id;
  final String name;
  final List<Floor> floors;
  final String? description;

  Building({
    required this.id,
    required this.name,
    required this.floors,
    this.description,
  });

  factory Building.fromJson(Map<String, dynamic> json) {
    return Building(
      id: json['id'],
      name: json['name'],
      floors: List<Floor>.from(
        json['floors'].map((floor) => Floor.fromJson(floor))
      ),
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'floors': floors.map((floor) => floor.toJson()).toList(),
      'description': description,
    };
  }

  Floor? getFloor(int floorNumber) {
    try {
      return floors.firstWhere((floor) => floor.number == floorNumber);
    } catch (e) {
      return null;
    }
  }

  List<Room> getAllRooms() {
    return floors.expand((floor) => floor.rooms).toList();
  }

  List<Room> searchRooms(String query) {
    final lowercaseQuery = query.toLowerCase();
    return getAllRooms().where((room) =>
      room.name.toLowerCase().contains(lowercaseQuery) ||
      room.type.toLowerCase().contains(lowercaseQuery) ||
      (room.department?.toLowerCase().contains(lowercaseQuery) ?? false)
    ).toList();
  }
}