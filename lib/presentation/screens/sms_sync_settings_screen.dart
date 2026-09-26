import 'package:flutter/material.dart';

import 'package:wallet/core/sms_constants.dart';
import 'package:wallet/data/models/sms_sync_state.dart';
import 'package:wallet/data/repositories/sms_sync_repository.dart';
import 'package:wallet/presentation/screens/sms_mappings_screen.dart';
import 'package:wallet/presentation/screens/sms_templates_screen.dart';
import 'package:wallet/presentation/widgets/sms_sync_status_card.dart';
import 'package:wallet/services/sms/sms_sync_service.dart';

class SmsSyncSettingsScreen extends StatefulWidget {
  const SmsSyncSettingsScreen({super.key});

  @override
  State<SmsSyncSettingsScreen> createState() => _SmsSyncSettingsScreenState();
}

class _SmsSyncSettingsScreenState extends State<SmsSyncSettingsScreen> {
  final _repository = SmsSyncRepository();
  final _syncService = SmsSyncService();

  late SmsSyncState _state;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _state = _repository.getOrCreate();
  }

  Future<void> _setEnabled(bool value) async {
    setState(() => _state.enabled = value);
    await _repository.save(_state);
  }

  Future<void> _setOverlapMinutes(int minutes) async {
    setState(() => _state.overlapMilliseconds = minutes * 60 * 1000);
    await _repository.save(_state);
  }

  Future<void> _syncNow() async {
    if (_isSyncing) return;

    setState(() => _isSyncing = true);

    try {
      final result = await _syncService.sync();

      if (!mounted) return;

      setState(() => _state = _repository.getOrCreate());

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.successful
                ? 'Synced ${result.scanned} message(s), '
                      '${result.imported} imported'
                : 'Sync failed: ${result.error ?? "unknown error"}',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final overlapMinutes = (_state.overlapMilliseconds / (60 * 1000)).round();

    return Scaffold(
      appBar: AppBar(
        title: const Text('SMS Sync Settings'),
        actions: [
          IconButton(
            onPressed: _isSyncing ? null : _syncNow,
            icon: _isSyncing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sync),
            tooltip: 'Sync now',
          ),
        ],
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle('Last Sync'),
          SmsSyncStatusCard(state: _state, isSyncing: _isSyncing),

          const SizedBox(height: 20),

          _sectionTitle('SMS Synchronization'),

          Card(
            child: SwitchListTile(
              title: const Text('Enable SMS Sync'),
              subtitle: const Text(
                'Read and process SMS when the wallet is opened',
              ),
              value: _state.enabled,
              onChanged: _setEnabled,
            ),
          ),

          const SizedBox(height: 20),

          _sectionTitle('Duplicate Protection'),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sync overlap',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    'Read a small period before the last sync '
                    'to avoid missing SMS messages.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),

                  const SizedBox(height: 16),

                  DropdownButtonFormField<int>(
                    value: SmsConstants.overlapMinutePresets.contains(
                      overlapMinutes,
                    )
                        ? overlapMinutes
                        : SmsConstants.defaultOverlapMinutes,
                    decoration: const InputDecoration(
                      labelText: 'Overlap period',
                      border: OutlineInputBorder(),
                    ),
                    items: SmsConstants.overlapMinutePresets
                        .map(
                          (minutes) => DropdownMenuItem(
                            value: minutes,
                            child: Text(
                              minutes == 0 ? 'No overlap' : '$minutes minutes',
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        _setOverlapMinutes(value);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          _sectionTitle('Processing'),

          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.rule),
                  title: const Text('SMS Templates'),
                  subtitle: const Text(
                    'Configure how bank SMS messages are parsed',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SmsTemplatesScreen(),
                      ),
                    );
                  },
                ),

                const Divider(height: 1),

                ListTile(
                  leading: const Icon(Icons.account_tree_outlined),
                  title: const Text('Mappings'),
                  subtitle: const Text(
                    'Configure account and category mappings',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SmsMappingsScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }
}
