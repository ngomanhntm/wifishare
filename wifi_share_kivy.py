from kivy.app import App
from kivy.uix.boxlayout import BoxLayout
from kivy.uix.label import Label
from kivy.uix.button import Button
from kivy.uix.textinput import TextInput
from kivy.uix.popup import Popup
from kivy.uix.filechooser import FileChooserListView
from kivy.uix.screenmanager import ScreenManager, Screen
from kivy.clock import Clock
from kivy.logger import Logger
import threading
import os
import socket
from flask import Flask, request, send_from_directory, abort, render_template_string, send_file, Response, jsonify, session, redirect, url_for
import mimetypes
import time
import logging
import shutil
from io import BytesIO
from zipfile import ZipFile, ZIP_DEFLATED
from functools import lru_cache, wraps
from werkzeug.exceptions import HTTPException
from werkzeug.utils import secure_filename
import re
import unicodedata

# ===== AUTHENTICATION =====
USERNAME = "admin"
PASSWORD = "123456"  # ĐỔI MẬT KHẨU NÀY!

def check_auth(username, password):
    """Kiểm tra username và password"""
    return username == USERNAME and password == PASSWORD

def requires_auth(f):
    """Decorator để bảo vệ routes với session-based auth"""
    @wraps(f)
    def decorated(*args, **kwargs):
        if not session.get('logged_in'):
            return redirect(url_for('login'))
        return f(*args, **kwargs)
    return decorated

# ===== AUTO-DETECT STORAGE FOR ANDROID =====
def detect_storages():
    """Tự động phát hiện storage - Android version"""
    storages = {}
    
    # Android storage paths
    android_paths = [
        "/storage/emulated/0",  # Internal storage
        "/storage/self/primary",  # Alternative internal
        "/sdcard",  # Symlink to internal
    ]
    
    # Check internal storage
    for path in android_paths:
        if os.path.exists(path):
            try:
                os.listdir(path)
                storages["Internal"] = path
                break
            except (PermissionError, OSError):
                continue
    
    # Check external storage (SD cards)
    storage_base = "/storage"
    if os.path.exists(storage_base):
        try:
            for item in os.listdir(storage_base):
                if item in ["emulated", "self"]:
                    continue
                    
                path = os.path.join(storage_base, item)
                if os.path.isdir(path):
                    try:
                        os.listdir(path)
                        if path not in storages.values():
                            storages[f"SD_{item}"] = path
                    except (PermissionError, OSError):
                        pass
        except (PermissionError, OSError):
            pass
    
    # Fallback
    if not storages:
        fallback_paths = ["/sdcard", "/storage/emulated/0"]
        for path in fallback_paths:
            if os.path.exists(path):
                storages["Storage"] = path
                break
    
    return storages

# Flask app setup
flask_app = Flask(__name__)
flask_app.secret_key = 'your-secret-key-change-this-in-production'

STORAGES = detect_storages()
ROOT_DIR = list(STORAGES.values())[0] if STORAGES else "/sdcard"

# File type extensions
IMAGE_EXTS = {'.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp', '.svg', '.ico'}
VIDEO_EXTS = {'.mp4', '.avi', '.mkv', '.mov', '.wmv', '.flv', '.webm', '.m4v', '.3gp'}
AUDIO_EXTS = {'.mp3', '.wav', '.flac', '.aac', '.ogg', '.wma', '.m4a'}
DOCUMENT_EXTS = {'.pdf', '.doc', '.docx', '.txt', '.rtf', '.odt'}
ARCHIVE_EXTS = {'.zip', '.rar', '.7z', '.tar', '.gz', '.bz2'}

# Simple HTML template for mobile
MOBILE_HTML = """
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>WiFi File Share</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 10px; background: #f5f5f5; }
        .container { max-width: 100%; background: white; padding: 15px; border-radius: 8px; }
        .file-item { padding: 10px; border-bottom: 1px solid #eee; display: flex; align-items: center; }
        .file-icon { width: 24px; height: 24px; margin-right: 10px; }
        .file-name { flex: 1; }
        .file-size { color: #666; font-size: 12px; }
        .btn { background: #007bff; color: white; padding: 8px 16px; border: none; border-radius: 4px; text-decoration: none; }
        .upload-area { border: 2px dashed #ccc; padding: 20px; text-align: center; margin: 10px 0; }
    </style>
</head>
<body>
    <div class="container">
        <h2>📁 WiFi File Share</h2>
        <p>Current: {{ current_path }}</p>
        
        {% if parent_path %}
        <div class="file-item">
            <a href="/browse?path={{ parent_path }}" class="btn">⬆️ Back</a>
        </div>
        {% endif %}
        
        {% for item in files %}
        <div class="file-item">
            {% if item.is_dir %}
                <span class="file-icon">📁</span>
                <a href="/browse?path={{ item.path }}" class="file-name">{{ item.name }}</a>
            {% else %}
                <span class="file-icon">📄</span>
                <span class="file-name">{{ item.name }}</span>
                <span class="file-size">{{ item.size }}</span>
                <a href="/download?path={{ item.path }}" class="btn">⬇️</a>
            {% endif %}
        </div>
        {% endfor %}
        
        <div class="upload-area">
            <form method="post" enctype="multipart/form-data" action="/upload">
                <input type="hidden" name="path" value="{{ current_path }}">
                <input type="file" name="file" multiple>
                <button type="submit" class="btn">📤 Upload</button>
            </form>
        </div>
    </div>
</body>
</html>
"""

# Flask routes
@flask_app.route('/')
def index():
    return redirect('/browse')

@flask_app.route('/browse')
def browse():
    path = request.args.get('path', ROOT_DIR)
    if not os.path.exists(path):
        path = ROOT_DIR
    
    files = []
    try:
        for item in os.listdir(path):
            item_path = os.path.join(path, item)
            if os.path.isdir(item_path):
                files.append({
                    'name': item,
                    'path': item_path,
                    'is_dir': True,
                    'size': ''
                })
            else:
                size = os.path.getsize(item_path)
                files.append({
                    'name': item,
                    'path': item_path,
                    'is_dir': False,
                    'size': f"{size} bytes"
                })
    except PermissionError:
        files = []
    
    parent_path = os.path.dirname(path) if path != ROOT_DIR else None
    
    return render_template_string(MOBILE_HTML, 
                                files=files, 
                                current_path=path,
                                parent_path=parent_path)

@flask_app.route('/download')
def download():
    path = request.args.get('path')
    if not path or not os.path.exists(path):
        abort(404)
    return send_file(path, as_attachment=True)

@flask_app.route('/upload', methods=['POST'])
def upload():
    upload_path = request.form.get('path', ROOT_DIR)
    file = request.files.get('file')
    
    if file and file.filename:
        filename = secure_filename(file.filename)
        file.save(os.path.join(upload_path, filename))
    
    return redirect(f'/browse?path={upload_path}')

# Kivy UI Classes
class ServerScreen(Screen):
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.server_thread = None
        self.server_running = False
        
        layout = BoxLayout(orientation='vertical', padding=20, spacing=10)
        
        # Title
        title = Label(text='📱 WiFi File Share', font_size=24, size_hint_y=0.1)
        layout.add_widget(title)
        
        # Storage info
        storage_info = f"Detected Storage: {', '.join(STORAGES.keys())}"
        self.storage_label = Label(text=storage_info, size_hint_y=0.1)
        layout.add_widget(self.storage_label)
        
        # Server status
        self.status_label = Label(text='Server: Stopped', size_hint_y=0.1)
        layout.add_widget(self.status_label)
        
        # IP address
        self.ip_label = Label(text='IP: Not available', size_hint_y=0.1)
        layout.add_widget(self.ip_label)
        
        # Start/Stop button
        self.server_btn = Button(text='Start Server', size_hint_y=0.15)
        self.server_btn.bind(on_press=self.toggle_server)
        layout.add_widget(self.server_btn)
        
        # Settings
        settings_layout = BoxLayout(orientation='horizontal', size_hint_y=0.1)
        settings_layout.add_widget(Label(text='Port:'))
        self.port_input = TextInput(text='8000', multiline=False)
        settings_layout.add_widget(self.port_input)
        layout.add_widget(settings_layout)
        
        # Instructions
        instructions = Label(
            text='1. Start server\n2. Connect devices to same WiFi\n3. Open browser to IP:Port\n4. Login: admin/123456',
            size_hint_y=0.3
        )
        layout.add_widget(instructions)
        
        self.add_widget(layout)
        
        # Update IP periodically
        Clock.schedule_interval(self.update_ip, 5)
    
    def get_local_ip(self):
        try:
            s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
            s.connect(("8.8.8.8", 80))
            ip = s.getsockname()[0]
            s.close()
            return ip
        except:
            return "Unknown"
    
    def update_ip(self, dt):
        if not self.server_running:
            self.ip_label.text = "IP: Not available"
        else:
            ip = self.get_local_ip()
            port = self.port_input.text
            self.ip_label.text = f"Access: http://{ip}:{port}"
    
    def toggle_server(self, instance):
        if not self.server_running:
            self.start_server()
        else:
            self.stop_server()
    
    def start_server(self):
        try:
            port = int(self.port_input.text)
            self.server_thread = threading.Thread(
                target=self.run_server, 
                args=(port,),
                daemon=True
            )
            self.server_thread.start()
            self.server_running = True
            self.server_btn.text = 'Stop Server'
            self.status_label.text = 'Server: Running'
            Logger.info(f"Server started on port {port}")
        except Exception as e:
            Logger.error(f"Failed to start server: {e}")
            popup = Popup(title='Error', content=Label(text=str(e)), size_hint=(0.8, 0.4))
            popup.open()
    
    def stop_server(self):
        self.server_running = False
        self.server_btn.text = 'Start Server'
        self.status_label.text = 'Server: Stopped'
        Logger.info("Server stopped")
    
    def run_server(self, port):
        try:
            flask_app.run(host='0.0.0.0', port=port, debug=False, threaded=True)
        except Exception as e:
            Logger.error(f"Server error: {e}")

class WiFiShareApp(App):
    def build(self):
        sm = ScreenManager()
        sm.add_widget(ServerScreen(name='server'))
        return sm

if __name__ == '__main__':
    WiFiShareApp().run()
