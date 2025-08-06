from flask import Flask, request, jsonify
from queue import PriorityQueue

app = Flask(__name__)

# Sample grid map: 0 = walkable, 1 = wall
MAP = [
    [0, 0, 0, 0, 1, 0],
    [1, 1, 1, 0, 1, 0],
    [0, 0, 0, 0, 0, 0],
    [0, 1, 1, 1, 1, 1],
    [0, 0, 0, 0, 0, 0],
]

ROWS = len(MAP)
COLS = len(MAP[0])

def heuristic(a, b):
    return abs(a[0] - b[0]) + abs(a[1] - b[1])

def a_star(start, end):
    queue = PriorityQueue()
    queue.put((0, start))
    came_from = {}
    g_score = {start: 0}

    while not queue.empty():
        current = queue.get()[1]
        if current == end:
            path = []
            while current in came_from:
                path.append(current)
                current = came_from[current]
            path.append(start)
            path.reverse()
            return path

        for dx, dy in [(-1,0), (1,0), (0,-1), (0,1)]:
            neighbor = (current[0] + dx, current[1] + dy)
            if 0 <= neighbor[0] < ROWS and 0 <= neighbor[1] < COLS:
                if MAP[neighbor[0]][neighbor[1]] == 1:
                    continue
                tentative_g = g_score[current] + 1
                if neighbor not in g_score or tentative_g < g_score[neighbor]:
                    g_score[neighbor] = tentative_g
                    priority = tentative_g + heuristic(end, neighbor)
                    queue.put((priority, neighbor))
                    came_from[neighbor] = current
    return []

@app.route('/path', methods=['POST'])
def get_path():
    data = request.json
    start = tuple(data['start'])  # [row, col]
    end = tuple(data['end'])
    path = a_star(start, end)
    return jsonify({'path': path})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
