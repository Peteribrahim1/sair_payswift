import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'providers/wallet_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/splash/splash_screen.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
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

