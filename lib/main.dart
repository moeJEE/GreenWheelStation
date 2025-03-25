import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:ev_charging_app/core/config/firebase_options.dart';
import 'package:ev_charging_app/core/services/auth_service.dart';
import 'package:ev_charging_app/core/services/firestore_service.dart';
import 'package:ev_charging_app/core/services/station_service.dart';
import 'package:ev_charging_app/core/routes/app_routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Forcer l'orientation en mode portrait uniquement
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize services
  final authService = await AuthService.init();

  runApp(MyApp(authService: authService));
}

class MyApp extends StatelessWidget {
  final AuthService authService;

  const MyApp({super.key, required this.authService});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => authService),
        Provider<FirestoreService>(create: (_) => FirestoreService()),
        Provider<StationService>(
          create: (context) => StationService(
            firestoreService:
                Provider.of<FirestoreService>(context, listen: false),
          ),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'EV Charging App',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        initialRoute: AppRoutes.splash,
        routes: AppRoutes.getRoutes(),
        onGenerateRoute: AppRoutes.generateRoute,
      ),
    );
  }
}
