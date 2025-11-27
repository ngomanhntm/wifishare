import 'package:flutter/material.dart';

class ServerStatusCard extends StatelessWidget {
  final bool isRunning;
  final String ipAddress;
  final String serverUrl;
  final int port;
  final VoidCallback onToggle;
  final VoidCallback onCopyUrl;
  final VoidCallback onShowQR;
  final bool isLoading;

  const ServerStatusCard({
    super.key,
    required this.isRunning,
    required this.ipAddress,
    required this.serverUrl,
    required this.port,
    required this.onToggle,
    required this.onCopyUrl,
    required this.onShowQR,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isRunning
                ? [Colors.green.shade400, Colors.green.shade600]
                : [Colors.grey.shade300, Colors.grey.shade400],
          ),
        ),
        child: Column(
          children: [
            // Status Indicator
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: isRunning ? Colors.white : Colors.grey.shade600,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  isRunning ? 'Server Running' : 'Server Stopped',
                  style: TextStyle(
                    color: isRunning ? Colors.white : Colors.grey.shade700,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // Server Info
            if (isRunning) ...[
              _buildInfoRow(
                icon: Icons.computer,
                label: 'IP Address',
                value: ipAddress,
                color: Colors.white,
              ),
              const SizedBox(height: 8),
              _buildInfoRow(
                icon: Icons.link,
                label: 'Server URL',
                value: serverUrl,
                color: Colors.white,
              ),
              const SizedBox(height: 8),
              _buildInfoRow(
                icon: Icons.router,
                label: 'Port',
                value: port.toString(),
                color: Colors.white,
              ),
              const SizedBox(height: 20),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: serverUrl.isNotEmpty ? onCopyUrl : null,
                      icon: const Icon(Icons.copy, size: 18),
                      label: const Text('Copy URL'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.green.shade600,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: serverUrl.isNotEmpty ? onShowQR : null,
                      icon: const Icon(Icons.qr_code, size: 18),
                      label: const Text('QR Code'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.green.shade600,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              Text(
                'Start the server to share files',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ],

            const SizedBox(height: 20),

            // Toggle Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: isLoading ? null : onToggle,
                icon: Icon(
                  isRunning ? Icons.stop : Icons.play_arrow,
                  size: 24,
                ),
                label: Text(
                  isRunning ? 'Stop Server' : 'Start Server',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isRunning ? Colors.red.shade500 : Colors.blue.shade500,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            color: color.withOpacity(0.8),
            fontSize: 14,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
