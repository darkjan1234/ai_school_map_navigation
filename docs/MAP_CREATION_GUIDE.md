# 🗺️ Map Creation Guide for Tupi SEAIT Navigation System

This guide will help you convert your school's floor plans into digital map data for the AI navigation system.

## 📋 Overview

The navigation system uses a grid-based approach where each cell represents a physical space in your building. You'll need to:

1. **Analyze your floor plan**
2. **Create a grid representation**
3. **Define room locations**
4. **Set up navigation points**

## 🏗️ Step 1: Analyze Your Floor Plan

### What You Need:
- Floor plan drawings (PDF, image, or CAD files)
- Room numbers and names
- Department information
- Accessibility features

### Grid Planning:
- Decide on grid resolution (e.g., 1 cell = 1 meter)
- Identify walkable areas vs walls
- Mark special locations (stairs, elevators, entrances)

## 🔢 Step 2: Grid Values

Use these values in your grid:
- `0` = Walkable space (corridors, open areas)
- `1` = Wall or obstacle
- `2` = Stairs
- `3` = Elevator
- `4` = Entrance/Exit (optional)

## 📐 Step 3: Creating Your Grid

### Method 1: Manual Grid Creation
1. Print your floor plan on graph paper
2. Overlay a grid (recommend 15x15 or larger)
3. Mark each cell according to the values above
4. Convert to JSON format

### Method 2: Using Image Processing (Advanced)
```python
# Example Python script to help convert floor plan images
import cv2
import numpy as np

def floor_plan_to_grid(image_path, grid_size=(15, 15)):
    # Load and process floor plan image
    img = cv2.imread(image_path, cv2.IMREAD_GRAYSCALE)
    
    # Resize to grid dimensions
    resized = cv2.resize(img, grid_size)
    
    # Convert to binary (walls vs walkable)
    _, binary = cv2.threshold(resized, 127, 255, cv2.THRESH_BINARY)
    
    # Convert to grid values
    grid = []
    for row in binary:
        grid_row = []
        for pixel in row:
            # White = walkable (0), Black = wall (1)
            grid_row.append(0 if pixel > 127 else 1)
        grid.append(grid_row)
    
    return grid
```

## 🏢 Step 4: Room Definition

For each room, define:

```json
{
  "id": "unique_room_id",
  "name": "Room Name/Number",
  "type": "classroom|laboratory|office|restroom|library|cafeteria",
  "floor": 1,
  "position": {
    "row": 3,
    "col": 5,
    "x": 3.0,
    "y": 5.0
  },
  "description": "Brief description",
  "department": "Department name",
  "isAccessible": true,
  "amenities": ["projector", "computers", "whiteboard"]
}
```

### Room Types:
- `classroom` - Regular classrooms
- `laboratory` - Science/computer labs
- `office` - Faculty/admin offices
- `restroom` - Bathrooms
- `library` - Library/study areas
- `cafeteria` - Dining areas
- `auditorium` - Large meeting spaces
- `gymnasium` - Sports facilities

### Common Amenities:
- `projector`, `smart_board`, `whiteboard`
- `computers`, `printer`, `scanner`
- `air_conditioning`, `wifi`
- `wheelchair_accessible`
- `lab_equipment`, `safety_equipment`

## 🎯 Step 5: Special Locations

Define important navigation points:

```json
"specialLocations": {
  "main_entrance": {"row": 9, "col": 7},
  "stairs_1": {"row": 6, "col": 7},
  "elevator_1": {"row": 1, "col": 7},
  "emergency_exit_1": {"row": 0, "col": 14}
}
```

## 📏 Step 6: Coordinate Mapping

### Grid Coordinates vs Real-World
- Grid coordinates: Integer values for pathfinding
- Real-world coordinates: Actual distances in meters
- Use both for accuracy and flexibility

### Example Mapping:
```
Grid Cell (3,5) = Real Position (15.0m, 25.0m)
Scale: 1 grid cell = 5 meters
```

## 🛠️ Tools and Templates

### Excel Template
Create a spreadsheet with:
- Column A-O: Grid cells (15 columns)
- Rows 1-15: Grid rows
- Use conditional formatting for visualization

### Online Tools
- **Draw.io**: Create digital floor plans
- **Lucidchart**: Professional diagramming
- **SketchUp**: 3D modeling (export to 2D)

## ✅ Validation Checklist

Before finalizing your map:

- [ ] All walkable areas are connected
- [ ] Room positions match grid layout
- [ ] Stairs/elevators connect floors properly
- [ ] All rooms have unique IDs
- [ ] Accessibility paths are marked
- [ ] Emergency exits are included
- [ ] Grid dimensions are consistent

## 🔄 Testing Your Map

1. **Visual Check**: Display grid in the app
2. **Path Testing**: Try navigation between rooms
3. **Accessibility**: Test wheelchair-accessible routes
4. **Multi-floor**: Verify stair/elevator connections

## 📝 Example Workflow

1. **Scan/photograph** your floor plan
2. **Import** into drawing software
3. **Overlay** a grid (15x15 recommended)
4. **Mark** each cell type (0,1,2,3)
5. **Identify** room centers
6. **Create** JSON file using template
7. **Test** in the navigation app
8. **Refine** based on testing results

## 🚀 Quick Start Template

Use the provided `tupi_seait_sample.json` as a starting point:
1. Copy the file structure
2. Replace grid data with your floor plan
3. Update room information
4. Modify special locations
5. Test and iterate

## 💡 Tips for Success

- **Start simple**: Begin with one floor
- **Test frequently**: Validate each section
- **Use consistent naming**: Follow room numbering conventions
- **Document changes**: Keep track of modifications
- **Plan for growth**: Leave room for future expansions

## 🆘 Troubleshooting

### Common Issues:
- **Disconnected paths**: Ensure all walkable areas connect
- **Wrong room positions**: Double-check grid coordinates
- **Missing amenities**: Add relevant facility information
- **Scale problems**: Verify grid-to-real-world mapping

### Getting Help:
- Check the sample JSON file for reference
- Test with simple 5x5 grids first
- Use the app's debug mode to visualize paths
