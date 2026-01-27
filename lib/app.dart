import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'shared/navigation/app_router.dart';

import 'shared/widgets/error_boundary.dart';

class AirmangoApp extends ConsumerStatefulWidget {
  const AirmangoApp({super.key});

  @override
  ConsumerState<AirmangoApp> createState() => _AirmangoAppState();
}

class _AirmangoAppState extends ConsumerState<AirmangoApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint('App Lifecycle: $state');
    if (state == AppLifecycleState.resumed) {
      // Force rebuild to refresh state when app resumes
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeState = ref.watch(themeNotifierProvider);
    
    final router = ref.watch(AppRouter.routerProvider);
    
    return AppErrorBoundary(
      child: MaterialApp.router(
        title: 'Airmango Creator',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeState.themeMode,
        routerConfig: router,
      ),
    );
  }
}
