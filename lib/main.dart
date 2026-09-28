import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/constants.dart';
import 'screens/login_screen.dart';
import 'screens/vet_shell.dart';
import 'services/session_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Professional clinical status bar overlay
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize session state from SharedPreferences
  await SessionManager().init();

  runApp(const PashuVetApp());
}

class PashuVetApp extends StatelessWidget {
  const PashuVetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SessionManager(),
      builder: (context, _) {
        final session = SessionManager();
        return MaterialApp(
          key: ValueKey('${session.isLoggedIn}_${session.language}'),
          title: VetAppConstants.appName,
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            fontFamily: 'Roboto',
            colorScheme: ColorScheme.fromSeed(
              seedColor: VetAppConstants.primaryBlue,
              primary: VetAppConstants.primaryBlue,
              secondary: VetAppConstants.clinicalTeal,
              surface: Colors.white,
            ),
            scaffoldBackgroundColor: VetAppConstants.background,
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.white,
              elevation: 0,
              centerTitle: false,
              iconTheme: IconThemeData(color: VetAppConstants.primaryNavy),
              titleTextStyle: TextStyle(
                color: VetAppConstants.primaryNavy,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
          ),
          home: session.isLoggedIn
              ? VetShell(onLogout: () {})
              : VetLoginScreen(onLoginSuccess: () {}),
        );
      },
    );
  }
}
