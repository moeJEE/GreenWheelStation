import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:ev_charging_app/core/services/station_service.dart';
import 'package:ev_charging_app/features/charging_stations/presentation/pages/station_details_page.dart';

import '../../../../core/models/station.dart';

class QRScannerPage extends StatefulWidget {
  const QRScannerPage({super.key});

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  final _stationService = StationService();
  MobileScannerController controller = MobileScannerController();
  bool _isProcessing = false;
  bool _isFlashOn = false;
  bool _isFrontCamera = false;

  Future<void> _processBarcode(BarcodeCapture capture) async {
    if (!_isProcessing) {
      final List<Barcode> barcodes = capture.barcodes;
      for (final barcode in barcodes) {
        if (barcode.rawValue != null) {
          await _processQRCode(barcode.rawValue!);
          break;
        }
      }
    }
  }

  Future<void> _processQRCode(String stationId) async {
    setState(() => _isProcessing = true);
    
    try {
      // Get station details
      final stationData = await _stationService.getStationDetails(stationId);
      
      if (stationData == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid QR code. Station not found.'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() => _isProcessing = false);
        }
        return;
      }

      // Add to favorites
      await _stationService.addToFavorites(stationId);

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Station added to favorites!'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to station details
        final station = Station.fromJson(stationId, stationData);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => StationDetailsPage(
              station: station,
            ),
          ),
        );
      }
    } catch (e) {
      print('Error processing QR code: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error processing QR code. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Station QR Code'),
        actions: [
          IconButton(
            icon: Icon(_isFlashOn ? Icons.flash_on : Icons.flash_off),
            onPressed: () {
              controller.toggleTorch();
              setState(() => _isFlashOn = !_isFlashOn);
            },
          ),
          IconButton(
            icon: Icon(_isFrontCamera ? Icons.camera_front : Icons.camera_rear),
            onPressed: () {
              controller.switchCamera();
              setState(() => _isFrontCamera = !_isFrontCamera);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                flex: 5,
                child: MobileScanner(
                  controller: controller,
                  onDetect: _processBarcode,
                  overlayBuilder: (context, constraints) {
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                      ),
                      child: Stack(
                        children: [
                          Center(
                            child: Container(
                              width: 250,
                              height: 250,
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                border: Border.all(
                                  color: Theme.of(context).primaryColor,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Expanded(
                flex: 1,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      'Scan the station QR code to add it to favorites and start charging',
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
