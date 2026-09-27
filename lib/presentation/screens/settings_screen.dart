import 'package:flutter/material.dart';
import 'package:wallet/presentation/screens/add_category.dart';
import 'package:wallet/presentation/screens/add_source_screen.dart';
import 'package:wallet/presentation/screens/create_sms_template_screen.dart';
import 'package:wallet/presentation/screens/sms_list_screen.dart'; // Ensure correct path

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "Settings",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSectionTitle("Management"),
          _buildSettingsCard(
            context,
            children: [
              _buildSettingItem(
                icon: Icons.category_rounded,
                color: Colors.orange,
                title: "Categories",
                subtitle: "Add or edit spending categories",
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddCategoryScreen()),
                ),
              ),
              const Divider(indent: 50),
              _buildSettingItem(
                icon: Icons.account_balance_wallet_rounded,
                color: Colors.blue,
                title: "Sources",
                subtitle: "Manage bank accounts and wallets",
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddSourceScreen()),
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          _buildSectionTitle("App Preferences"),
          _buildSettingsCard(
            context,
            children: [
              _buildSettingItem(
                icon: Icons.notifications_rounded,
                color: Colors.purple,
                title: "Reminders",
                subtitle: "Daily expense logging alerts",
                onTap: () {
                  // TODO: Implement Notifications
                },
              ),
              const Divider(indent: 50),
              _buildSettingItem(
                icon: Icons.security_rounded,
                color: Colors.green,
                title: "Security",
                subtitle: "App lock and biometrics",
                onTap: () {
                  // TODO: Implement Security
                },
              ),
              _buildSettingItem(
                icon: Icons.notifications_rounded,
                color: Colors.purple,
                title: "Reminders",
                subtitle: "Daily expense logging alerts",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SmsListScreen(
                        onSelect: (message) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CreateSmsTemplateScreen(
                                message: message,
                                onSave: (template) {
                                  print(template.toJson());
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                  // TODO: Implement Notifications
                },
              ),
            ],
          ),

          const SizedBox(height: 32),

          // App Version Info
          const Center(
            child: Text(
              "Wallet v1.0.0",
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
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

  Widget _buildSettingsCard(
    BuildContext context, {
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: Colors.grey[600], fontSize: 13),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
    );
  }
}
