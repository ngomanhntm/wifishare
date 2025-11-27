import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import '../services/file_server.dart';
import '../widgets/server_status_card.dart';
import '../widgets/file_browser.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final FileServer _fileServer = FileServer();
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  
  String _ipAddress = 'Unknown';
  String _serverUrl = '';
  bool _isLoading = false;
  String _rootPath = '';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _initializeApp();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _fileServer.stop();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    await _requestPermissions();
    await _getNetworkInfo();
    await _setupRootPath();
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.storage,
      Permission.manageExternalStorage,
    ].request();
  }

  Future<void> _getNetworkInfo() async {
    try {
      final info = NetworkInfo();
      final wifiIP = await info.getWifiIP();
      setState(() {
        _ipAddress = wifiIP ?? 'Not connected to WiFi';
        _serverUrl = _ipAddress != 'Not connected to WiFi' 
            ? 'http://$_ipAddress:${_fileServer.port}'
            : '';
      });
    } catch (e) {
      setState(() {
        _ipAddress = 'Error getting IP';
      });
    }
  }

  Future<void> _setupRootPath() async {
    try {
      final directory = await getExternalStorageDirectory();
      setState(() {
        _rootPath = directory?.path ?? '/storage/emulated/0/Download';
      });
    } catch (e) {
      setState(() {
        _rootPath = '/storage/emulated/0/Download';
      });
    }
  }

  Future<void> _toggleServer() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (_fileServer.isRunning) {
        await _fileServer.stop();
        _animationController.reverse();
      } else {
        final success = await _fileServer.start(_rootPath);
        if (success) {
          await _getNetworkInfo();
          _animationController.forward();
        } else {
          _showErrorSnackBar('Failed to start server');
        }
      }
    } catch (e) {
      _showErrorSnackBar('Error: $e');
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

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showQRCode() {
    if (_serverUrl.isEmpty) return;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Scan to Connect',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: QrImageView(
                  data: _serverUrl,
                  version: QrVersions.auto,
                  size: 200.0,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _serverUrl,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
              Theme.of(context).colorScheme.secondary.withOpacity(0.1),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // App Bar
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.wifi,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'WiFi File Share',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Share files wirelessly',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _getNetworkInfo,
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                ),
              ),

              // Server Status Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: AnimatedBuilder(
                  animation: _scaleAnimation,
                  builder: (context, child) => Transform.scale(
                    scale: _scaleAnimation.value,
                    child: ServerStatusCard(
                      isRunning: _fileServer.isRunning,
                      ipAddress: _ipAddress,
                      serverUrl: _serverUrl,
                      port: _fileServer.port,
                      onToggle: _toggleServer,
                      onCopyUrl: () => _copyToClipboard(_serverUrl),
                      onShowQR: _showQRCode,
                      isLoading: _isLoading,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // File Browser
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: FileBrowser(rootPath: _rootPath),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
