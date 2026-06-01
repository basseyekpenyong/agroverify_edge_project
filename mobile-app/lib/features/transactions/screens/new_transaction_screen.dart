import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/commodities.dart';
import '../../../core/database/transaction_dao.dart';
import '../../auth/providers/auth_provider.dart';
import '../../voice/services/whisper_service.dart';
import '../../voice/widgets/voice_input_button.dart';

class NewTransactionScreen extends ConsumerStatefulWidget {
  const NewTransactionScreen({super.key});

  @override
  ConsumerState<NewTransactionScreen> createState() => _NewTransactionScreenState();
}

class _NewTransactionScreenState extends ConsumerState<NewTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  String _commodity = Commodities.all.first;
  String _unit = Commodities.units.first;
  final _weightCtrl = TextEditingController();
  final _buyerCtrl = TextEditingController();
  final _sellerCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  Position? _position;
  bool _locating = false;
  bool _saving = false;
  WhisperLanguage _language = WhisperLanguage.hausa;

  @override
  void initState() {
    super.initState();
    _captureGps();
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _buyerCtrl.dispose();
    _sellerCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _captureGps() async {
    setState(() => _locating = true);
    try {
      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) await Geolocator.requestPermission();
      _position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (_) {
      _position = await Geolocator.getLastKnownPosition();
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_position == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Waiting for GPS — please try again')),
      );
      return;
    }
    setState(() => _saving = true);
    final agent = ref.read(authStateProvider).value?.agent;
    try {
      final dao = TransactionDao.fromSingleton();
      await dao.insert(
        commodityType: _commodity,
        weight: double.parse(_weightCtrl.text),
        unit: _unit,
        buyerId: _buyerCtrl.text.trim(),
        sellerId: _sellerCtrl.text.trim(),
        gpsLat: _position!.latitude,
        gpsLng: _position!.longitude,
        gpsAccuracy: _position!.accuracy,
        agentId: agent!.id,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Transaction'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // GPS indicator
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _position != null ? AppColors.primary.withValues(alpha:0.1) : AppColors.warning.withValues(alpha:0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(_locating ? Icons.gps_not_fixed : Icons.gps_fixed,
                      color: _position != null ? AppColors.primary : AppColors.warning),
                  const SizedBox(width: 8),
                  Text(
                    _locating
                        ? 'Acquiring GPS…'
                        : _position != null
                            ? 'GPS: ${_position!.latitude.toStringAsFixed(5)}, ${_position!.longitude.toStringAsFixed(5)} (±${_position!.accuracy.toStringAsFixed(0)}m)'
                            : 'GPS unavailable — tap to retry',
                    style: const TextStyle(fontSize: 12),
                  ),
                  if (!_locating && _position == null)
                    IconButton(icon: const Icon(Icons.refresh), onPressed: _captureGps),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Language selector for voice input
            Row(
              children: [
                const Icon(Icons.language, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                const Text('Voice language:', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(width: 8),
                DropdownButton<WhisperLanguage>(
                  value: _language,
                  isDense: true,
                  underline: const SizedBox(),
                  items: WhisperLanguage.values
                      .map((l) => DropdownMenuItem(value: l, child: Text(l.label, style: const TextStyle(fontSize: 13))))
                      .toList(),
                  onChanged: (v) => setState(() => _language = v!),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Commodity
            DropdownButtonFormField<String>(
              initialValue: _commodity,
              decoration: const InputDecoration(labelText: 'Commodity Type', border: OutlineInputBorder()),
              items: Commodities.all.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _commodity = v!),
            ),
            const SizedBox(height: 12),
            // Weight + unit
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _weightCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Weight', border: OutlineInputBorder()),
                    validator: (v) => (v == null || double.tryParse(v) == null) ? 'Enter a valid number' : null,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    initialValue: _unit,
                    decoration: const InputDecoration(labelText: 'Unit', border: OutlineInputBorder()),
                    items: Commodities.units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                    onChanged: (v) => setState(() => _unit = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _buyerCtrl,
              decoration: InputDecoration(
                labelText: 'Buyer ID / Name',
                border: const OutlineInputBorder(),
                suffixIcon: VoiceInputButton(
                  language: _language,
                  onTranscript: (t) => setState(() => _buyerCtrl.text = t),
                ),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _sellerCtrl,
              decoration: InputDecoration(
                labelText: 'Seller ID / Name',
                border: const OutlineInputBorder(),
                suffixIcon: VoiceInputButton(
                  language: _language,
                  onTranscript: (t) => setState(() => _sellerCtrl.text = t),
                ),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Notes (optional)',
                border: const OutlineInputBorder(),
                suffixIcon: VoiceInputButton(
                  language: _language,
                  onTranscript: (t) => setState(() => _notesCtrl.text = t),
                ),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _saving
                  ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                  : const Text('Save Transaction', style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
