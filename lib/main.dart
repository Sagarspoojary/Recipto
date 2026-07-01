import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/routes/routes.dart';
import 'core/theme/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
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
