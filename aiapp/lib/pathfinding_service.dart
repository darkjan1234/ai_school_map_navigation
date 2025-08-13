import 'package:http/http.dart' as http;
import 'dart:convert';
import 'models/room.dart';

class PathfindingService {
  static const String baseUrl = 'http://192.168.137.1:5000'; // Update with your backend URL

  /// Find path between two rooms
  static Future<List<List<int>>?> findPath(Room startRoom, Room endRoom) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/path'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'start': startRoom.position.toList(),
          'end': endRoom.position.toList(),
          'floor': startRoom.floor,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<List<int>>.from(
          data['path'].map((e) => List<int>.from(e))
        );
      } else {
        print('Error finding path: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Network error: $e');
      return null;
    }
  }

  /// Find path between two positions
  static Future<List<List<int>>?> findPathByPosition(
    List<int> start,
    List<int> end,
    {int floor = 1}
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/path'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'start': start,
          'end': end,
          'floor': floor,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<List<int>>.from(
          data['path'].map((e) => List<int>.from(e))
        );
      } else {
        print('Error finding path: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Network error: $e');
      return null;
    }
  }

  /// Find accessible path (wheelchair-friendly)
  static Future<List<List<int>>?> findAccessiblePath(Room startRoom, Room endRoom) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/accessible_path'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'start': startRoom.position.toList(),
          'end': endRoom.position.toList(),
          'floor': startRoom.floor,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<List<int>>.from(
          data['path'].map((e) => List<int>.from(e))
        );
      } else {
        print('Error finding accessible path: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Network error: $e');
      return null;
    }
  }

  /// Get navigation instructions
  static Future<List<String>?> getNavigationInstructions(
    Room startRoom,
    Room endRoom
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/instructions'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'start': startRoom.position.toList(),
          'end': endRoom.position.toList(),
          'start_room': startRoom.toJson(),
          'end_room': endRoom.toJson(),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<String>.from(data['instructions']);
      } else {
        print('Error getting instructions: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Network error: $e');
      return null;
    }
  }

  /// Load building data from backend
  static Future<Building?> loadBuildingData(String buildingId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/building/$buildingId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Building.fromJson(data);
      } else {
        print('Error loading building data: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Network error: $e');
      return null;
    }
  }

  /// Search rooms by query
  static Future<List<Room>?> searchRooms(String query, {String? buildingId}) async {
    try {
      final uri = Uri.parse('$baseUrl/search').replace(queryParameters: {
        'q': query,
        if (buildingId != null) 'building': buildingId,
      });

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Room>.from(
          data['rooms'].map((room) => Room.fromJson(room))
        );
      } else {
        print('Error searching rooms: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Network error: $e');
      return null;
    }
  }

  /// Calculate estimated walking time
  static Duration calculateWalkingTime(List<List<int>> path, {double speedMps = 1.4}) {
    // Average walking speed: 1.4 m/s (5 km/h)
    // Assuming each grid cell represents 1 meter
    final distanceMeters = path.length.toDouble();
    final timeSeconds = distanceMeters / speedMps;
    return Duration(seconds: timeSeconds.round());
  }

  /// Get path statistics
  static Map<String, dynamic> getPathStatistics(List<List<int>> path) {
    if (path.isEmpty) return {};

    int totalSteps = path.length;
    double totalDistance = totalSteps.toDouble(); // Assuming 1 cell = 1 meter
    Duration estimatedTime = calculateWalkingTime(path);

    return {
      'steps': totalSteps,
      'distance_meters': totalDistance,
      'estimated_time': estimatedTime,
      'estimated_time_string': _formatDuration(estimatedTime),
    };
  }

  static String _formatDuration(Duration duration) {
    if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
    } else {
      return '${duration.inSeconds}s';
    }
  }
}