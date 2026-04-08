import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

class DeviceService {
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  Future<String> getDeviceId() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        return androidInfo.id;
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return iosInfo.identifierForVendor ?? 'unknown_ios_id';
      }
    } catch (_) {
      return 'unknown_device';
    }
    return 'unknown_device';
  }
}

