import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:file_picker/file_picker.dart';

class FileBrowser extends StatefulWidget {
  final String rootPath;

  const FileBrowser({
    super.key,
    required this.rootPath,
  });

  @override
  State<FileBrowser> createState() => _FileBrowserState();
}

class _FileBrowserState extends State<FileBrowser> {
  List<FileSystemEntity> _files = [];
  bool _isLoading = true;
  String _currentPath = '';

  @override
  void initState() {
    super.initState();
    _currentPath = widget.rootPath;
    _loadFiles();
  }

  @override
  void didUpdateWidget(FileBrowser oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rootPath != widget.rootPath) {
      _currentPath = widget.rootPath;
      _loadFiles();
    }
  }

  Future<void> _loadFiles() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final directory = Directory(_currentPath);
      if (await directory.exists()) {
        final files = await directory.list().toList();
        files.sort((a, b) {
          // Directories first, then files
          if (a is Directory && b is File) return -1;
          if (a is File && b is Directory) return 1;
          return path.basename(a.path).toLowerCase()
              .compareTo(path.basename(b.path).toLowerCase());
        });
        
        setState(() {
          _files = files;
        });
      }
    } catch (e) {
      _showErrorSnackBar('Error loading files: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _navigateToDirectory(String dirPath) {
    setState(() {
      _currentPath = dirPath;
    });
    _loadFiles();
  }

  void _navigateUp() {
    final parent = Directory(_currentPath).parent;
    if (parent.path != _currentPath && parent.path.contains(widget.rootPath)) {
      _navigateToDirectory(parent.path);
    }
  }

  Future<void> _pickAndCopyFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
      );

      if (result != null) {
        for (PlatformFile file in result.files) {
          if (file.path != null) {
            final sourceFile = File(file.path!);
            final targetFile = File(path.join(_currentPath, file.name));
            await sourceFile.copy(targetFile.path);
          }
        }
        _loadFiles();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Files copied successfully'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      _showErrorSnackBar('Error copying files: $e');
    }
  }

  IconData _getFileIcon(String fileName) {
    final extension = path.extension(fileName).toLowerCase();
    switch (extension) {
      case '.pdf':
        return Icons.picture_as_pdf;
      case '.doc':
      case '.docx':
        return Icons.description;
      case '.txt':
        return Icons.text_snippet;
      case '.jpg':
      case '.jpeg':
      case '.png':
      case '.gif':
      case '.bmp':
        return Icons.image;
      case '.mp4':
      case '.avi':
      case '.mkv':
      case '.mov':
        return Icons.video_file;
      case '.mp3':
      case '.wav':
      case '.flac':
        return Icons.audio_file;
      case '.zip':
      case '.rar':
      case '.7z':
        return Icons.archive;
      case '.apk':
        return Icons.android;
      default:
        return Icons.insert_drive_file;
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var i = 0;
    double size = bytes.toDouble();
    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    return '${size.toStringAsFixed(1)} ${suffixes[i]}';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.folder, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'File Browser',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _currentPath.replaceAll(widget.rootPath, '~/'),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (_currentPath != widget.rootPath)
                  IconButton(
                    onPressed: _navigateUp,
                    icon: const Icon(Icons.arrow_upward, color: Colors.white),
                    tooltip: 'Go up',
                  ),
                IconButton(
                  onPressed: _loadFiles,
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  tooltip: 'Refresh',
                ),
              ],
            ),
          ),

          // File List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _files.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.folder_open, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'No files found',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _files.length,
                        itemBuilder: (context, index) {
                          final file = _files[index];
                          final isDirectory = file is Directory;
                          final fileName = path.basename(file.path);

                          return ListTile(
                            leading: Icon(
                              isDirectory ? Icons.folder : _getFileIcon(fileName),
                              color: isDirectory
                                  ? Colors.blue
                                  : Theme.of(context).colorScheme.primary,
                            ),
                            title: Text(
                              fileName,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: isDirectory
                                ? const Text('Folder')
                                : FutureBuilder<FileStat>(
                                    future: file.stat(),
                                    builder: (context, snapshot) {
                                      if (snapshot.hasData) {
                                        return Text(
                                          _formatFileSize(snapshot.data!.size),
                                        );
                                      }
                                      return const Text('...');
                                    },
                                  ),
                            onTap: isDirectory
                                ? () => _navigateToDirectory(file.path)
                                : null,
                            trailing: isDirectory
                                ? const Icon(Icons.chevron_right)
                                : null,
                          );
                        },
                      ),
          ),

          // Add Files Button
          Container(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _pickAndCopyFiles,
                icon: const Icon(Icons.add),
                label: const Text('Add Files'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
