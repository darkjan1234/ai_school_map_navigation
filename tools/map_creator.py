#!/usr/bin/env python3
"""
Map Creator Tool for Tupi SEAIT Navigation System
Helps convert floor plans to digital map data
"""

import json
import cv2
import numpy as np
from typing import List, Dict, Tuple, Optional
import argparse
import os

class MapCreator:
    def __init__(self):
        self.grid = []
        self.rooms = []
        self.special_locations = {}
        self.grid_size = (15, 15)
        
    def load_floor_plan_image(self, image_path: str, grid_size: Tuple[int, int] = (15, 15)) -> List[List[int]]:
        """
        Convert a floor plan image to a grid representation
        """
        if not os.path.exists(image_path):
            raise FileNotFoundError(f"Image file not found: {image_path}")
            
        # Load image
        img = cv2.imread(image_path, cv2.IMREAD_GRAYSCALE)
        if img is None:
            raise ValueError(f"Could not load image: {image_path}")
            
        print(f"Original image size: {img.shape}")
        
        # Resize to grid dimensions
        resized = cv2.resize(img, grid_size)
        
        # Apply threshold to create binary image
        _, binary = cv2.threshold(resized, 127, 255, cv2.THRESH_BINARY)
        
        # Convert to grid values
        grid = []
        for row in binary:
            grid_row = []
            for pixel in row:
                # White pixels = walkable (0), Dark pixels = walls (1)
                grid_row.append(0 if pixel > 127 else 1)
            grid.append(grid_row)
            
        self.grid = grid
        self.grid_size = grid_size
        print(f"Generated grid: {len(grid)}x{len(grid[0])}")
        return grid
    
    def create_manual_grid(self, rows: int = 15, cols: int = 15) -> List[List[int]]:
        """
        Create an empty grid for manual editing
        """
        self.grid = [[0 for _ in range(cols)] for _ in range(rows)]
        self.grid_size = (rows, cols)
        return self.grid
    
    def add_walls_border(self):
        """
        Add walls around the border of the grid
        """
        if not self.grid:
            return
            
        rows, cols = len(self.grid), len(self.grid[0])
        
        # Top and bottom borders
        for col in range(cols):
            self.grid[0][col] = 1
            self.grid[rows-1][col] = 1
            
        # Left and right borders
        for row in range(rows):
            self.grid[row][0] = 1
            self.grid[row][cols-1] = 1
    
    def add_room(self, room_id: str, name: str, room_type: str, floor: int, 
                 row: int, col: int, department: str = None, 
                 description: str = None, amenities: List[str] = None):
        """
        Add a room to the map
        """
        room = {
            "id": room_id,
            "name": name,
            "type": room_type,
            "floor": floor,
            "position": {
                "row": row,
                "col": col,
                "x": float(col),
                "y": float(row)
            },
            "description": description,
            "department": department,
            "isAccessible": True,
            "amenities": amenities or []
        }
        self.rooms.append(room)
        print(f"Added room: {name} at ({row}, {col})")
    
    def add_special_location(self, name: str, row: int, col: int):
        """
        Add a special location (stairs, elevator, entrance)
        """
        self.special_locations[name] = {
            "row": row,
            "col": col,
            "x": float(col),
            "y": float(row)
        }
        print(f"Added special location: {name} at ({row}, {col})")
    
    def set_cell_type(self, row: int, col: int, cell_type: int):
        """
        Set a specific cell type in the grid
        0 = walkable, 1 = wall, 2 = stairs, 3 = elevator
        """
        if 0 <= row < len(self.grid) and 0 <= col < len(self.grid[0]):
            self.grid[row][col] = cell_type
            print(f"Set cell ({row}, {col}) to type {cell_type}")
        else:
            print(f"Invalid coordinates: ({row}, {col})")
    
    def visualize_grid(self):
        """
        Print a visual representation of the grid
        """
        if not self.grid:
            print("No grid data available")
            return
            
        print("\nGrid Visualization:")
        print("0=walkable, 1=wall, 2=stairs, 3=elevator")
        print("-" * (len(self.grid[0]) * 2 + 1))
        
        for i, row in enumerate(self.grid):
            print(f"{i:2d}|", end="")
            for cell in row:
                symbol = {0: ".", 1: "█", 2: "S", 3: "E"}.get(cell, "?")
                print(symbol, end=" ")
            print()
        
        print("-" * (len(self.grid[0]) * 2 + 1))
        print("   ", end="")
        for j in range(len(self.grid[0])):
            print(f"{j%10}", end=" ")
        print()
    
    def export_to_json(self, building_id: str, building_name: str, 
                      floor_number: int, floor_name: str, 
                      output_file: str):
        """
        Export the map data to JSON format
        """
        map_data = {
            "id": building_id,
            "name": building_name,
            "description": f"Digital map for {building_name}",
            "floors": [
                {
                    "number": floor_number,
                    "name": floor_name,
                    "grid": self.grid,
                    "rooms": self.rooms,
                    "specialLocations": self.special_locations
                }
            ]
        }
        
        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(map_data, f, indent=2, ensure_ascii=False)
        
        print(f"Map data exported to: {output_file}")
        return map_data
    
    def load_from_json(self, json_file: str):
        """
        Load existing map data from JSON
        """
        with open(json_file, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        if data.get('floors'):
            floor = data['floors'][0]  # Load first floor
            self.grid = floor.get('grid', [])
            self.rooms = floor.get('rooms', [])
            self.special_locations = floor.get('specialLocations', {})
            print(f"Loaded map data from: {json_file}")
        
    def interactive_mode(self):
        """
        Interactive mode for creating maps
        """
        print("=== Interactive Map Creator ===")
        print("Commands:")
        print("  grid <rows> <cols> - Create new grid")
        print("  wall <row> <col> - Add wall")
        print("  stairs <row> <col> - Add stairs")
        print("  elevator <row> <col> - Add elevator")
        print("  room <id> <name> <type> <row> <col> - Add room")
        print("  special <name> <row> <col> - Add special location")
        print("  show - Display current grid")
        print("  save <filename> - Save to JSON")
        print("  quit - Exit")
        
        while True:
            try:
                command = input("\n> ").strip().split()
                if not command:
                    continue
                    
                cmd = command[0].lower()
                
                if cmd == "quit":
                    break
                elif cmd == "grid":
                    rows, cols = int(command[1]), int(command[2])
                    self.create_manual_grid(rows, cols)
                    self.add_walls_border()
                elif cmd == "wall":
                    row, col = int(command[1]), int(command[2])
                    self.set_cell_type(row, col, 1)
                elif cmd == "stairs":
                    row, col = int(command[1]), int(command[2])
                    self.set_cell_type(row, col, 2)
                elif cmd == "elevator":
                    row, col = int(command[1]), int(command[2])
                    self.set_cell_type(row, col, 3)
                elif cmd == "room":
                    room_id, name, room_type = command[1], command[2], command[3]
                    row, col = int(command[4]), int(command[5])
                    self.add_room(room_id, name, room_type, 1, row, col)
                elif cmd == "special":
                    name, row, col = command[1], int(command[2]), int(command[3])
                    self.add_special_location(name, row, col)
                elif cmd == "show":
                    self.visualize_grid()
                elif cmd == "save":
                    filename = command[1]
                    self.export_to_json("building_1", "School Building", 1, "Ground Floor", filename)
                else:
                    print("Unknown command")
                    
            except (IndexError, ValueError) as e:
                print(f"Error: {e}")
                print("Check command syntax")

def main():
    parser = argparse.ArgumentParser(description="Map Creator for Navigation System")
    parser.add_argument("--image", help="Floor plan image file")
    parser.add_argument("--grid-size", nargs=2, type=int, default=[15, 15], 
                       help="Grid dimensions (rows cols)")
    parser.add_argument("--output", default="map_output.json", 
                       help="Output JSON file")
    parser.add_argument("--interactive", action="store_true", 
                       help="Start interactive mode")
    
    args = parser.parse_args()
    
    creator = MapCreator()
    
    if args.interactive:
        creator.interactive_mode()
    elif args.image:
        # Process image
        grid = creator.load_floor_plan_image(args.image, tuple(args.grid_size))
        creator.add_walls_border()
        creator.visualize_grid()
        
        # Export basic structure
        creator.export_to_json("building_1", "School Building", 1, "Ground Floor", args.output)
        print(f"\nBasic map structure created. Edit {args.output} to add rooms and details.")
    else:
        print("Use --interactive for manual creation or --image for image processing")
        print("Example: python map_creator.py --interactive")
        print("Example: python map_creator.py --image floor_plan.png --output school_map.json")

if __name__ == "__main__":
    main()
