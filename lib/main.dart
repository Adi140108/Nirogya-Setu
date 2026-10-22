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
import 'core/sync/offline_sync_manager.dart';

import 'features/auth/screens/login_screen.dart';
import 'features/asha_portal/screens/asha_dashboard_screen.dart';
import 'features/doctor_portal/screens/doctor_dashboard_screen.dart';
import 'features/patient_portal/screens/patient_dashboard_screen.dart';
import 'features/shared/screens/splash_screen.dart';

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

  // 2. Initialize persistent local storage
  final storageService = StorageService();
  await storageService.init();

  // 3. Initialize repositories & managers
  final healthRepo = HealthRepository(storageService);
  final authService = AuthService(storageService);
  final videoManager = OfflineVideoManager(storageService);
  final syncManager = OfflineSyncManager(healthRepo);

  runApp(
    MultiProvider(
      providers: [
        Provider<StorageService>.value(value: storageService),
        ChangeNotifierProvider<AuthService>.value(value: authService),
        ChangeNotifierProvider<HealthRepository>.value(value: healthRepo),
        ChangeNotifierProvider<OfflineVideoManager>.value(value: videoManager),
        ChangeNotifierProvider<OfflineSyncManager>.value(value: syncManager),
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
      title: 'AarogyaSetu AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          surface: Colors.white,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: false,
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
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
      home: const SplashScreen(),
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
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppColors.primary),
              SizedBox(height: 16),
              Text(
                'AarogyaSetu AI loading...',
                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDark),
              ),
            ],
          ),
        ),
      );
    }

    if (!authService.isAuthenticated || authService.currentUser == null) {
      return const LoginScreen();
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
