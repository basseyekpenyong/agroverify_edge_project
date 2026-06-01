import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/auth/rbac.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/providers/auth_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agent = ref.watch(authStateProvider).value?.agent;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          if (agent != null) ...[
            const _SectionHeader('Account'),
            ListTile(
              leading: const Icon(Icons.person),
              title: Text(agent.name),
              subtitle: Text('${agent.role.value} · ${agent.region}'),
            ),
            ListTile(
              leading: const Icon(Icons.business),
              title: const Text('Cooperative'),
              subtitle: Text(agent.cooperativeId),
            ),
          ],
          const Divider(),
          const _SectionHeader('App'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Version'),
            trailing: const Text('1.0.0', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ListTile(
            leading: const Icon(Icons.storage),
            title: const Text('Local Database'),
            subtitle: const Text('AES-256 encrypted SQLite'),
            trailing: const Icon(Icons.lock, color: AppColors.primary, size: 18),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.error),
            title: const Text('Sign Out', style: TextStyle(color: AppColors.error)),
            onTap: () => ref.read(authStateProvider.notifier).logout(),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: Text(title,
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary, letterSpacing: 0.5)),
      );
}
