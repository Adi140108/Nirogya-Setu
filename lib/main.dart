import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'core/constants/app_colors.dart';
import 'core/models/user_model.dart';
import 'core/services/storage_service.dart';
import 'core/services/auth_service.dart';
import 'core/services/health_repository.dart';
import 'core/services/offline_video_manager.dart';
import 'core/services/admin_repository.dart';
import 'core/services/health_video_download_manager.dart';
import 'core/services/app_locale.dart';
import 'core/sync/offline_sync_manager.dart';

import 'features/asha_portal/screens/asha_dashboard_screen.dart';
import 'features/doctor_portal/screens/doctor_dashboard_screen.dart';
import 'features/patient_portal/screens/patient_dashboard_screen.dart';
import 'features/shared/screens/welcome_screen.dart';
import 'features/shared/widgets/notification_banner_overlay.dart';
import 'features/shared/widgets/notification_session_binder.dart';
import 'core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Firebase if platform options available, fallback gracefully
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization notice (running offline/local mode): $e');
  }

  // Notification channel for the Android notification panel
  await NotificationService().init();

  // 2. Initialize persistent local storage
  final storageService = StorageService();
  await storageService.init();

  // 3. Initialize repositories & managers
  final healthRepo = HealthRepository(storageService);
  final authService = AuthService(storageService);
  final videoManager = OfflineVideoManager(storageService);
  final syncManager = OfflineSyncManager(healthRepo);
  final adminRepo = AdminRepository(storageService);
  final healthVideoDownloads = HealthVideoDownloadManager(storageService);

  runApp(
    MultiProvider(
      providers: [
        Provider<StorageService>.value(value: storageService),
        ChangeNotifierProvider<AuthService>.value(value: authService),
        ChangeNotifierProvider<HealthRepository>.value(value: healthRepo),
        ChangeNotifierProvider<OfflineVideoManager>.value(value: videoManager),
        ChangeNotifierProvider<OfflineSyncManager>.value(value: syncManager),
        ChangeNotifierProvider<AdminRepository>.value(value: adminRepo),
        ChangeNotifierProvider<HealthVideoDownloadManager>.value(value: healthVideoDownloads),
        ChangeNotifierProvider<AppLocale>(create: (_) => AppLocale()),
      ],
      child: const AarogyaSetuApp(),
    ),
  );
}

class AarogyaSetuApp extends StatelessWidget {
  const AarogyaSetuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nirogya Setu',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'DMSans',
        fontFamilyFallback: const ['TiroDevanagari'],
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          surface: AppColors.surface,
          onSurface: AppColors.textPrimary,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: AppColors.background,
        cardColor: AppColors.surface,
        dividerColor: AppColors.divider,
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontFamily: 'Fraunces', fontWeight: FontWeight.w700),
          displayMedium: TextStyle(fontFamily: 'Fraunces', fontWeight: FontWeight.w700),
          displaySmall: TextStyle(fontFamily: 'Fraunces', fontWeight: FontWeight.w700),
          headlineLarge: TextStyle(fontFamily: 'Fraunces', fontWeight: FontWeight.w700),
          headlineMedium: TextStyle(fontFamily: 'Fraunces', fontWeight: FontWeight.w700),
          headlineSmall: TextStyle(fontFamily: 'Fraunces', fontWeight: FontWeight.w700),
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: false,
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.paint,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: const StadiumBorder(),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(shape: const StadiumBorder()),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
      builder: (context, child) {
        return NotificationSessionBinder(
          child: NotificationBannerOverlay(child: child ?? const SizedBox.shrink()),
        );
      },
      home: const RootGateScreen(),
    );
  }
}

class RootGateScreen extends StatelessWidget {
  const RootGateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();

    if (authService.isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppColors.primary),
              SizedBox(height: 16),
              Text(
                'Nirogya Setu loading...',
                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDark),
              ),
            ],
          ),
        ),
      );
    }

    if (!authService.isAuthenticated || authService.currentUser == null) {
      return const WelcomeScreen();
    }

    // Role-based authorization & screen routing
    switch (authService.currentUser!.role) {
      case UserRole.asha:
        return const AshaDashboardScreen();
      case UserRole.doctor:
        return const DoctorDashboardScreen();
      case UserRole.patient:
        return const PatientDashboardScreen();
    }
  }
}
