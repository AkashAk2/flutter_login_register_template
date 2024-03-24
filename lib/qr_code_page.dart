import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';

class QRCodePage extends StatefulWidget {
  @override
  _QRCodePageState createState() => _QRCodePageState();
}

class _QRCodePageState extends State<QRCodePage> {
  bool _isShowingQRCode = true; // By default, we show the QR Code.

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final String userId = user?.uid ?? 'no-user'; // If user is null, use 'no-user'

    return Scaffold(
      appBar: AppBar(
        title: Text('QR Code'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // This switch toggles between showing the QR code and scanning mode.
            SwitchListTile(
              title: Text(_isShowingQRCode ? 'Show QR Code' : 'Scan QR Code'),
              value: _isShowingQRCode,
              onChanged: (bool value) {
                setState(() {
                  _isShowingQRCode = value;
                });
              },
            ),
            // Display QR code if _isShowingQRCode is true
            if (_isShowingQRCode)
              QrImageView(
                data: userId, // This is the data that will be encoded into the QR code.
                version: QrVersions.auto, // Automatically tries to find the best QR version.
                size: 200.0, // Size of the QR code.
                gapless: false, // To prevent gaps in the QR code
              ),
            // Placeholder for the scanner if _isShowingQRCode is false
            if (!_isShowingQRCode)
              Text('QR Code Scanner (Placeholder)'),
              // You would use a package like barcode_scan to implement the scanner.
          ],
        ),
      ),
    );
  }
}
