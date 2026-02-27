import 'package:flutter/foundation.dart';
import 'package:root_checker_plus/root_checker_plus.dart';
import 'dart:io';

class RootDetectionService {
  static Future<bool> isDeviceCompromised() async {
    if (kIsWeb) return false; // Root detection not applicable to web

    if (Platform.isAndroid) {
      bool isRooted = await RootCheckerPlus.isRootChecker() ?? false;
      return isRooted;
    } else if (Platform.isIOS) {
      bool isJailbroken = await RootCheckerPlus.isJailbreak() ?? false;
      return isJailbroken;
    }
    return false;
  }
}
