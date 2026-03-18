import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'core/security/secure_storage_service.dart';
import 'core/security/app_lifecycle_observer.dart';
import 'core/security/root_detection_service.dart';
import 'core/security/session_manager.dart';
import 'shared/widgets/compromised_device_screen.dart';
import 'routes/app_router.dart';
import 'shared/theme/app_theme.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/localization/language_provider.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Security Check: Root Detection
  bool isCompromised = false;
  try {
    isCompromised = await RootDetectionService.isDeviceCompromised();
  } catch (e) {
    debugPrint('Security check error: $e');
  }

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
  bool mpinEnabled = await SecureStorageService.isMpinEnabled();

  String initialRoute = AppRouter.onboarding;
  if (onboarded) {
    if (loggedIn) {
      initialRoute = mpinEnabled ? AppRouter.mpin : AppRouter.home;
    } else {
      initialRoute = AppRouter.login;
    }
  }

  // 3. UI Config
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(ProviderScope(child: MyApp(initialRoute: initialRoute)));
}

class MyApp extends ConsumerWidget {
  final String initialRoute;
  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Register Lifecycle Observer
    ref.watch(lifecycleObserverProvider(navigatorKey));

    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        final languageState = ref.watch(languageProvider);

        return MaterialApp(
          title: 'StartGold',
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          initialRoute: initialRoute,
          onGenerateRoute: AppRouter.onGenerateRoute,
          locale: Locale(languageState.currentLocale),
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'),
            Locale('ta'),
            Locale('te'),
          ],
        );
      },
    );
  }
}
