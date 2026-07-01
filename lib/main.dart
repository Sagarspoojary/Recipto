import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/routes/routes.dart';
import 'core/theme/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase using platform-specific options
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Supabase (specifically for storage bucket operations)
  await Supabase.initialize(
    url: 'https://deixphiktjtlvabgbdqu.supabase.co',
    anonKey: 'sb_publishable_i8_vxpu4DUtYbqihlwLYqw_v5bYidz3',
  );

  runApp(
    const ProviderScope(
      child: ReceiptoApp(),
    ),
  );
}

class ReceiptoApp extends StatelessWidget {
  const ReceiptoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Receipto',
      debugShowCheckedModeBanner: false,
      theme: ReceiptoTheme.darkTheme,
      routerConfig: router,
    );
  }
}
