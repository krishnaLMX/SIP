import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'core/security/app_lifecycle_observer.dart';
import 'core/security/root_detection_service.dart';
import 'shared/widgets/compromised_device_screen.dart';
import 'shared/widgets/app_control_wrapper.dart';
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

  // 2. UI Config
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // 3. Always start with Flutter splash — it handles session/routing internally
  runApp(const ProviderScope(
    child: MyApp(),
  ));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

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
          themeMode: ThemeMode.light,
          onGenerateRoute: AppRouter.onGenerateRoute,
          initialRoute: AppRouter.splash,
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
          // ── Global gradient background + runtime control wrapper ──
          builder: (context, child) {
            return Container(
              decoration: const BoxDecoration(
                gradient: AppTheme.lightGradient,
              ),
              child: AppControlWrapper(child: child!),
            );
          },
        );
      },
    );
  }
}
