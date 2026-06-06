import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/auth/rbac.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/auth_provider.dart';

class DeviceSetupScreen extends ConsumerStatefulWidget {
  const DeviceSetupScreen({super.key});

  @override
  ConsumerState<DeviceSetupScreen> createState() => _DeviceSetupScreenState();
}

class _DeviceSetupScreenState extends ConsumerState<DeviceSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _regionCtrl = TextEditingController();
  final _coopCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();
  final _confirmPinCtrl = TextEditingController();

  UserRole _role = UserRole.fieldAgent;
  bool _loading = false;
  String? _error;

  static const _roleOptions = [
    (label: 'Field Agent', role: UserRole.fieldAgent),
    (label: 'Cooperative Manager', role: UserRole.cooperativeManager),
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _regionCtrl.dispose();
    _coopCtrl.dispose();
    _pinCtrl.dispose();
    _confirmPinCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });

    final ok = await ref.read(authStateProvider.notifier).setupDevice(
      name: _nameCtrl.text.trim(),
      region: _regionCtrl.text.trim(),
      cooperativeId: _coopCtrl.text.trim(),
      role: _role,
      pin: _pinCtrl.text.trim(),
    );

    if (!ok && mounted) {
      setState(() {
        _loading = false;
        _error = 'Setup failed. Please try again.';
      });
    }
    // On success the router redirect fires automatically.
  }

  InputDecoration _field(String label) => InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: AppColors.surface,
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                ClipRect(
                  child: Align(
                    alignment: Alignment.topCenter,
                    heightFactor: 0.58,
                    child: Image.asset('assets/images/logo.png', height: 155),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Device Setup',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Configure this device for a field agent',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 36),

                // Agent Name
                TextFormField(
                  controller: _nameCtrl,
                  decoration: _field('Full Name'),
                  textCapitalization: TextCapitalization.words,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                ),
                const SizedBox(height: 16),

                // Region
                TextFormField(
                  controller: _regionCtrl,
                  decoration: _field('Region'),
                  textCapitalization: TextCapitalization.words,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Region is required' : null,
                ),
                const SizedBox(height: 16),

                // Cooperative ID
                TextFormField(
                  controller: _coopCtrl,
                  decoration: _field('Cooperative ID'),
                  textCapitalization: TextCapitalization.characters,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Cooperative ID is required' : null,
                ),
                const SizedBox(height: 16),

                // Role
                DropdownButtonFormField<UserRole>(
                  initialValue: _role,
                  decoration: _field('Role'),
                  items: _roleOptions
                      .map((o) => DropdownMenuItem(value: o.role, child: Text(o.label)))
                      .toList(),
                  onChanged: (v) { if (v != null) setState(() => _role = v); },
                ),
                const SizedBox(height: 16),

                // PIN
                TextFormField(
                  controller: _pinCtrl,
                  decoration: _field('PIN (4–6 digits)'),
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  validator: (v) {
                    if (v == null || v.trim().length < 4) return 'PIN must be at least 4 digits';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Confirm PIN
                TextFormField(
                  controller: _confirmPinCtrl,
                  decoration: _field('Confirm PIN'),
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  validator: (v) {
                    if (v != _pinCtrl.text) return 'PINs do not match';
                    return null;
                  },
                ),
                const SizedBox(height: 8),

                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: AppColors.error, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ),

                const SizedBox(height: 8),
                FilledButton(
                  onPressed: _loading ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _loading
                      ? const SizedBox(
                          height: 20, width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Set Up Device', style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
