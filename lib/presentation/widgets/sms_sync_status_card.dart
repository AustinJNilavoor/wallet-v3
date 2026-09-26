import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:wallet/data/models/sms_sync_state.dart';

/// Shows a summary of the last SMS sync run: when it happened, whether
/// it succeeded, and how many messages were scanned/imported/ignored.
class SmsSyncStatusCard extends StatelessWidget {
  final SmsSyncState state;
  final bool isSyncing;

  const SmsSyncStatusCard({
    super.key,
    required this.state,
    this.isSyncing = false,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM, hh:mm a');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isSyncing
                      ? Icons.sync
                      : (state.lastSyncSuccessful
                            ? Icons.check_circle
                            : Icons.error_outline),
                  color: isSyncing
                      ? Theme.of(context).colorScheme.primary
                      : (state.lastSyncSuccessful ? Colors.green : Colors.red),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isSyncing
                        ? 'Syncing…'
                        : (state.lastSyncCompletedAt == null
                              ? 'Not synced yet'
                              : 'Last synced ${dateFormat.format(state.lastSyncCompletedAt!.toLocal())}'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),

            if (!isSyncing &&
                !state.lastSyncSuccessful &&
                state.lastError != null) ...[
              const SizedBox(height: 8),
              Text(
                state.lastError!,
                style: const TextStyle(color: Colors.red, fontSize: 13),
              ),
            ],

            if (state.lastSyncCompletedAt != null) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  _StatChip(label: 'Scanned', value: state.lastScanCount),
                  const SizedBox(width: 8),
                  _StatChip(
                    label: 'Imported',
                    value: state.lastImportedCount,
                    color: Colors.green,
                  ),
                  const SizedBox(width: 8),
                  _StatChip(
                    label: 'Duplicate',
                    value: state.lastDuplicateCount,
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  _StatChip(
                    label: 'Unmatched',
                    value: state.lastUnmatchedCount,
                    color: Colors.grey,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final int value;
  final Color? color;

  const _StatChip({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: (color ?? Theme.of(context).colorScheme.primary).withValues(
            alpha: 0.1,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              '$value',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: color ?? Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
