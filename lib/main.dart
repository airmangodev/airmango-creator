import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'shared/services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final container = ProviderContainer();
  
  // Initialize Services
  await container.read(notificationServiceProvider).init();
  
  // Auth check is now handled via AuthViewModel and GoRouter redirect
  debugPrint('Airmango Creator starting...');

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const AirmangoApp(),
    ),
  );
}