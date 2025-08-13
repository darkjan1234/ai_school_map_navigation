from flask import Flask, request, jsonify
from flask_cors import CORS
from queue import PriorityQueue
import json
import os
from typing import List, Dict, Tuple, Optional

app = Flask(__name__)
CORS(app)  # Enable CORS for Flutter app

# Global building data storage
buildings = {}
current_building = None

def load_building_data():
    """Load building data from JSON files"""
    global buildings, current_building

    # Try to load sample building data
    sample_file = os.path.join('..', 'assets', 'maps', 'tupi_seait_sample.json')
    if os.path.exists(sample_file):
        try:
            with open(sample_file, 'r', encoding='utf-8') as f:
                building_data = json.load(f)
                buildings[building_data['id']] = building_data
                current_building = building_data
                print(f"Loaded building: {building_data['name']}")
        except Exception as e:
            print(f"Error loading building data: {e}")

    # Fallback to simple map if no building data found
    if not buildings:
        _create_fallback_building()

def _create_fallback_building():
    """Create a simple fallback building for testing"""
    global buildings, current_building

    fallback_building = {
        "id": "fallback",
        "name": "Fallback Building",
        "description": "Simple building for testing",
        "floors": [{
            "number": 1,
            "name": "Ground Floor",
            "grid": [
                [0, 0, 0, 0, 1, 0],
                [1, 1, 1, 0, 1, 0],
                [0, 0, 0, 0, 0, 0],
                [0, 1, 1, 1, 1, 1],
                [0, 0, 0, 0, 0, 0],
            ],
            "rooms": [
                {
                    "id": "101",
                    "name": "Room 101",
                    "type": "classroom",
                    "floor": 1,
                    "position": {"row": 0, "col": 0},
                    "department": "General",
                    "isAccessible": True,
                    "amenities": []
                },
                {
                    "id": "102",
                    "name": "Room 102",
                    "type": "classroom",
                    "floor": 1,
                    "position": {"row": 0, "col": 3},
                    "department": "General",
                    "isAccessible": True,
                    "amenities": []
                }
            ],
            "specialLocations": {}
        }]
    }

    buildings["fallback"] = fallback_building
    current_building = fallback_building
    print("Created fallback building")

# Load building data on startup
load_building_data()

def heuristic(a: Tuple[int, int], b: Tuple[int, int]) -> int:
    """Manhattan distance heuristic"""
    return abs(a[0] - b[0]) + abs(a[1] - b[1])

def get_floor_grid(floor_number: int = 1) -> List[List[int]]:
    """Get the grid for a specific floor"""
    if current_building is None:
        return []

    for floor in current_building['floors']:
        if floor['number'] == floor_number:
            return floor['grid']

    return []

def a_star(start: Tuple[int, int], end: Tuple[int, int], floor: int = 1, accessible_only: bool = False) -> List[Tuple[int, int]]:
    """A* pathfinding algorithm with support for different floors and accessibility"""
    grid = get_floor_grid(floor)
    if not grid:
        return []

    rows, cols = len(grid), len(grid[0])

    # Validate start and end positions
    if not (0 <= start[0] < rows and 0 <= start[1] < cols):
        return []
    if not (0 <= end[0] < rows and 0 <= end[1] < cols):
        return []
    if grid[start[0]][start[1]] == 1 or grid[end[0]][end[1]] == 1:
        return []

    queue = PriorityQueue()
    queue.put((0, start))
    came_from = {}
    g_score = {start: 0}

    while not queue.empty():
        current = queue.get()[1]
        if current == end:
            # Reconstruct path
            path = []
            while current in came_from:
                path.append(current)
                current = came_from[current]
            path.append(start)
            path.reverse()
            return path

        # Check all 4 directions
        for dx, dy in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
            neighbor = (current[0] + dx, current[1] + dy)

            # Check bounds
            if not (0 <= neighbor[0] < rows and 0 <= neighbor[1] < cols):
                continue

            # Check if walkable
            cell_type = grid[neighbor[0]][neighbor[1]]
            if cell_type == 1:  # Wall
                continue

            # For accessible paths, avoid stairs if possible
            if accessible_only and cell_type == 2:  # Stairs
                continue

            tentative_g = g_score[current] + 1

            # Add penalty for stairs in accessible mode
            if accessible_only and cell_type == 2:
                tentative_g += 10

            if neighbor not in g_score or tentative_g < g_score[neighbor]:
                g_score[neighbor] = tentative_g
                priority = tentative_g + heuristic(end, neighbor)
                queue.put((priority, neighbor))
                came_from[neighbor] = current

    return []

def find_room_by_id(room_id: str) -> Optional[Dict]:
    """Find a room by its ID"""
    if current_building is None:
        return None

    for floor in current_building['floors']:
        for room in floor['rooms']:
            if room['id'] == room_id:
                return room
    return None

def search_rooms(query: str) -> List[Dict]:
    """Search rooms by name, type, or department"""
    if current_building is None:
        return []

    query_lower = query.lower()
    results = []

    for floor in current_building['floors']:
        for room in floor['rooms']:
            # Search in name, type, and department
            if (query_lower in room['name'].lower() or
                query_lower in room['type'].lower() or
                (room.get('department') and query_lower in room['department'].lower())):
                results.append(room)

    return results

def generate_instructions(start_pos: Tuple[int, int], end_pos: Tuple[int, int],
                         path: List[Tuple[int, int]], start_room: Dict, end_room: Dict) -> List[str]:
    """Generate step-by-step navigation instructions"""
    if not path or len(path) < 2:
        return ["You are already at your destination."]

    instructions = []
    instructions.append(f"Starting from {start_room['name']}")

    # Analyze path for direction changes
    for i in range(1, len(path)):
        current = path[i-1]
        next_pos = path[i]

        # Determine direction
        if next_pos[0] < current[0]:
            direction = "north"
        elif next_pos[0] > current[0]:
            direction = "south"
        elif next_pos[1] < current[1]:
            direction = "west"
        elif next_pos[1] > current[1]:
            direction = "east"
        else:
            continue

        # Count consecutive steps in same direction
        steps = 1
        while (i + steps < len(path) and
               _get_direction(path[i + steps - 1], path[i + steps]) == direction):
            steps += 1

        if steps == 1:
            instructions.append(f"Move {direction}")
        else:
            instructions.append(f"Move {direction} for {steps} steps")

        i += steps - 1

    instructions.append(f"You have arrived at {end_room['name']}")
    return instructions

def _get_direction(from_pos: Tuple[int, int], to_pos: Tuple[int, int]) -> str:
    """Get direction between two positions"""
    if to_pos[0] < from_pos[0]:
        return "north"
    elif to_pos[0] > from_pos[0]:
        return "south"
    elif to_pos[1] < from_pos[1]:
        return "west"
    elif to_pos[1] > from_pos[1]:
        return "east"
    return "unknown"

# API Routes

@app.route('/path', methods=['POST'])
def get_path():
    """Find path between two points"""
    try:
        data = request.json
        start = tuple(data['start'])  # [row, col]
        end = tuple(data['end'])
        floor = data.get('floor', 1)

        path = a_star(start, end, floor)
        return jsonify({
            'path': path,
            'length': len(path),
            'floor': floor
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 400

@app.route('/accessible_path', methods=['POST'])
def get_accessible_path():
    """Find wheelchair-accessible path between two points"""
    try:
        data = request.json
        start = tuple(data['start'])
        end = tuple(data['end'])
        floor = data.get('floor', 1)

        path = a_star(start, end, floor, accessible_only=True)
        return jsonify({
            'path': path,
            'length': len(path),
            'floor': floor,
            'accessible': True
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 400

@app.route('/instructions', methods=['POST'])
def get_instructions():
    """Get step-by-step navigation instructions"""
    try:
        data = request.json
        start = tuple(data['start'])
        end = tuple(data['end'])
        start_room = data['start_room']
        end_room = data['end_room']
        floor = data.get('floor', 1)

        path = a_star(start, end, floor)
        if not path:
            return jsonify({'error': 'No path found'}), 404

        instructions = generate_instructions(start, end, path, start_room, end_room)
        return jsonify({
            'instructions': instructions,
            'path': path,
            'length': len(path)
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 400

@app.route('/building/<building_id>', methods=['GET'])
def get_building(building_id):
    """Get building data by ID"""
    if building_id in buildings:
        return jsonify(buildings[building_id])
    else:
        return jsonify({'error': 'Building not found'}), 404

@app.route('/buildings', methods=['GET'])
def get_buildings():
    """Get list of all buildings"""
    return jsonify({
        'buildings': list(buildings.keys()),
        'data': buildings
    })

@app.route('/search', methods=['GET'])
def search_rooms_endpoint():
    """Search for rooms"""
    try:
        query = request.args.get('q', '')
        building_id = request.args.get('building')

        if building_id and building_id in buildings:
            # Search in specific building
            global current_building
            old_building = current_building
            current_building = buildings[building_id]
            results = search_rooms(query)
            current_building = old_building
        else:
            # Search in current building
            results = search_rooms(query)

        return jsonify({
            'rooms': results,
            'query': query,
            'count': len(results)
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 400

@app.route('/room/<room_id>', methods=['GET'])
def get_room(room_id):
    """Get room details by ID"""
    room = find_room_by_id(room_id)
    if room:
        return jsonify(room)
    else:
        return jsonify({'error': 'Room not found'}), 404

@app.route('/floors', methods=['GET'])
def get_floors():
    """Get list of floors in current building"""
    if current_building:
        floors = [{'number': floor['number'], 'name': floor['name']}
                 for floor in current_building['floors']]
        return jsonify({'floors': floors})
    else:
        return jsonify({'error': 'No building loaded'}), 404

@app.route('/floor/<int:floor_number>', methods=['GET'])
def get_floor(floor_number):
    """Get specific floor data"""
    if current_building:
        for floor in current_building['floors']:
            if floor['number'] == floor_number:
                return jsonify(floor)
        return jsonify({'error': 'Floor not found'}), 404
    else:
        return jsonify({'error': 'No building loaded'}), 404

@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({
        'status': 'healthy',
        'building_loaded': current_building is not None,
        'buildings_count': len(buildings)
    })

@app.route('/', methods=['GET'])
def index():
    """API information"""
    return jsonify({
        'name': 'Tupi SEAIT Navigation API',
        'version': '1.0.0',
        'endpoints': {
            'POST /path': 'Find path between two points',
            'POST /accessible_path': 'Find accessible path',
            'POST /instructions': 'Get navigation instructions',
            'GET /building/<id>': 'Get building data',
            'GET /buildings': 'List all buildings',
            'GET /search?q=<query>': 'Search rooms',
            'GET /room/<id>': 'Get room details',
            'GET /floors': 'List floors',
            'GET /floor/<number>': 'Get floor data',
            'GET /health': 'Health check'
        }
    })

if __name__ == '__main__':
    print("Starting Tupi SEAIT Navigation API...")
    print(f"Building loaded: {current_building['name'] if current_building else 'None'}")
    app.run(host='0.0.0.0', port=5000, debug=True)
