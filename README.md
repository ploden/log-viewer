# LogViewer

A powerful macOS application for viewing and filtering OSLog entries in real-time, built with SwiftUI and distributed as a Swift Package.

## Features

- **Real-time Log Monitoring**: View OSLog entries as they happen
- **Advanced Filtering**: 
  - Filter by log categories and levels
  - Global and per-category log level controls
  - Real-time search with text filtering
- **Modern UI**: 
  - Clean SwiftUI interface with sidebar navigation
  - 24-hour timestamp format with seconds
  - Color-coded log levels
- **Performance Optimized**:
  - Background thread filtering
  - Smart UI updates only when results change
  - Responsive interface during heavy logging
- **Developer Tools**: 
  - Pause/resume logging
  - Clear logs functionality
  - Test log generation

## Requirements

- macOS 14.0 or later
- Swift 5.9 or later

## Installation

### Using Swift Package Manager

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/LogViewer.git
   cd LogViewer
   ```

2. Build and run:
   ```bash
   swift build
   swift run LogViewer
   ```

### Building from Source

1. Clone the repository
2. Open Terminal and navigate to the project directory
3. Run `swift build` to build the package
4. Run `swift run LogViewer` to launch the application

## Usage

### Basic Operation

1. Launch the application
2. Use the sidebar to select which log categories you want to monitor
3. Adjust global log levels using the level checkboxes
4. Use the search bar to filter logs by content
5. Use the toolbar buttons to:
   - Pause/resume log collection
   - Clear current logs
   - Generate test logs
   - Toggle sidebar visibility

### Log Filtering

- **Categories**: Select/deselect categories in the left sidebar
- **Log Levels**: Use the global level controls, or expand categories for per-category level control
- **Search**: Type in the search bar to filter logs by message content, category, or subsystem
- **Real-time**: All filtering happens in real-time as logs are collected

### Performance Features

- Filtering operations run on background threads to maintain UI responsiveness
- Only updates the display when filtered results actually change
- Automatic task cancellation prevents multiple concurrent filtering operations

## Architecture

The LogViewer follows a clean architecture pattern:

- **LogService**: Handles OSLog collection and data management
- **LogViewModel**: Manages UI state and filtering logic
- **Views**: SwiftUI components for the user interface
- **ServiceProtocol**: Reactive service pattern for data updates

## Configuration

The app includes configuration files for OSLog behavior:
- `LogViewerLoggerSettings.plist`: Controls which log categories are captured
- `LoggerSettings.plist`: Additional logging configuration

## Development

### Building for Development

```bash
swift build -c debug
```

### Running Tests

```bash
swift test
```

### Building for Release

```bash
swift build -c release
```

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Built with SwiftUI and OSLog frameworks
- Designed for macOS developers and system administrators
- Optimized for performance and usability 