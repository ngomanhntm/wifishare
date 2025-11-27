import 'dart:io';
import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_static/shelf_static.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;

class FileServer {
  HttpServer? _server;
  int _port = 8000;
  String _rootPath = '';
  bool _isRunning = false;

  bool get isRunning => _isRunning;
  int get port => _port;
  String get rootPath => _rootPath;

  Future<bool> start(String rootPath, {int port = 8000}) async {
    if (_isRunning) {
      await stop();
    }

    _rootPath = rootPath;
    _port = port;

    try {
      final router = Router();

      // Serve static files
      final staticHandler = createStaticHandler(
        rootPath,
        defaultDocument: 'index.html',
        listDirectories: true,
      );

      // API routes
      router.get('/api/files', _handleFileList);
      router.post('/api/upload', _handleUpload);
      router.get('/api/download/<path|.*>', _handleDownload);
      router.get('/', _handleIndex);
      router.get('/<path|.*>', staticHandler);

      final handler = Pipeline()
          .addMiddleware(logRequests())
          .addMiddleware(_corsMiddleware)
          .addHandler(router);

      _server = await shelf_io.serve(handler, InternetAddress.anyIPv4, port);
      _isRunning = true;

      print('Server running on http://${_server!.address.host}:${_server!.port}');
      return true;
    } catch (e) {
      print('Failed to start server: $e');
      return false;
    }
  }

  Future<void> stop() async {
    if (_server != null) {
      await _server!.close();
      _server = null;
      _isRunning = false;
      print('Server stopped');
    }
  }

  Middleware get _corsMiddleware => (Handler handler) {
        return (Request request) async {
          final response = await handler(request);
          return response.change(headers: {
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
            'Access-Control-Allow-Headers': 'Content-Type, Authorization',
          });
        };
      };

  Response _handleIndex(Request request) {
    final html = '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>WiFi File Share</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { 
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            padding: 20px;
        }
        .container {
            max-width: 800px;
            margin: 0 auto;
            background: white;
            border-radius: 16px;
            box-shadow: 0 20px 40px rgba(0,0,0,0.1);
            overflow: hidden;
        }
        .header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 30px;
            text-align: center;
        }
        .header h1 { font-size: 2.5rem; margin-bottom: 10px; }
        .header p { opacity: 0.9; font-size: 1.1rem; }
        .content { padding: 30px; }
        .file-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
            gap: 20px;
            margin: 20px 0;
        }
        .file-item {
            background: #f8f9fa;
            border-radius: 12px;
            padding: 20px;
            text-align: center;
            transition: transform 0.2s, box-shadow 0.2s;
            cursor: pointer;
        }
        .file-item:hover {
            transform: translateY(-5px);
            box-shadow: 0 10px 25px rgba(0,0,0,0.1);
        }
        .file-icon {
            font-size: 3rem;
            margin-bottom: 10px;
            display: block;
        }
        .upload-area {
            border: 3px dashed #667eea;
            border-radius: 12px;
            padding: 40px;
            text-align: center;
            margin: 30px 0;
            background: #f8f9ff;
            transition: all 0.3s;
        }
        .upload-area:hover { background: #f0f4ff; }
        .upload-area.dragover { 
            border-color: #764ba2;
            background: #f0f4ff;
            transform: scale(1.02);
        }
        .btn {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            border: none;
            padding: 12px 24px;
            border-radius: 8px;
            font-size: 1rem;
            cursor: pointer;
            transition: transform 0.2s;
        }
        .btn:hover { transform: translateY(-2px); }
        .file-input { display: none; }
        @media (max-width: 768px) {
            .file-grid { grid-template-columns: repeat(auto-fill, minmax(150px, 1fr)); }
            .header h1 { font-size: 2rem; }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>📱 WiFi File Share</h1>
            <p>Share files wirelessly across devices</p>
        </div>
        <div class="content">
            <div class="upload-area" id="uploadArea">
                <div style="font-size: 3rem; margin-bottom: 20px;">📤</div>
                <h3>Drop files here or click to upload</h3>
                <p style="margin: 10px 0; color: #666;">Support all file types</p>
                <button class="btn" onclick="document.getElementById('fileInput').click()">
                    Choose Files
                </button>
                <input type="file" id="fileInput" class="file-input" multiple>
            </div>
            
            <h3 style="margin: 30px 0 20px 0;">📁 Available Files</h3>
            <div class="file-grid" id="fileGrid">
                <!-- Files will be loaded here -->
            </div>
        </div>
    </div>

    <script>
        // File upload functionality
        const uploadArea = document.getElementById('uploadArea');
        const fileInput = document.getElementById('fileInput');
        const fileGrid = document.getElementById('fileGrid');

        // Drag and drop
        uploadArea.addEventListener('dragover', (e) => {
            e.preventDefault();
            uploadArea.classList.add('dragover');
        });

        uploadArea.addEventListener('dragleave', () => {
            uploadArea.classList.remove('dragover');
        });

        uploadArea.addEventListener('drop', (e) => {
            e.preventDefault();
            uploadArea.classList.remove('dragover');
            const files = e.dataTransfer.files;
            uploadFiles(files);
        });

        fileInput.addEventListener('change', (e) => {
            uploadFiles(e.target.files);
        });

        function uploadFiles(files) {
            for (let file of files) {
                const formData = new FormData();
                formData.append('file', file);
                
                fetch('/api/upload', {
                    method: 'POST',
                    body: formData
                }).then(() => {
                    loadFiles();
                });
            }
        }

        function loadFiles() {
            fetch('/api/files')
                .then(response => response.json())
                .then(files => {
                    fileGrid.innerHTML = '';
                    files.forEach(file => {
                        const fileItem = document.createElement('div');
                        fileItem.className = 'file-item';
                        fileItem.innerHTML = `
                            <span class="file-icon">${getFileIcon(file.name)}</span>
                            <div style="font-weight: bold; margin-bottom: 5px;">${file.name}</div>
                            <div style="color: #666; font-size: 0.9rem;">${formatFileSize(file.size)}</div>
                        `;
                        fileItem.onclick = () => downloadFile(file.name);
                        fileGrid.appendChild(fileItem);
                    });
                });
        }

        function getFileIcon(filename) {
            const ext = filename.split('.').pop().toLowerCase();
            const icons = {
                'pdf': '📄', 'doc': '📄', 'docx': '📄', 'txt': '📄',
                'jpg': '🖼️', 'jpeg': '🖼️', 'png': '🖼️', 'gif': '🖼️',
                'mp4': '🎥', 'avi': '🎥', 'mkv': '🎥', 'mov': '🎥',
                'mp3': '🎵', 'wav': '🎵', 'flac': '🎵',
                'zip': '📦', 'rar': '📦', '7z': '📦',
                'apk': '📱'
            };
            return icons[ext] || '📄';
        }

        function formatFileSize(bytes) {
            if (bytes === 0) return '0 Bytes';
            const k = 1024;
            const sizes = ['Bytes', 'KB', 'MB', 'GB'];
            const i = Math.floor(Math.log(bytes) / Math.log(k));
            return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
        }

        function downloadFile(filename) {
            window.open(`/api/download/\${filename}`, '_blank');
        }

        // Load files on page load
        loadFiles();
    </script>
</body>
</html>
    ''';
    
    return Response.ok(html, headers: {'Content-Type': 'text/html'});
  }

  Future<Response> _handleFileList(Request request) async {
    try {
      final dir = Directory(_rootPath);
      final files = <Map<String, dynamic>>[];
      
      await for (final entity in dir.list()) {
        if (entity is File) {
          final stat = await entity.stat();
          files.add({
            'name': path.basename(entity.path),
            'size': stat.size,
            'modified': stat.modified.toIso8601String(),
            'type': 'file',
          });
        }
      }
      
      return Response.ok(
        jsonEncode(files),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(body: 'Error listing files: $e');
    }
  }

  Future<Response> _handleUpload(Request request) async {
    try {
      // Simple file upload implementation
      // In a real app, you'd parse multipart/form-data properly
      final bytes = await request.read().toList();
      final data = bytes.expand((x) => x).toList();
      
      // For now, save as uploaded_file_timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File(path.join(_rootPath, 'uploaded_$timestamp'));
      await file.writeAsBytes(data);
      
      return Response.ok('File uploaded successfully');
    } catch (e) {
      return Response.internalServerError(body: 'Upload failed: $e');
    }
  }

  Future<Response> _handleDownload(Request request, String filePath) async {
    try {
      final file = File(path.join(_rootPath, filePath));
      
      if (!await file.exists()) {
        return Response.notFound('File not found');
      }
      
      final mimeType = lookupMimeType(file.path) ?? 'application/octet-stream';
      final stream = file.openRead();
      
      return Response.ok(
        stream,
        headers: {
          'Content-Type': mimeType,
          'Content-Disposition': 'attachment; filename="${path.basename(filePath)}"',
        },
      );
    } catch (e) {
      return Response.internalServerError(body: 'Download failed: $e');
    }
  }
}
