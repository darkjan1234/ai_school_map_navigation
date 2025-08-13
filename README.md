# 🧠 AI-Based Indoor Navigation System for Tupi SEAIT School

> A comprehensive indoor navigation mobile application powered by AI pathfinding algorithms, designed specifically for school facilities with smart room routing and accessibility features.

---

## 📌 Features

### 🗺️ **Core Navigation**
- **AI-Powered Pathfinding** using A* algorithm
- **Multi-Floor Navigation** with stairs and elevator support
- **Real-Time Route Calculation** between any two rooms
- **Visual Map Display** with interactive zoom and pan
- **Step-by-Step Directions** with estimated walking time

### 🔍 **Smart Search & Discovery**
- **Room Search** by name, number, or department
- **Facility Type Filtering** (classrooms, labs, offices, etc.)
- **Department-Based Navigation** for easy organization
- **Quick Room Selection** with visual indicators

### ♿ **Accessibility Features**
- **Wheelchair-Accessible Routes** with elevator prioritization
- **Accessibility Information** for each room and path
- **Alternative Route Suggestions** when barriers exist
- **Visual Accessibility Indicators** throughout the app

### 📱 **Mobile Experience**
- **Cross-Platform Support** (Android, iOS, Web, Desktop)
- **Offline Mode** with cached maps for navigation without internet
- **Responsive Design** optimized for mobile devices
- **Touch-Friendly Interface** with intuitive controls

---

## 📂 Project Structure

```bash
ai_school_map_navigation/
├── aiapp/                      # Flutter mobile application
│   ├── lib/
│   │   ├── models/            # Data models (Room, Floor, Building)
│   │   ├── map_screen.dart    # Interactive map display
│   │   ├── pathfinding_service.dart  # API communication
│   │   └── main.dart          # Main app entry point
│   ├── assets/
│   │   └── maps/              # Map data files
│   └── pubspec.yaml           # Flutter dependencies
├── backend/                   # Python Flask API server
│   ├── app.py                 # Main API server
│   └── requirements.txt       # Python dependencies
├── tools/                     # Map creation utilities
│   ├── map_creator.py         # Python map creation tool
│   └── web_map_editor.html    # Web-based map editor
├── docs/                      # Documentation
│   └── MAP_CREATION_GUIDE.md  # Guide for creating maps
└── README.md                  # This file

---

## 🚀 Quick Start

### Prerequisites
- **Flutter SDK** (3.0 or higher)
- **Python 3.8+** for backend
- **Android Studio** or **VS Code** for development
- **Git** for version control

### 1. Clone the Repository
```bash
git clone https://github.com/your-username/ai_school_map_navigation.git
cd ai_school_map_navigation
```

### 2. Setup Backend (Python Flask)
```bash
cd backend

# Create virtual environment
python -m venv venv

# Activate virtual environment
# Windows:
venv\Scripts\activate
# macOS/Linux:
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Start the server
python app.py
```

The backend will start on `http://localhost:5000`

### 3. Setup Flutter App
```bash
cd aiapp

# Get Flutter dependencies
flutter pub get

# Run on your preferred platform
flutter run                    # Default device
flutter run -d chrome          # Web browser
flutter run -d windows         # Windows desktop
flutter run -d android         # Android device/emulator
```

### 4. Configure Network Connection
Update the backend URL in `aiapp/lib/pathfinding_service.dart`:
```dart
static const String baseUrl = 'http://YOUR_IP_ADDRESS:5000';
```

For Android emulator, use: `http://10.0.2.2:5000`
For physical device, use your computer's IP address.

---

## 🗺️ Creating Your School Map

### Option 1: Web-Based Map Editor (Recommended)
1. Open `tools/web_map_editor.html` in your browser
2. Create your grid layout by clicking cells
3. Add rooms with details (name, type, department)
4. Export as JSON file
5. Place the file in `assets/maps/`

### Option 2: Python Map Creator Tool
```bash
cd tools

# Interactive mode
python map_creator.py --interactive

# From floor plan image
python map_creator.py --image floor_plan.png --output school_map.json
```

### Option 3: Manual JSON Creation
Follow the detailed guide in `docs/MAP_CREATION_GUIDE.md`

---

## 📱 How to Use the App

### 1. **Search for Rooms**
- Use the search bar to find rooms by name, number, or department
- Browse the complete room list below the search

### 2. **Select Start and Destination**
- Tap the green arrow (▶️) to set a room as starting point
- Tap the red flag (🚩) to set a room as destination
- Or tap "Set as Start/Destination" in room details

### 3. **Find Your Route**
- Press "Find Route" to calculate the optimal path
- View the route on the interactive map
- Get step-by-step directions with estimated time

### 4. **Navigate the Map**
- Zoom in/out with pinch gestures or buttons
- Switch between floors using the floor selector
- Tap rooms for detailed information
- Follow the green path to your destination

---

## 🛠️ API Endpoints

The backend provides a RESTful API for the mobile app:

### Navigation
- `POST /path` - Find path between two points
- `POST /accessible_path` - Find wheelchair-accessible path
- `POST /instructions` - Get step-by-step directions

### Building Data
- `GET /building/<id>` - Get building information
- `GET /buildings` - List all buildings
- `GET /floors` - List floors in current building
- `GET /floor/<number>` - Get specific floor data

### Room Management
- `GET /search?q=<query>` - Search rooms
- `GET /room/<id>` - Get room details

### System
- `GET /health` - API health check
- `GET /` - API documentation

---

## 🏗️ Architecture Overview

### Frontend (Flutter)
- **Models**: Data structures for rooms, floors, and buildings
- **Services**: API communication and pathfinding logic
- **UI Components**: Map display, search, and navigation screens
- **State Management**: Local state with setState

### Backend (Python Flask)
- **Pathfinding Engine**: A* algorithm implementation
- **Data Management**: JSON-based building and room data
- **API Layer**: RESTful endpoints for mobile app
- **CORS Support**: Cross-origin requests for web deployment

### Data Flow
1. User selects start and destination rooms
2. Flutter app sends pathfinding request to Flask API
3. Backend calculates optimal route using A* algorithm
4. Route data returned to app for visualization
5. Interactive map displays path with turn-by-turn directions

---

## 🧪 Testing the System

### 1. **Backend Testing**
```bash
cd backend
python app.py

# Test API endpoints
curl http://localhost:5000/health
curl http://localhost:5000/buildings
```

### 2. **Flutter Testing**
```bash
cd aiapp

# Run unit tests
flutter test

# Run integration tests
flutter test integration_test/
```

### 3. **Manual Testing Checklist**
- [ ] App loads successfully
- [ ] Room search works correctly
- [ ] Path calculation between rooms
- [ ] Map visualization displays properly
- [ ] Multi-floor navigation functions
- [ ] Accessibility features work
- [ ] Offline mode operates correctly

---

## 🔧 Troubleshooting

### Common Issues

**1. "No route found" error**
- Check that both rooms are on the same floor
- Verify room positions are on walkable cells
- Ensure there's a valid path between rooms

**2. Backend connection failed**
- Verify backend is running on correct port
- Check IP address configuration in Flutter app
- Ensure firewall allows connections on port 5000

**3. Map not loading**
- Confirm map JSON file is in `assets/maps/`
- Validate JSON syntax using online validator
- Check Flutter asset configuration in `pubspec.yaml`

**4. Flutter build errors**
- Run `flutter clean && flutter pub get`
- Update Flutter SDK to latest stable version
- Check for dependency conflicts

### Performance Optimization
- Use smaller grid sizes for better performance
- Implement map caching for offline use
- Optimize image assets for mobile devices
- Consider using Flutter's `const` constructors

---

## 🤝 Contributing

We welcome contributions to improve the navigation system!

### Development Setup
1. Fork the repository
2. Create a feature branch: `git checkout -b feature-name`
3. Make your changes and test thoroughly
4. Submit a pull request with detailed description

### Code Style
- **Flutter**: Follow [Dart style guide](https://dart.dev/guides/language/effective-dart/style)
- **Python**: Follow [PEP 8](https://pep8.org/) style guide
- **Documentation**: Update README and code comments

### Areas for Contribution
- 🗺️ Enhanced map visualization features
- 🔍 Advanced search and filtering options
- ♿ Improved accessibility features
- 🌐 Multi-language support
- 📊 Analytics and usage tracking
- 🎨 UI/UX improvements

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- **A* Algorithm**: Based on classic pathfinding research
- **Flutter Team**: For the excellent cross-platform framework
- **Flask Community**: For the lightweight web framework
- **Tupi SEAIT School**: For the inspiration and use case

---

## 📞 Support

For questions, issues, or suggestions:

- 📧 **Email**: your-email@example.com
- 🐛 **Issues**: [GitHub Issues](https://github.com/your-username/ai_school_map_navigation/issues)
- 💬 **Discussions**: [GitHub Discussions](https://github.com/your-username/ai_school_map_navigation/discussions)

---

**Made with ❤️ for Tupi SEAIT School and the education community**
Members of the team:
*** Shekinah Faith Bartolome
***
***
***
***


