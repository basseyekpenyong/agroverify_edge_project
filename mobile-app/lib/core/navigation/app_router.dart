import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/transactions/screens/new_transaction_screen.dart';
import '../../features/transactions/screens/transaction_list_screen.dart';
import '../../features/transactions/screens/transaction_detail_screen.dart';
import '../../features/sync/screens/sync_dashboard_screen.dart';
import '../../features/settings/screens/settings_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isAuthenticated = authState.value?.isAuthenticated ?? false;
      final isLoginRoute = state.matchedLocation == '/login';
      if (!isAuthenticated && !isLoginRoute) return '/login';
      if (isAuthenticated && isLoginRoute) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
          GoRoute(path: '/transactions', builder: (_, __) => const TransactionListScreen()),
          GoRoute(path: '/transactions/new', builder: (_, __) => const NewTransactionScreen()),
          GoRoute(
            path: '/transactions/:id',
            builder: (_, state) => TransactionDetailScreen(id: state.pathParameters['id']!),
          ),
          GoRoute(path: '/sync', builder: (_, __) => const SyncDashboardScreen()),
          GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
        ],
      ),
    ],
  );
});

class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final tabIndex = switch (location) {
      String l when l.startsWith('/transactions') => 1,
      '/sync' => 2,
      '/settings' => 3,
      _ => 0,
    };

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: tabIndex,
        onDestinationSelected: (i) => switch (i) {
          0 => context.go('/home'),
          1 => context.go('/transactions'),
          2 => context.go('/sync'),
          _ => context.go('/settings'),
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.list_outlined), selectedIcon: Icon(Icons.list), label: 'Transactions'),
          NavigationDestination(icon: Icon(Icons.sync_outlined), selectedIcon: Icon(Icons.sync), label: 'Sync'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}
