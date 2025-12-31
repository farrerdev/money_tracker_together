import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/money_tracker/presentation/providers/tracker_providers.dart';
import 'features/money_tracker/presentation/screens/home_screen.dart';
import 'firebase_options.dart'; // Uncomment this after running flutterfire configure

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // TODO: Run 'flutterfire configure' to generate firebase_options.dart
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // For now, we might need a dummy Firebase initialization if we want to run without errors
  // but since we don't have the config, the app will crash if we try to use Firebase features.
  // The user MUST configure Firebase.

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Logic Auto Login Anonymous
    // We listen to the auth state. If no user is logged in, we sign in anonymously.
    // Note: This requires Firebase to be initialized.
    ref.listen(authStateProvider, (previous, next) async {
       if (next.value == null) {
         try {
           await ref.read(authProvider).signInAnonymously();
         } catch (e) {
           debugPrint("Error signing in anonymously: $e");
         }
       }
    });

    return MaterialApp(
      title: 'Money Tracker Together',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.green,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 2,
        )
      ),
      home: const HomeScreen(),
    );
  }
}
