# 📱 WiFi File Share - Flutter

A beautiful, modern Android app for sharing files over WiFi with an elegant web interface.

## ✨ Features

### 📱 Mobile App
- **Material Design 3** UI with dynamic theming
- **Start/Stop server** with one tap
- **QR Code sharing** for easy connection
- **File browser** with intuitive navigation
- **Real-time server status** with animations
- **Dark/Light theme** support

### 🌐 Web Interface
- **Drag & drop** file uploads
- **Beautiful gradient design** 
- **Responsive layout** for all devices
- **File type icons** and previews
- **One-click downloads**
- **Real-time file listing**

### 🔧 Technical Features
- **HTTP server** built in pure Dart
- **Cross-platform** file sharing
- **Automatic IP detection**
- **Storage permissions** handling
- **Network state** monitoring

## 📸 Screenshots

| Home Screen | Server Running | QR Code | File Browser |
|-------------|----------------|---------|--------------|
| ![Home](screenshots/home.png) | ![Running](screenshots/running.png) | ![QR](screenshots/qr.png) | ![Browser](screenshots/browser.png) |

## 🚀 Quick Start

### Option 1: Download APK
1. Go to [Releases](../../releases)
2. Download latest `wifi-file-share-apk.apk`
3. Install on Android device

### Option 2: Build from Source
```bash
# Clone repository
git clone https://github.com/ngomanhntm/wifishare.git
cd wifishare/flutter_wifi_share

# Get dependencies
flutter pub get

# Build APK
flutter build apk --release

# APK will be in: build/app/outputs/flutter-apk/app-release.apk
```

## 📱 How to Use

1. **Install** the APK on your Android device
2. **Open** WiFi File Share app
3. **Tap "Start Server"** - the app will show your IP address
4. **Connect other devices** to the same WiFi network
5. **Open browser** on other devices and go to the IP address shown
6. **Share files** by:
   - Dragging files to the web interface
   - Using the file browser in the app
   - Downloading files from the web interface

## 🔧 Development

### Prerequisites
- Flutter SDK 3.16.0+
- Android SDK
- Dart 3.0+

### Project Structure
```
lib/
├── main.dart                 # App entry point
├── screens/
│   └── home_screen.dart     # Main UI screen
├── services/
│   └── file_server.dart     # HTTP server implementation
└── widgets/
    ├── server_status_card.dart  # Server status UI
    └── file_browser.dart        # File browser UI
```

### Key Dependencies
- `shelf` - HTTP server framework
- `qr_flutter` - QR code generation
- `network_info_plus` - Network information
- `permission_handler` - Android permissions
- `file_picker` - File selection

## 🌐 Web Interface Features

The web interface provides a modern, responsive design:

- **Gradient backgrounds** with smooth animations
- **File type icons** (📄 PDF, 🖼️ Images, 🎵 Audio, etc.)
- **Drag & drop zones** with visual feedback
- **Mobile-optimized** touch interface
- **File size formatting** (KB, MB, GB)
- **One-click downloads** with proper MIME types

## 🔒 Security Notes

- Server runs on **local network only**
- **No authentication** by default (add if needed)
- Files are served **read-only** from selected directory
- **CORS enabled** for web browser access

## 🛠️ Build & Deploy

### GitHub Actions
The project includes automated CI/CD:
- **Automatic APK building** on push
- **Release creation** with artifacts
- **Code analysis** and testing

### Manual Build
```bash
# Debug build
flutter build apk --debug

# Release build
flutter build apk --release

# Build for specific architecture
flutter build apk --target-platform android-arm64
```

## 📋 Permissions

The app requires these Android permissions:
- `INTERNET` - HTTP server functionality
- `ACCESS_NETWORK_STATE` - Network status detection
- `ACCESS_WIFI_STATE` - WiFi IP address detection
- `READ_EXTERNAL_STORAGE` - File access
- `WRITE_EXTERNAL_STORAGE` - File operations
- `MANAGE_EXTERNAL_STORAGE` - Android 11+ storage access

## 🤝 Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Material Design for UI inspiration
- Shelf package for HTTP server functionality

---

**Made with ❤️ using Flutter**
