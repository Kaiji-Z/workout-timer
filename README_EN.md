# Workout Timer

Professional Rest Timer for Fitness - Precision for Every Set

## Features

### Timer Core
- Preset rest durations: 30s, 60s, 90s, 120s - one tap selection
- Large countdown display for easy viewing during workouts
- Automatic set counting and complete training tracking
- Background operation: timer continues when screen is locked

### Smart Reminders
- Multi-channel notifications: Sound + Vibration + Screen popup
- Customizable reminder preferences
- Foreground service ensures notifications are never missed

### Exercise Database
- 800+ exercises covering all muscle groups
- Filter by muscle group to quickly find target exercises
- Exercise details with demonstration images
- Bilingual support (English/Chinese)

### Workout Plans
- Create personalized workout plans
- Calendar view for schedule management
- Real-time progress tracking

### Statistics
- Training history records
- Weekly/Monthly/Yearly statistics charts
- Visual data analysis

### Personalization
- 5 beautiful theme colors
- Dark/Light mode support
- Modern Material Design 3 interface

## Getting Started

### Requirements
- Flutter 3.10+
- Dart 3.10+

### Installation

```bash
# Clone the repository
git clone https://github.com/Kaiji-Z/workout-timer.git
cd workout-timer

# Install dependencies
flutter pub get

# Run the app
flutter run

# Build Release APK
./build_release.sh        # Linux/macOS
build_release.bat         # Windows
```

## Project Structure

```
lib/
├── main.dart              # App entry point
├── bloc/                  # State management (Provider)
├── models/                # Data models
├── screens/               # Screens
├── widgets/               # Reusable components
├── theme/                 # Theme system
├── services/              # Service layer
├── utils/                 # Utilities
└── data/                  # Static data
```

## Tech Stack

| Technology | Purpose |
|------------|---------|
| Flutter/Dart | Cross-platform UI framework |
| Provider | State management |
| SQLite (sqflite) | Local data storage |
| flutter_local_notifications | Local notifications |
| cached_network_image | Image caching |
| google_fonts | Typography |

## Acknowledgements

### Core Frameworks
- [Flutter](https://flutter.dev) - BSD 3-Clause
- [Dart](https://dart.dev) - BSD 3-Clause

### Third-party Packages
| Package | License | Purpose |
|---------|---------|---------|
| provider | MIT | State management |
| sqflite | BSD 2-Clause | SQLite database |
| flutter_local_notifications | BSD 3-Clause | Local notifications |
| shared_preferences | BSD 3-Clause | Persistent storage |
| google_fonts | Apache 2.0 | Google Fonts |
| cached_network_image | MIT | Image caching |
| intl | BSD 3-Clause | Internationalization |
| uuid | MIT | UUID generation |

### Data & Design Resources
| Resource | Source | License |
|----------|--------|---------|
| Exercise Database | [yuhonas/free-exercise-db](https://github.com/yuhonas/free-exercise-db) | CC0 Public Domain |
| Exercise Images | [yuhonas/free-exercise-db](https://github.com/yuhonas/free-exercise-db) | CC0 Public Domain |
| Orbitron Font | [Google Fonts](https://fonts.google.com/specimen/Orbitron) | SIL OFL |
| Rajdhani Font | [Google Fonts](https://fonts.google.com/specimen/Rajdhani) | SIL OFL |

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the [MIT License](LICENSE).

---

If you find this project helpful, please consider giving it a Star!
