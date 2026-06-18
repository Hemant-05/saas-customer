import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/providers.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'screens/menu_screen.dart';
import 'screens/order_tracking_screen.dart';
import 'screens/order_history_screen.dart';
import 'services/notification_service.dart';
import 'providers/theme_provider.dart';
import 'theme/app_theme.dart';

final GoRouter _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/menu/:restaurantId/:tableId',
      builder: (context, state) {
        final restaurantId = state.pathParameters['restaurantId']!;
        final tableId = state.pathParameters['tableId'];
        return MenuScreen(restaurantId: restaurantId, tableId: tableId);
      },
    ),
    GoRoute(
      path: '/menu/:restaurantId',
      builder: (context, state) {
        final restaurantId = state.pathParameters['restaurantId']!;
        return MenuScreen(restaurantId: restaurantId);
      },
    ),
    GoRoute(
      path: '/order/:restaurantId',
      builder: (context, state) {
        final restaurantId = state.pathParameters['restaurantId']!;
        return MenuScreen(restaurantId: restaurantId);
      },
    ),
    GoRoute(
      path: '/orders/:orderId',
      builder: (context, state) {
        final orderId = state.pathParameters['orderId']!;
        return OrderTrackingScreen(orderId: orderId);
      },
    ),
    GoRoute(
      path: '/history',
      builder: (context, state) => const OrderHistoryScreen(),
    ),
  ],
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();

  try {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
    await CustomerNotificationService().initialize();
  } catch (e) {
    debugPrint('[Main] Firebase/notification init failed (non-fatal): $e');
  }

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
  ));
  runApp(const QRCafeCustomerApp());
}

class QRCafeCustomerApp extends StatelessWidget {
  const QRCafeCustomerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CustomerMenuProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => CustomerOrderProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp.router(
            title: 'QR Cafe',
            debugShowCheckedModeBanner: false,
            routerConfig: _router,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
          );
        },
      ),
    );
  }
}
