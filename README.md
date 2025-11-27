
# WiFi File Share APK Builder

## Build Options

### Option 1: Docker (Recommended)
1. Install Docker Desktop
2. Run: `build.bat` (Windows) or `./build.sh` (Linux/Mac)
3. Wait 15-30 minutes
4. APK will be in `bin/` folder

### Option 2: Online Build Services
Upload this folder to:
- GitHub Codespaces
- Google Colab
- Replit
Then run buildozer commands

### Option 3: Linux/WSL
```bash
sudo apt update
sudo apt install python3-pip git zip unzip openjdk-8-jdk
pip3 install buildozer cython
buildozer android debug
```

## APK Features
- WiFi file sharing server
- Android native UI with Kivy
- Web interface for other devices
- Auto-detect Android storage
- Upload/Download files

## Configuration
- Username: admin
- Password: 123456 (change in wifi_share_kivy.py)
- Default port: 8000
