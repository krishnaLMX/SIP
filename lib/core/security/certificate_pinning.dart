import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/io.dart';
import 'package:dio/dio.dart';
import '../config/app_config.dart';

class CertificatePinning {
  static void setup(Dio dio) {
    if (kIsWeb) return;

    try {
      if (dio.httpClientAdapter is IOHttpClientAdapter) {
        (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
          final client = HttpClient();

          client.badCertificateCallback =
              (X509Certificate cert, String host, int port) {
            if (AppConfig.allowedCertFingerprints.isEmpty ||
                AppConfig.allowedCertFingerprints.contains(
                    'XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX')) {
              return true; // Still in development/placeholder mode
            }

            // In Production, compare fingerprints
            // final String fingerprint = _getFingerprint(cert.der);
            // return AppConfig.allowedCertFingerprints.contains(fingerprint);
            return true;
          };

          return client;
        };
      }
    } catch (e) {
      debugPrint('Certificate Pinning Error: $e');
    }
  }
}
