import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/auth/rbac.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../../sync/services/sync_service.dart';

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
          const _SectionHeader('Backend API'),
          ListTile(
            leading: const Icon(Icons.cloud_outlined),
            title: const Text('API Configuration'),
            subtitle: const Text('Set backend URL and auth token'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showApiConfigDialog(context),
          ),
          const Divider(),
          const _SectionHeader('App'),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Version'),
            trailing: Text('1.0.0', style: TextStyle(color: AppColors.textSecondary)),
          ),
          const ListTile(
            leading: Icon(Icons.storage),
            title: Text('Local Database'),
            subtitle: Text('AES-256 encrypted SQLite'),
            trailing: Icon(Icons.lock, color: AppColors.primary, size: 18),
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

  void _showApiConfigDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => const _ApiConfigDialog(),
    );
  }
}

class _ApiConfigDialog extends StatefulWidget {
  const _ApiConfigDialog();

  @override
  State<_ApiConfigDialog> createState() => _ApiConfigDialogState();
}

class _ApiConfigDialogState extends State<_ApiConfigDialog> {
  final _urlCtrl = TextEditingController();
  final _tokenCtrl = TextEditingController();
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final config = await SyncService.loadApiConfig();
    if (!mounted) return;
    _urlCtrl.text = config.baseUrl;
    _tokenCtrl.text = config.token;
    setState(() => _loading = false);
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    _tokenCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await SyncService.saveApiConfig(
      baseUrl: _urlCtrl.text.trim(),
      token: _tokenCtrl.text.trim(),
    );
    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('API configuration saved'), backgroundColor: AppColors.primary),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('API Configuration'),
      content: _loading
          ? const SizedBox(height: 80, child: Center(child: CircularProgressIndicator()))
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _urlCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Backend URL',
                    hintText: 'http://192.168.1.x:8000',
                    border: OutlineInputBorder(),
                    helperText: 'Use your computer\'s local IP for device testing',
                  ),
                  keyboardType: TextInputType.url,
                  autocorrect: false,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _tokenCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Auth Token (optional)',
                    hintText: 'Bearer token from /api/v1/auth/login',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  autocorrect: false,
                ),
              ],
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: (_loading || _saving) ? null : _save,
          style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
          child: _saving
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Save'),
        ),
      ],
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
