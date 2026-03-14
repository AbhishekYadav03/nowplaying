import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/notification_service.dart';
import 'theme.dart';
import 'router.dart';

class NowPlayingApp extends ConsumerStatefulWidget {
  const NowPlayingApp({super.key});

  @override
  ConsumerState<NowPlayingApp> createState() => _NowPlayingAppState();
}

class _NowPlayingAppState extends ConsumerState<NowPlayingApp> {
  final GlobalKey<ScaffoldMessengerState> _messengerKey = GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    _setupNotifications();
  }

  Future<void> _setupNotifications() async {
    final router = ref.read(routerProvider);
    await ref.read(notificationServiceProvider).initialize(messengerKey: _messengerKey, router: router);
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Softsync',
      scaffoldMessengerKey: _messengerKey,
      theme: AppTheme.dark,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
