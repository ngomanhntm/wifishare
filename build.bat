@echo off
echo Building WiFi File Share APK...
echo This will take 15-30 minutes for first build

REM Build with Docker
docker build -t wifi-share-builder .
docker run -v %cd%\bin:/app/bin wifi-share-builder

echo APK should be in bin\ folder
pause
