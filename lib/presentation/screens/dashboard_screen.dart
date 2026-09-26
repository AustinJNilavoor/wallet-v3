import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:wallet/core/boxes.dart';
import 'package:wallet/core/source_icons.dart';
import 'package:wallet/data/models/source.dart';
import 'package:reorderables/reorderables.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final format = NumberFormat('##,##,##0.00');
  Set<String> flippedCards = {};
  bool _isBalanceVisible = false;
  Color _getBalanceColor(Source source, double usage) {
    if (!source.isCreditCard) {
      return source.balance >= 0 ? Colors.green : Colors.red;
    }
    if (source.isCreditCard && source.balance > 0) {
      return Colors.green;
    }
    if (usage < 0.3) return Colors.blue;
    if (usage < 0.4) return Colors.orange;
    return Colors.red;
  }

  Color _getProgressColor(double usage) {
    if (usage < 0.3) return Colors.blue;
    if (usage < 0.4) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Wallet",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),

      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          if (flippedCards.isNotEmpty) {
            setState(() {
              flippedCards.clear();
            });
          }
        },
        child: ListView(children: [_buildHeader(), _buildSourceList()]),
      ),
    );
  }

  Widget _buildSourceCard(Source source) {
    double usagePercent = 0.0;

    final creditLimit = source.creditLimit ?? 0;

    if (source.isCreditCard && creditLimit > 0) {
      usagePercent = source.balance.abs() / creditLimit;
      usagePercent = usagePercent.clamp(0.0, 1.0).toDouble();
    }

    final baseColor = Color(source.colorValue);
    final bgColor = baseColor.withValues(alpha: 0.15);
    final isFlipped = flippedCards.contains(source.id);
    return RepaintBoundary(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          setState(() {
            if (isFlipped) {
              flippedCards.remove(source.id);
            } else {
              flippedCards.add(source.id);
            }
          });
        },
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) {
            return SlideTransition(
              position: Tween(
                begin: const Offset(0.2, 0),
                end: Offset.zero,
              ).animate(animation),
              child: FadeTransition(opacity: animation, child: child),
            );
          },
          child: isFlipped
              ? _buildBackCard(source, baseColor)
              : _buildFrontCard(source, baseColor, bgColor, usagePercent),
        ),
      ),
    );
  }

  Widget _buildFrontCard(
    Source source,
    Color baseColor,
    Color bgColor,
    double usagePercent,
  ) {
    return Container(
      height: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: baseColor.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        height: 36,
                        width: 36,
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          SourceIcons.icons[source.iconIndex],
                          size: 18,
                          color: baseColor,
                        ),
                      ),

                      const SizedBox(width: 8),

                      Expanded(
                        child: Text(
                          source.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 12),

                  Text(
                    source.isBalanceHidden
                        ? "₹ ••••••••"
                        : "₹ ${format.format(source.balance.abs())}",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _getBalanceColor(source, usagePercent),
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    "Last update: ${DateFormat('dd/MM hh:mm a').format(source.lastUpdated)}",
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),

                  if (source.isCreditCard) const SizedBox(height: 6),
                ],
              ),
            ),

            if (source.isCreditCard)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: LinearProgressIndicator(
                  value: usagePercent,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getProgressColor(usagePercent),
                  ),
                  minHeight: 6,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackCard(Source source, Color baseColor) {
    return Container(
      height: double.infinity,
      key: ValueKey('${source.id}_back'),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: baseColor.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(source.name, style: const TextStyle(fontSize: 8)),
          _buildSwitchRow(
            title: "Include in total",
            value: source.isIncludedInTotal,
            onChanged: (v) async {
              source.isIncludedInTotal = v;
              try {
                await source.save();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Failed to save changes')),
                );
              }
            },
          ),

          _buildSwitchRow(
            title: "Hide balance",
            value: source.isBalanceHidden,
            onChanged: (v) async {
              source.isBalanceHidden = v;
              try {
                await source.save();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Failed to save changes')),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchRow({
    required String title,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 13)),
        Transform.scale(
          scale: 0.65,
          child: Switch(value: value, onChanged: onChanged),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return ValueListenableBuilder<Box<Source>>(
      valueListenable: Boxes.getSources().listenable(),
      builder: (context, box, _) {
        // Calculations only happen when box updates
        final sources = box.values.toList();
        double availableBalance = sources
            .where((s) => s.isIncludedInTotal)
            .fold(0, (sum, s) => sum + s.balance);
        double totalBalance = sources.fold(0, (sum, s) => sum + s.balance);

        return RepaintBoundary(
          child: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(20),
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade600, Colors.blue.shade800],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Available Balance",
                  style: TextStyle(fontSize: 14, color: Colors.white70),
                ),
                Text(
                  "₹ ${format.format(availableBalance)}",
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 16),
                const Divider(color: Colors.white24, height: 1),
                const SizedBox(height: 10),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Total Balance",
                          style: TextStyle(fontSize: 14, color: Colors.white70),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _isBalanceVisible
                              ? "₹ ${format.format(totalBalance)}"
                              : "₹ ••••••••",
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: Icon(
                        _isBalanceVisible
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.white70,
                      ),
                      onPressed: () {
                        setState(() {
                          _isBalanceVisible = !_isBalanceVisible;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSourceList() {
    return ValueListenableBuilder<Box<Source>>(
      valueListenable: Boxes.getSources().listenable(),
      builder: (context, box, _) {
        final sortedSources = box.values.toList()
          ..sort((a, b) => a.order.compareTo(b.order));

        return Padding(
          padding: const EdgeInsets.all(12.0),
          child: ReorderableWrap(
            spacing: 12,
            runSpacing: 12,
            needsLongPressDraggable: true,
            onReorder: (oldIndex, newIndex) {
              HapticFeedback.mediumImpact();

              final item = sortedSources.removeAt(oldIndex);
              sortedSources.insert(newIndex, item);

              final Map<dynamic, Source> updates = {};
              for (int i = 0; i < sortedSources.length; i++) {
                sortedSources[i].order = i;
                updates[sortedSources[i].key] = sortedSources[i];
              }

              box.putAll(updates);
            },
            children: List.generate(sortedSources.length, (index) {
              final source = sortedSources[index];
              return SizedBox(
                height: 130,
                key: ValueKey(source.id),
                width: MediaQuery.of(context).size.width / 2 - 20,
                child: _buildSourceCard(source),
              );
            }),
          ),
        );
      },
    );
  }
}
