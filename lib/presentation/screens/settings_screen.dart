import 'package:flutter/material.dart';
import 'package:wallet/core/backup_service.dart';

import 'package:wallet/presentation/screens/add_category.dart';
import 'package:wallet/presentation/screens/add_source_screen.dart';
import 'package:wallet/presentation/screens/pending_transactions_screen.dart';
import 'package:wallet/presentation/screens/stocks_dashboard_screen.dart';
import 'package:wallet/presentation/screens/sms_sync_settings_screen.dart';
import 'package:wallet/presentation/screens/sms_template_editor_screen.dart';
import 'package:wallet/presentation/screens/sms_templates_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],

      appBar: AppBar(
        title: const Text(
          "Settings",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),

      body: ListView(
        padding: const EdgeInsets.all(20),

        children: [
          // ======================================================
          // MANAGEMENT
          // ======================================================

          _buildSectionTitle("Management"),

          _buildSettingsCard(
            context,

            children: [
              ListTile(
  leading: const Icon(
    Icons.pending_actions,
  ),
  title: const Text(
    'Pending Transactions',
  ),
  subtitle: const Text(
    'Review transactions detected from SMS',
  ),
  trailing: const Icon(
    Icons.chevron_right,
  ),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const PendingTransactionsScreen(),
      ),
    );
  },
),
              _buildSettingItem(
                icon: Icons.category_rounded,
                color: Colors.orange,
                title: "Categories",
                subtitle:
                    "Add or edit spending categories",

                onTap: () =>
                    Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const AddCategoryScreen(),
                  ),
                ),
              ),

              const Divider(
                indent: 50,
              ),

              _buildSettingItem(
                icon:
                    Icons.account_balance_wallet_rounded,
                color: Colors.blue,
                title: "Sources",
                subtitle:
                    "Manage bank accounts and wallets",

                onTap: () =>
                    Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const AddSourceScreen(),
                  ),
                ),
              ),

              const Divider(
                indent: 50,
              ),

              _buildSettingItem(
                icon: Icons.show_chart_rounded,
                color: Colors.teal,
                title: "Stocks",
                subtitle:
                    "Track your stock investments",

                onTap: () =>
                    Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const StocksDashboardScreen(),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // ======================================================
          // SMS MANAGEMENT
          // ======================================================

          _buildSectionTitle("SMS Management"),

          _buildSettingsCard(
            context,
            children: [
              _buildSettingItem(
                icon: Icons.sync_rounded,
                color: Colors.deepPurple,
                title: "SMS Sync Settings",
                subtitle: "Configure SMS synchronization and processing",
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SmsSyncSettingsScreen(),
                  ),
                ),
              ),

              const Divider(indent: 50),

              _buildSettingItem(
                icon: Icons.rule_rounded,
                color: Colors.indigo,
                title: "SMS Templates",
                subtitle: "Manage bank SMS parsing templates",
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SmsTemplatesScreen(),
                  ),
                ),
              ),

              const Divider(indent: 50),

              _buildSettingItem(
                icon: Icons.edit_note_rounded,
                color: Colors.blue,
                title: "New SMS Template",
                subtitle: "Create a template for a bank SMS format",
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SmsTemplateEditorScreen(),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // ======================================================
          // DATA MANAGEMENT
          // ======================================================

          _buildSectionTitle(
            "Data Management",
          ),

          _buildSettingsCard(
            context,

            children: [
              // --------------------------------------------------
              // EXPORT
              // --------------------------------------------------

              _buildSettingItem(
                icon:
                    Icons.upload_rounded,
                color: Colors.indigo,
                title: "Export Backup",
                subtitle:
                    "Save your wallet data as a backup file",

                onTap: () async {
                  try {
                    await BackupService
                        .exportBackup();

                    if (!context.mounted) {
                      return;
                    }

                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(
                      const SnackBar(
                        content: Text(
                          "Backup ready to share",
                        ),
                      ),
                    );
                  } catch (e) {
                    if (!context.mounted) {
                      return;
                    }

                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(
                      SnackBar(
                        content: Text(
                          "Export failed: $e",
                        ),
                      ),
                    );
                  }
                },
              ),

              const Divider(
                indent: 50,
              ),

              // --------------------------------------------------
              // IMPORT
              // --------------------------------------------------

              _buildSettingItem(
                icon:
                    Icons.download_rounded,
                color: Colors.green,
                title: "Import Backup",
                subtitle:
                    "Restore wallet data from a backup file",

                onTap: () async {
                  try {
                    final imported =
                        await BackupService
                            .importBackup();

                    if (!context.mounted) {
                      return;
                    }

                    if (imported) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Backup imported successfully",
                          ),
                        ),
                      );
                    }
                  } catch (e) {
                    if (!context.mounted) {
                      return;
                    }

                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(
                      SnackBar(
                        content: Text(
                          "Import failed: $e",
                        ),
                      ),
                    );
                  }
                },
              ),
            ],
          ),

          const SizedBox(height: 32),

          // ======================================================
          // APP PREFERENCES
          // ======================================================

          _buildSectionTitle(
            "App Preferences",
          ),

          _buildSettingsCard(
            context,

            children: [
              _buildSettingItem(
                icon:
                    Icons.notifications_rounded,
                color: Colors.purple,
                title: "Reminders",
                subtitle:
                    "Daily expense logging alerts",

                onTap: () {
                  // TODO: Implement Notifications
                },
              ),

              const Divider(
                indent: 50,
              ),

              _buildSettingItem(
                icon:
                    Icons.security_rounded,
                color: Colors.green,
                title: "Security",
                subtitle:
                    "App lock and biometrics",

                onTap: () {
                  // TODO: Implement Security
                },
              ),
            ],
          ),

          const SizedBox(height: 32),

          // ======================================================
          // VERSION
          // ======================================================

          const Center(
            child: Text(
              "Wallet v1.0.0",
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

  Widget _buildSectionTitle(
    String title,
  ) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 4,
        bottom: 12,
      ),

      child: Text(
        title.toUpperCase(),

        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  // ============================================================
  // SETTINGS CARD
  // ============================================================

  Widget _buildSettingsCard(
    BuildContext context, {
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(24),

        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withValues(alpha: 0.04),

            blurRadius: 10,

            offset:
                const Offset(0, 4),
          ),
        ],
      ),

      child: Column(
        children: children,
      ),
    );
  }

  // ============================================================
  // SETTING ITEM
  // ============================================================

  Widget _buildSettingItem({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,

      contentPadding:
          const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 4,
      ),

      leading: Container(
        padding:
            const EdgeInsets.all(8),

        decoration: BoxDecoration(
          color:
              color.withValues(alpha: 0.1),

          borderRadius:
              BorderRadius.circular(12),
        ),

        child: Icon(
          icon,
          color: color,
          size: 24,
        ),
      ),

      title: Text(
        title,

        style: const TextStyle(
          fontWeight:
              FontWeight.w600,
          fontSize: 16,
        ),
      ),

      subtitle: Text(
        subtitle,

        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 13,
        ),
      ),

      trailing: const Icon(
        Icons.chevron_right,
        color: Colors.grey,
      ),
    );
  }
}