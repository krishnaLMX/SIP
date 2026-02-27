import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'core/security/root_detection_service.dart';
import 'core/security/session_manager.dart';
import 'shared/widgets/compromised_device_screen.dart';
import 'routes/app_router.dart';
import 'shared/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Security Check: Root Detection
  bool isCompromised = await RootDetectionService.isDeviceCompromised();
  if (isCompromised) {
    runApp(const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: CompromisedDeviceScreen(),
    ));
    return;
  }

  // 2. Navigation Logic Check
  bool onboarded = await SessionManager.hasSeenOnboarding();
  bool loggedIn = await SessionManager.isAuthenticated();

  String initialRoute = AppRouter.onboarding;
  if (onboarded) {
    initialRoute = loggedIn ? AppRouter.home : AppRouter.login;
  }

  // 3. UI Config
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(ProviderScope(child: MyApp(initialRoute: initialRoute)));
}

class MyApp extends StatelessWidget {
  final String initialRoute;
  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(390, 844), // iPhone 13 base size
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          title: 'StartGold',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          initialRoute: initialRoute,
          routes: AppRouter.routes,
          onGenerateRoute: AppRouter.onGenerateRoute,
        );
      },
    );
  }
}
