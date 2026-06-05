import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'providers/wallet_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/splash/splash_screen.dart';
import 'core/theme/app_theme.dart';
import 'services/api_service.dart';

// Handle background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: 'AIzaSyALXuJqH9E9Y1xqzMSiV21Z9hE-eZ0p1EY',
      appId: '1:636797020131:android:16c76404f71ea7c49c62d6',
      messagingSenderId: '636797020131',
      projectId: 'sairpayswift',
      storageBucket: 'sairpayswift.firebasestorage.app',
    ),
  );
  debugPrint("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'AIzaSyALXuJqH9E9Y1xqzMSiV21Z9hE-eZ0p1EY',
        appId: '1:636797020131:android:16c76404f71ea7c49c62d6',
        messagingSenderId: '636797020131',
        projectId: 'sairpayswift',
        storageBucket: 'sairpayswift.firebasestorage.app',
      ),
    );
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  } catch (e) {
    debugPrint("Firebase init failed: $e");
  }
  
  // Set up AdMob request configuration with test devices to prevent invalid traffic bans
  final requestConfiguration = RequestConfiguration(
    testDeviceIds: [
      "33BE2250B7D69D358ACF75E4D0F4D373", // Example Android Emulator ID
    ],
  );
  await MobileAds.instance.updateRequestConfiguration(requestConfiguration);
  
  // Initialize Google Mobile Ads SDK
  await MobileAds.instance.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => WalletProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const PaySwiftApp(),
    ),
  );
}

class PaySwiftApp extends StatelessWidget {
  const PaySwiftApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'PaySwift',
          debugShowCheckedModeBanner: false,
          themeMode: themeProvider.themeMode,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          home: const SplashScreen(),
        );
      },
    );
  }
}

