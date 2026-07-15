import 'package:electrical_shop/app/app.dart';
// import 'package:electrical_shop/firebase_options.dart';
// import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// import 'app/app.dart';
import 'core/services/firebase_service.dart';
import 'core/services/hive_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await FirebaseInitializer.initialize();
  await HiveService.initialize();

  runApp(const ProviderScope(child: ESMSApp()));
}
