import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/splash_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/chat/chat_screen.dart';
import 'screens/workspace/join_workspace_screen.dart';
import 'screens/workspace/create_workspace_screen.dart';
import 'theme/app_theme.dart';

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (_, _) => const SplashScreen()),
    GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
    GoRoute(path: '/register', builder: (_, _) => const RegisterScreen()),
    GoRoute(path: '/join', builder: (_, _) => const JoinWorkspaceScreen()),
    GoRoute(
      path: '/create-workspace',
      builder: (_, _) => const CreateWorkspaceScreen(),
    ),
    GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
    GoRoute(
      path: '/chat/:id',
      builder: (_, state) => ChatScreen(
        conversationId: state.pathParameters['id']!,
        title: state.uri.queryParameters['title'] ?? 'Conversation',
      ),
    ),
  ],
);

class CollaborationApp extends StatelessWidget {
  const CollaborationApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp.router(
    title: 'SyncUp',
    debugShowCheckedModeBanner: false,
    routerConfig: _router,
    theme: AppTheme.light,
    darkTheme: AppTheme.dark,
    themeMode: ThemeMode.system,
  );
}
