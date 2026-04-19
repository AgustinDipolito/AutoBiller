import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrScanPage extends StatefulWidget {
  const QrScanPage({Key? key}) : super(key: key);

  @override
  State<QrScanPage> createState() => _QrScanPageState();
}

class _QrScanPageState extends State<QrScanPage> {
  bool _isDetected = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escanear QR'),
      ),
      body: MobileScanner(
        onDetect: (capture) {
          if (_isDetected) return;
          if (capture.barcodes.isEmpty) return;

          final barcode = capture.barcodes.firstWhere(
            (b) => b.rawValue != null && b.rawValue!.isNotEmpty,
            orElse: () => capture.barcodes.first,
          );
          final rawValue = barcode.rawValue;
          if (rawValue == null || rawValue.isEmpty) return;

          _isDetected = true;
          Navigator.of(context).pop(rawValue);
        },
      ),
    );
  }
}
