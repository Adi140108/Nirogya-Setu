import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../../core/services/health_repository.dart';
import '../../../core/services/patient_qr.dart';
import '../../asha_portal/screens/patient_detail_screen.dart';

/// Scans a citizen's Nirogya Setu QR code and opens that citizen's record,
/// replacing manual search by name or phone number.
class PatientQrScannerScreen extends StatefulWidget {
  final Color accentColor;

  const PatientQrScannerScreen({super.key, this.accentColor = const Color(0xFF3B6634)});

  @override
  State<PatientQrScannerScreen> createState() => _PatientQrScannerScreenState();
}

class _PatientQrScannerScreenState extends State<PatientQrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: const [BarcodeFormat.qrCode],
  );
  bool _busy = false;
  String? _message;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_busy) return;
    final raw = capture.barcodes.map((b) => b.rawValue).whereType<String>().firstOrNull;
    if (raw == null) return;

    final parsed = PatientQr.decode(raw);
    if (parsed == null) {
      setState(() => _message = 'This is not a Nirogya Setu citizen QR code.');
      return;
    }

    setState(() {
      _busy = true;
      _message = 'Opening citizen record…';
    });
    final patient = await context
        .read<HealthRepository>()
        .resolveScannedPatient(patientId: parsed.patientId, abhaNumber: parsed.abhaNumber);
    if (!mounted) return;

    if (patient == null) {
      setState(() {
        _busy = false;
        _message = 'Citizen not found. Check the internet connection and try again.';
      });
      return;
    }
    await _controller.stop();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => PatientDetailScreen(patientId: patient.id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final frame = MediaQuery.of(context).size.width * 0.7;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: widget.accentColor,
        foregroundColor: Colors.white,
        title: const Text('Scan Citizen QR', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            tooltip: 'Torch',
            icon: const Icon(Icons.flashlight_on_rounded),
            onPressed: () => _controller.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  error.errorCode == MobileScannerErrorCode.permissionDenied
                      ? 'Camera permission is needed to scan. Allow camera access in Settings.'
                      : 'Camera unavailable: ${error.errorDetails?.message ?? error.errorCode.name}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ),
          ),
          Center(
            child: Container(
              width: frame,
              height: frame,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 3),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 40,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  if (_busy)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  else
                    const Icon(Icons.qr_code_2_rounded, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _message ?? 'Point the camera at the QR code on the citizen\'s Nirogya Setu health card.',
                      style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
