import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';

import 'package:ai_barcode_scanner/ai_barcode_scanner.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:wifi_iot/wifi_iot.dart';

import '../main.dart';

// import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';

class ConnectScreen extends StatefulWidget {
  const ConnectScreen({super.key});

  @override
  State<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen> {
  @override
  void initState() {
    super.initState();

    hotspotSetup();
  }

  hotspotSetup() async {
    // Map<Permission, PermissionStatus> statuses = await [
    //   Permission.location,
    //   Permission.nearbyWifiDevices,
    //   Permission.storage,
    // ].request();
    // statuses.forEach((v,k){v.request();});

      // WiFiForIoTPlugin.showWritePermissionSettings(true);
    await WiFiForIoTPlugin.setEnabled(true);
    var ssid = await WiFiForIoTPlugin.getWiFiAPSSID();
    var pass = await WiFiForIoTPlugin.getWiFiAPPreSharedKey();
    log(" ssid ::: $ssid");
    log(" pass ::: $pass");
  }

  @override
  Widget build(BuildContext context) {
    log("pass");
    // Define your map
    final Map<String, String> wifiData = {
      "ip": "111",
      "ssid": "lskdj",
      "password": "lol",
    };

    // Convert the map to a JSON string
    final String qrData = jsonEncode(wifiData);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gallery app'),
        actions: [
          IconButton(
              onPressed: () async {
                var data = await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => AiBarcodeScanner(
                      onDispose: () {
                        debugPrint("Barcode scanner disposed!");
                      },
                      hideGalleryButton: false,
                      hideSheetDragHandler: true,
                      hideSheetTitle: true,
                      controller: MobileScannerController(
                        detectionSpeed: DetectionSpeed.noDuplicates,
                      ),
                      onDetect: (BarcodeCapture capture) {
                        /// The row string scanned barcode value
                        final String? scannedValue =
                            capture.barcodes.first.rawValue;
                        debugPrint("Barcode scanned: $scannedValue");
                        final Map<String, dynamic> wifiData =
                            jsonDecode(scannedValue!);

                        WifiModel wifiModel = WifiModel.fromJson(wifiData);
                        debugPrint("Barcode scanned: ${wifiModel.ssid}");

                        // /// The `Uint8List` image is only available if `returnImage` is set to `true`.
                        // final Uint8List? image = capture.image;
                        // debugPrint("Barcode image: $image");
                        //
                        // /// row data of the barcode
                        // final Object? raw = capture.raw;
                        // debugPrint("Barcode raw: $raw");
                        //
                        // /// List of scanned barcodes if any
                        // final List<Barcode> barcodes = capture.barcodes;
                        // debugPrint("Barcode list: $barcodes");
                      },
                      // validator: (value) {
                      //   if (value.barcodes.isEmpty) {
                      //     return false;
                      //   }
                      //   if (!(value.barcodes.first.rawValue
                      //       ?.contains('flutter.dev') ??
                      //       false)) {
                      //     return false;
                      //   }
                      //   return true;
                      // },
                    ),
                  ),
                );
              },
              icon: Icon(Icons.qr_code_scanner))
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: SizedBox(
              height: 300,
              width: 300,
              child: PrettyQrView.data(
                data: qrData,
              ),
            ),
          )
        ],
      ),
    );
  }
}

// Model class to represent your WiFi data
class WifiModel {
  final String ip;
  final String ssid;
  final String password;

  WifiModel({
    required this.ip,
    required this.ssid,
    required this.password,
  });

  // Create a model from a JSON map
  factory WifiModel.fromJson(Map<String, dynamic> json) {
    return WifiModel(
      ip: json['ip'],
      ssid: json['ssid'],
      password: json['password'],
    );
  }

  // Convert the model to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'ip': ip,
      'ssid': ssid,
      'password': password,
    };
  }
}
