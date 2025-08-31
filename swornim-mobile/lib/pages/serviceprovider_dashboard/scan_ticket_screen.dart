import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:swornim/config/app_config.dart';
import 'package:swornim/pages/providers/auth/auth_provider.dart';
import 'dart:async';

class ScanTicketScreen extends ConsumerStatefulWidget {
  final String eventId;

  const ScanTicketScreen({Key? key, required this.eventId}) : super(key: key);

  @override
  ConsumerState<ScanTicketScreen> createState() => _ScanTicketScreenState();
}

class _ScanTicketScreenState extends ConsumerState<ScanTicketScreen>
    with TickerProviderStateMixin {
  bool _isProcessing = false;
  String? _resultMessage;
  Color _resultColor = Colors.green;
  Timer? _resetTimer;
  late final MobileScannerController _controller;
  late AnimationController _animationController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;
  
  String? _lastScannedCode;
  DateTime? _lastScanTime;
  static const int _scanCooldownMs = 3000;
  
  bool _flashEnabled = false;
  bool _cameraActive = true;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _animationController.forward();
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _resetTimer?.cancel();
    _controller.dispose();
    _animationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  bool _shouldProcessScan(String code) {
    final now = DateTime.now();
    
    if (_lastScannedCode == code && 
        _lastScanTime != null && 
        now.difference(_lastScanTime!).inMilliseconds < _scanCooldownMs) {
      return false;
    }
    
    return true;
  }

  Future<void> _verifyTicket(String bookingId) async {
    setState(() {
      _isProcessing = true;
      _resultMessage = null;
      _cameraActive = false;
    });

    await _controller.stop();
    _pulseController.stop();

    try {
      final authToken = ref.read(authProvider).accessToken;
      final dio = Dio();
      final url = '${AppConfig.baseUrl}/events/bookings/$bookingId/checkin/';
      final response = await dio.post(
        url,
        options: Options(
          headers: {'Authorization': 'Bearer $authToken'},
        ),
      );
      
      setState(() {
        _resultMessage = 'Check-in successful!';
        _resultColor = const Color(0xFF4CAF50);
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Check-in successful!'),
            ],
          ),
          backgroundColor: const Color(0xFF4CAF50),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      
    } catch (e) {
      final errorMessage = 'Check-in failed: '
          '${e is DioError ? e.response?.data['message'] ?? e.message : e.toString()}';
      
      setState(() {
        _resultMessage = errorMessage;
        _resultColor = const Color(0xFFE53E3E);
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(errorMessage)),
            ],
          ),
          backgroundColor: const Color(0xFFE53E3E),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;
    
    final code = capture.barcodes.firstOrNull?.rawValue;
    if (code != null && code.isNotEmpty) {
      if (!_shouldProcessScan(code)) {
        return;
      }
      
      _lastScannedCode = code;
      _lastScanTime = DateTime.now();
      
      // Add haptic feedback
      // HapticFeedback.mediumImpact(); // Uncomment if you want haptic feedback
      
      _verifyTicket(code);
    }
  }

  Future<void> _resumeScanning() async {
    setState(() {
      _resultMessage = null;
      _isProcessing = false;
      _lastScannedCode = null;
      _lastScanTime = null;
      _cameraActive = true;
    });
    
    try {
      await _controller.start();
      _pulseController.repeat(reverse: true);
    } catch (e) {
      print('Error restarting scanner: $e');
    }
  }

  Future<void> _toggleFlash() async {
    setState(() {
      _flashEnabled = !_flashEnabled;
    });
    await _controller.toggleTorch();
  }

  Widget _buildScanningOverlay() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.7),
            Colors.transparent,
            Colors.transparent,
            Colors.black.withOpacity(0.7),
          ],
          stops: const [0.0, 0.3, 0.7, 1.0],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _cameraActive ? _pulseAnimation.value : 1.0,
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.white,
                        width: 3,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Stack(
                      children: [
                        // Corner decorations
                        ...List.generate(4, (index) {
                          return Positioned(
                            top: index < 2 ? 8 : null,
                            bottom: index >= 2 ? 8 : null,
                            left: index % 2 == 0 ? 8 : null,
                            right: index % 2 == 1 ? 8 : null,
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                border: Border(
                                  top: index < 2 ? const BorderSide(color: Color(0xFF00BCD4), width: 4) : BorderSide.none,
                                  bottom: index >= 2 ? const BorderSide(color: Color(0xFF00BCD4), width: 4) : BorderSide.none,
                                  left: index % 2 == 0 ? const BorderSide(color: Color(0xFF00BCD4), width: 4) : BorderSide.none,
                                  right: index % 2 == 1 ? const BorderSide(color: Color(0xFF00BCD4), width: 4) : BorderSide.none,
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Text(
                _cameraActive ? 'Point camera at QR code' : 'Processing...',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProcessingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.8),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(
                    color: Color(0xFF00BCD4),
                    strokeWidth: 3,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Verifying ticket...',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please wait',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard() {
    final isSuccess = _resultColor == const Color(0xFF4CAF50);
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _resultColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _resultColor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _resultColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isSuccess ? Icons.check : Icons.error,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _resultMessage!,
                  style: TextStyle(
                    color: _resultColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _resumeScanning,
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Scan Another Ticket'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00BCD4),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Scan Ticket',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: _cameraActive ? _toggleFlash : null,
            icon: Icon(
              _flashEnabled ? Icons.flash_on : Icons.flash_off,
              color: _cameraActive 
                  ? (_flashEnabled ? const Color(0xFF00BCD4) : Colors.white)
                  : Colors.grey,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  // Camera view
                  ClipRRect(
                    child: MobileScanner(
                      controller: _controller,
                      onDetect: _onDetect,
                      fit: BoxFit.cover,
                    ),
                  ),
                  
                  // Scanning overlay
                  if (_cameraActive && !_isProcessing) _buildScanningOverlay(),
                  
                  // Processing overlay
                  if (_isProcessing) _buildProcessingOverlay(),
                ],
              ),
            ),
            
            // Bottom section
            Container(
              color: Colors.grey[900],
              child: Column(
                children: [
                  // Progress indicator
                  if (_isProcessing)
                    const LinearProgressIndicator(
                      color: Color(0xFF00BCD4),
                      backgroundColor: Colors.transparent,
                    ),
                  
                  // Result message
                  if (_resultMessage != null) _buildResultCard(),
                  
                  // Instructions (when not showing results)
                  if (_resultMessage == null && !_isProcessing)
                    Container(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Icon(
                            Icons.qr_code_2,
                            size: 32,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Position the QR code within the frame',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'The camera will automatically scan when detected',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}