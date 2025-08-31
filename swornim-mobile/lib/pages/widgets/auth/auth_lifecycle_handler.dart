import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swornim/pages/providers/auth/auth_provider.dart';

class AuthLifecycleHandler extends ConsumerStatefulWidget {
  final Widget child;

  const AuthLifecycleHandler({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  ConsumerState<AuthLifecycleHandler> createState() => _AuthLifecycleHandlerState();
}

class _AuthLifecycleHandlerState extends ConsumerState<AuthLifecycleHandler> 
    with WidgetsBindingObserver {
  
  AppLifecycleState? _lastLifecycleState;
  DateTime? _lastPauseTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _lastLifecycleState = WidgetsBinding.instance.lifecycleState;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print('🔄 App lifecycle changed from $_lastLifecycleState to $state');
    
    // Handle app resume after being in background
    if (_lastLifecycleState == AppLifecycleState.paused && 
        state == AppLifecycleState.resumed) {
      _handleAppResume();
    }
    
    // Handle app going to background
    if (state == AppLifecycleState.paused) {
      _handleAppPause();
    }
    
    // Always notify the auth provider
    ref.read(authProvider.notifier).handleAppLifecycleChange(state);
    
    _lastLifecycleState = state;
  }

  void _handleAppResume() {
    print('🔄 App resumed from background');
    
    // Check how long the app was in background
    if (_lastPauseTime != null) {
      final backgroundDuration = DateTime.now().difference(_lastPauseTime!);
      print('🔄 App was in background for: ${backgroundDuration.inSeconds} seconds');
      
      // If app was in background for more than 30 seconds, validate auth
      if (backgroundDuration.inSeconds > 30) {
        print('🔄 App was in background for extended time, validating auth');
        Future.microtask(() {
          ref.read(authProvider.notifier).checkAndRestoreAuth();
        });
      }
    }
    
    _lastPauseTime = null;
  }

  void _handleAppPause() {
    print('🔄 App paused/going to background');
    _lastPauseTime = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    // Listen to auth state changes and handle any auth-related UI updates
    ref.listen<AuthState>(authProvider, (previous, next) {
      // Handle automatic logout scenarios
      if (previous?.isLoggedIn == true && next.isLoggedIn == false) {
        print('🔄 User logged out - previous: ${previous?.isLoggedIn}, current: ${next.isLoggedIn}');
        // You can add navigation logic here if needed
      }
      
      // Handle login state restoration
      if (previous?.isLoggedIn == false && next.isLoggedIn == true) {
        print('🔄 User logged in - previous: ${previous?.isLoggedIn}, current: ${next.isLoggedIn}');
      }
    });

    return widget.child;
  }
}