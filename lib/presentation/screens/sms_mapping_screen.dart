import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:wallet/data/models/category.dart';
import 'package:wallet/data/models/sms_mapping.dart';
import 'package:wallet/data/models/sms_mapping_type.dart';
import 'package:wallet/data/models/sms_match_field.dart';
import 'package:wallet/data/models/source.dart';

class SmsMappingScreen extends StatefulWidget {
  const SmsMappingScreen({
    super.key,
  });

  @override
  State<SmsMappingScreen> createState() =>
      _SmsMappingScreenState();
}

class _SmsMappingScreenState extends State<SmsMappingScreen> {
  /*
   * Change these box names if your existing Hive boxes
   * use different names.
   */
  static const String smsMappingBoxName = 'smsMappings';
  static const String sourceBoxName = 'sources';
  static const String categoryBoxName = 'categories';

  late Box<SmsMapping> _mappingBox;
  late Box<Source> _sourceBox;
  late Box<Category> _categoryBox;

  @override
  void initState() {
    super.initState();

    _mappingBox = Hive.box<SmsMapping>(
      smsMappingBoxName,
    );

    _sourceBox = Hive.box<Source>(
      sourceBoxName,
    );

    _categoryBox = Hive.box<Category>(
      categoryBoxName,
    );
  }

  // ===========================================================================
  // DATA
  // ===========================================================================

  List<SmsMapping> get _mappings {
    final mappings = _mappingBox.values.toList();

    mappings.sort(
      (a, b) => b.priority.compareTo(a.priority),
    );

    return mappings;
  }

  /// Active (non-archived) sources — the only ones a *new* mapping
  /// should be assignable to.
  List<Source> get _sources {
    return _sourceBox.values
        .where(
          (source) => !source.isArchived,
        )
        .toList();
  }

  /// All sources, including archived ones. Needed so that an
  /// *existing* mapping pointing at a since-archived source still
  /// resolves to a real name instead of showing "Target not found".
  List<Source> get _allSources {
    return _sourceBox.values.toList();
  }

  List<Category> get _categories {
    return _categoryBox.values.toList();
  }

  // ===========================================================================
  // TARGET NAME
  // ===========================================================================

  String _getTargetName(
    SmsMapping mapping,
  ) {
    if (mapping.mappingType == SmsMappingType.source) {
      for (final source in _allSources) {
        if (source.id == mapping.targetId) {
          return source.name;
        }
      }
    }

    if (mapping.mappingType == SmsMappingType.category) {
      for (final category in _categories) {
        if (category.id == mapping.targetId) {
          return category.name;
        }
      }
    }

    return 'Target not found';
  }

  // ===========================================================================
  // ADD / EDIT MAPPING
  // ===========================================================================

  Future<void> _showMappingDialog({
    SmsMapping? mapping,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _MappingFormSheet(
          mapping: mapping,
          sources: _sources,
          categories: _categories,
          onSave: (newMapping) async {
            await _mappingBox.put(
              newMapping.id,
              newMapping,
            );

            if (!sheetContext.mounted) {
              return;
            }

            Navigator.pop(sheetContext);

            if (!mounted) {
              return;
            }

            setState(() {});

            ScaffoldMessenger.of(
              context,
            ).showSnackBar(
              SnackBar(
                content: Text(
                  mapping != null
                      ? 'Mapping updated'
                      : 'Mapping added',
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ===========================================================================
  // DELETE
  // ===========================================================================

  Future<void> _deleteMapping(
    SmsMapping mapping,
  ) async {
    final bool? confirmed =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Delete Mapping?',
          ),
          content: Text(
            'Remove the mapping for "${mapping.matchValue}"?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text(
                'Cancel',
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: const Text(
                'Delete',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await _mappingBox.delete(
      mapping.id,
    );

    if (!mounted) {
      return;
    }

    setState(() {});

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      const SnackBar(
        content: Text(
          'Mapping deleted',
        ),
      ),
    );
  }

  // ===========================================================================
  // TOGGLE ACTIVE
  // ===========================================================================

  Future<void> _toggleMapping(
    SmsMapping mapping,
    bool value,
  ) async {
    mapping.isActive = value;

    await mapping.save();
  }

  // ===========================================================================
  // INFO CHIP
  // ===========================================================================

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: Colors.grey.shade600,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // MAPPING CARD
  // ===========================================================================

  Widget _buildMappingCard(
    SmsMapping mapping,
  ) {
    final bool isSource =
        mapping.mappingType ==
        SmsMappingType.source;

    final String targetName =
        _getTargetName(mapping);

    final String matchFieldText =
        mapping.matchField ==
                SmsMatchField.sender
            ? 'Sender'
            : 'Message';

    return Container(
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          16,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.04,
            ),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(
          16,
        ),
        onTap: () {
          _showMappingDialog(
            mapping: mapping,
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(
            16,
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: isSource
                          ? const Color(
                              0xFF5C6BC0,
                            ).withValues(
                              alpha: 0.10,
                            )
                          : const Color(
                              0xFF26A69A,
                            ).withValues(
                              alpha: 0.10,
                            ),
                      borderRadius:
                          BorderRadius.circular(
                        11,
                      ),
                    ),
                    child: Icon(
                      isSource
                          ? Icons
                              .account_balance_wallet_outlined
                          : Icons.category_outlined,
                      color: isSource
                          ? const Color(
                              0xFF5C6BC0,
                            )
                          : const Color(
                              0xFF26A69A,
                            ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          mapping.matchValue,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight:
                                FontWeight.w700,
                          ),
                        ),
                        const SizedBox(
                          height: 3,
                        ),
                        Text(
                          matchFieldText,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors
                                .grey
                                .shade600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Switch(
                    value: mapping.isActive,
                    onChanged: (value) {
                      _toggleMapping(
                        mapping,
                        value,
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // --------------------------------------------------------------
              // TARGET
              // --------------------------------------------------------------

              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius:
                      BorderRadius.circular(
                    10,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 18,
                      color:
                          Colors.grey.shade600,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isSource
                          ? 'Source'
                          : 'Category',
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        targetName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight:
                              FontWeight.w600,
                        ),
                        overflow:
                            TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              Row(
                children: [
                  _buildInfoChip(
                    icon:
                        Icons.low_priority_rounded,
                    label:
                        'Priority ${mapping.priority}',
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Delete',
                    onPressed: () {
                      _deleteMapping(
                        mapping,
                      );
                    },
                    icon: const Icon(
                      Icons
                          .delete_outline_rounded,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // EMPTY STATE
  // ===========================================================================

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(
          32,
        ),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(
                  0xFF5C6BC0,
                ).withValues(
                  alpha: 0.10,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.rule_folder_outlined,
                size: 38,
                color: Color(
                  0xFF5C6BC0,
                ),
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'No SMS mappings yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Create mappings to automatically assign sources and categories when importing SMS transactions.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: Colors.grey.shade600,
              ),
            ),

            const SizedBox(height: 22),

            FilledButton.icon(
              onPressed: () {
                _showMappingDialog();
              },
              icon: const Icon(
                Icons.add,
              ),
              label: const Text(
                'Add First Mapping',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor:
            const Color(0xFFF5F7FA),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'SMS Mappings',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 21,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      floatingActionButton:
          FloatingActionButton.extended(
        onPressed: () {
          _showMappingDialog();
        },
        icon: const Icon(
          Icons.add,
        ),
        label: const Text(
          'Add Mapping',
        ),
      ),
      body: ValueListenableBuilder<
          Box<SmsMapping>>(
        valueListenable:
            _mappingBox.listenable(),
        builder: (
          context,
          box,
          child,
        ) {
          final mappings = _mappings;

          if (mappings.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(
              16,
              16,
              16,
              100,
            ),
            itemCount: mappings.length,
            itemBuilder: (
              context,
              index,
            ) {
              return _buildMappingCard(
                mappings[index],
              );
            },
          );
        },
      ),
    );
  }
}

// =============================================================================
// MAPPING FORM SHEET
//
// Pulled out into its own StatefulWidget (rather than an inline
// StatefulBuilder inside showModalBottomSheet) specifically so that
// `_keywordController` / `_priorityController` are disposed by Flutter's
// normal widget lifecycle — i.e. only once this widget is actually
// unmounted, which happens *after* the bottom sheet's closing animation
// finishes.
//
// The previous implementation disposed the controllers manually right
// after `await showModalBottomSheet(...)` returned. That Future actually
// completes as soon as `Navigator.pop()` is called — not after the
// closing animation finishes — so the controllers were being disposed
// while the sheet (and its still-visible TextFormFields) were still
// mid-animation and still mounted, causing:
//
//   FlutterError: A TextEditingController was used after being disposed.
//
// =============================================================================

class _MappingFormSheet extends StatefulWidget {
  final SmsMapping? mapping;
  final List<Source> sources;
  final List<Category> categories;
  final Future<void> Function(SmsMapping mapping) onSave;

  const _MappingFormSheet({
    required this.mapping,
    required this.sources,
    required this.categories,
    required this.onSave,
  });

  @override
  State<_MappingFormSheet> createState() =>
      _MappingFormSheetState();
}

class _MappingFormSheetState
    extends State<_MappingFormSheet> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _keywordController;
  late final TextEditingController _priorityController;

  late SmsMatchField _matchField;
  late SmsMappingType _mappingType;
  String? _targetId;
  late bool _isActive;

  bool get _isEditing => widget.mapping != null;

  @override
  void initState() {
    super.initState();

    _keywordController = TextEditingController(
      text: widget.mapping?.matchValue ?? '',
    );

    _priorityController = TextEditingController(
      text: (widget.mapping?.priority ?? 0).toString(),
    );

    _matchField =
        widget.mapping?.matchField ??
        SmsMatchField.sender;

    _mappingType =
        widget.mapping?.mappingType ??
        SmsMappingType.source;

    _targetId = widget.mapping?.targetId;

    // If we're editing a mapping whose target no longer exists among
    // the currently selectable targets (e.g. the source was archived),
    // clear it up front so the user is prompted to pick a new one.
    if (_targetId != null) {
      final List<dynamic> initialTargets =
          _mappingType == SmsMappingType.source
              ? widget.sources
              : widget.categories;

      final bool initialTargetExists = initialTargets.any(
        (target) => target.id == _targetId,
      );

      if (!initialTargetExists) {
        _targetId = null;
      }
    }

    _isActive = widget.mapping?.isActive ?? true;
  }

  @override
  void dispose() {
    _keywordController.dispose();
    _priorityController.dispose();
    super.dispose();
  }

  // ===========================================================================
  // SAVE
  // ===========================================================================

  Future<void> _handleSave() async {
    final List<dynamic> targets =
        _mappingType == SmsMappingType.source
            ? widget.sources
            : widget.categories;

    if (targets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _mappingType == SmsMappingType.source
                ? 'Add a source before creating this mapping.'
                : 'Add a category before creating this mapping.',
          ),
        ),
      );

      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_targetId == null) {
      return;
    }

    final int parsedPriority =
        int.tryParse(
          _priorityController.text.trim(),
        ) ??
        0;

    final SmsMapping newMapping = SmsMapping(
      id: _isEditing
          ? widget.mapping!.id
          : DateTime.now()
              .microsecondsSinceEpoch
              .toString(),
      matchValue: _keywordController.text.trim(),
      matchField: _matchField,
      mappingType: _mappingType,
      targetId: _targetId!,
      isActive: _isActive,
      priority: parsedPriority,
    );

    await widget.onSave(newMapping);
  }

  // ===========================================================================
  // MAPPING TYPE SELECTOR
  // ===========================================================================

  Widget _buildMappingTypeSelector({
    required SmsMappingType value,
    required ValueChanged<SmsMappingType> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildSelectorItem<SmsMappingType>(
              value: SmsMappingType.source,
              currentValue: value,
              label: 'Source',
              icon:
                  Icons.account_balance_wallet_outlined,
              onTap: onChanged,
            ),
          ),
          Expanded(
            child: _buildSelectorItem<SmsMappingType>(
              value: SmsMappingType.category,
              currentValue: value,
              label: 'Category',
              icon: Icons.category_outlined,
              onTap: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // MATCH FIELD SELECTOR
  // ===========================================================================

  Widget _buildMatchFieldSelector({
    required SmsMatchField value,
    required ValueChanged<SmsMatchField> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildSelectorItem<SmsMatchField>(
              value: SmsMatchField.sender,
              currentValue: value,
              label: 'Sender',
              icon: Icons.person_outline,
              onTap: onChanged,
            ),
          ),
          Expanded(
            child: _buildSelectorItem<SmsMatchField>(
              value: SmsMatchField.message,
              currentValue: value,
              label: 'Message',
              icon: Icons.sms_outlined,
              onTap: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // GENERIC SELECTOR ITEM
  // ===========================================================================

  Widget _buildSelectorItem<T>({
    required T value,
    required T currentValue,
    required String label,
    required IconData icon,
    required ValueChanged<T> onTap,
  }) {
    final bool selected = value == currentValue;

    return GestureDetector(
      onTap: () => onTap(value),
      child: AnimatedContainer(
        duration: const Duration(
          milliseconds: 180,
        ),
        padding: const EdgeInsets.symmetric(
          vertical: 11,
        ),
        decoration: BoxDecoration(
          color: selected
              ? Colors.white
              : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: 0.06,
                    ),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: selected
                  ? Colors.black87
                  : Colors.grey.shade600,
            ),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected
                    ? FontWeight.w600
                    : FontWeight.w500,
                color: selected
                    ? Colors.black87
                    : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // NO TARGET MESSAGE
  // ===========================================================================

  Widget _buildNoTargetMessage(
    SmsMappingType mappingType,
  ) {
    final bool isSource =
        mappingType == SmsMappingType.source;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(
          alpha: 0.10,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Colors.orange,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isSource
                  ? 'No sources are available.'
                  : 'No categories are available.',
              style: const TextStyle(
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    final List<dynamic> targets =
        _mappingType == SmsMappingType.source
            ? widget.sources
            : widget.categories;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(
          context,
        ).viewInsets.bottom,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight:
              MediaQuery.of(context).size.height *
              0.92,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(24),
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            20,
            12,
            20,
            24,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                // --------------------------------------------------------
                // HANDLE
                // --------------------------------------------------------

                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius:
                          BorderRadius.circular(10),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // --------------------------------------------------------
                // TITLE
                // --------------------------------------------------------

                Text(
                  _isEditing
                      ? 'Edit SMS Mapping'
                      : 'Add SMS Mapping',
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  'Automatically assign a source or category when an SMS matches a value.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: Colors.grey.shade600,
                  ),
                ),

                const SizedBox(height: 22),

                // --------------------------------------------------------
                // MAP TO
                // --------------------------------------------------------

                const Text(
                  'Map To',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 8),

                _buildMappingTypeSelector(
                  value: _mappingType,
                  onChanged: (value) {
                    setState(() {
                      _mappingType = value;
                      _targetId = null;
                    });
                  },
                ),

                const SizedBox(height: 20),

                // --------------------------------------------------------
                // MATCH IN
                // --------------------------------------------------------

                const Text(
                  'Match In',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 8),

                _buildMatchFieldSelector(
                  value: _matchField,
                  onChanged: (value) {
                    setState(() {
                      _matchField = value;
                    });
                  },
                ),

                const SizedBox(height: 20),

                // --------------------------------------------------------
                // KEYWORD
                // --------------------------------------------------------

                const Text(
                  'Keyword / Value',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 8),

                TextFormField(
                  controller: _keywordController,
                  textCapitalization:
                      TextCapitalization.characters,
                  decoration: InputDecoration(
                    hintText:
                        _matchField == SmsMatchField.sender
                            ? 'Example: HDFCBK'
                            : 'Example: SWIGGY',
                    prefixIcon: Icon(
                      _matchField == SmsMatchField.sender
                          ? Icons.person_outline
                          : Icons.sms_outlined,
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Colors.black87,
                        width: 1,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return 'Enter a keyword';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // --------------------------------------------------------
                // TARGET
                // --------------------------------------------------------

                const Text(
                  'Select Target',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 8),

                // The KeyedSubtree here is important: keying this block
                // by `_mappingType` forces Flutter to throw away and
                // rebuild it from scratch whenever the user switches
                // between Source and Category, instead of trying to
                // reuse the previous DropdownButtonFormField's internal
                // state (which is what causes the menu to still show the
                // old list right after switching).
                KeyedSubtree(
                  key: ValueKey(_mappingType),
                  child: targets.isEmpty
                      ? _buildNoTargetMessage(
                          _mappingType,
                        )
                      : DropdownButtonFormField<String>(
                          value: _targetId,
                          isExpanded: true,
                          decoration: InputDecoration(
                            prefixIcon: Icon(
                              _mappingType ==
                                      SmsMappingType.source
                                  ? Icons
                                      .account_balance_wallet_outlined
                                  : Icons.category_outlined,
                            ),
                            filled: true,
                            fillColor:
                                Colors.grey.shade100,
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(
                                12,
                              ),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder:
                                OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(
                                12,
                              ),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder:
                                OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(
                                12,
                              ),
                              borderSide: const BorderSide(
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          hint: Text(
                            _mappingType ==
                                    SmsMappingType.source
                                ? 'Select source'
                                : 'Select category',
                          ),
                          items: targets
                              .map<DropdownMenuItem<String>>(
                            (target) {
                              return DropdownMenuItem<String>(
                                value: target.id,
                                child: Text(
                                  target.name,
                                  overflow:
                                      TextOverflow.ellipsis,
                                ),
                              );
                            },
                          ).toList(),
                          onChanged: (value) {
                            setState(() {
                              _targetId = value;
                            });
                          },
                          validator: (value) {
                            if (value == null) {
                              return _mappingType ==
                                      SmsMappingType.source
                                  ? 'Select a source'
                                  : 'Select a category';
                            }

                            return null;
                          },
                        ),
                ),

                const SizedBox(height: 20),

                // --------------------------------------------------------
                // PRIORITY
                // --------------------------------------------------------

                const Text(
                  'Priority',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 8),

                TextFormField(
                  controller: _priorityController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'Example: 10',
                    helperText:
                        'Higher priority mappings are checked first.',
                    prefixIcon: const Icon(
                      Icons.low_priority_rounded,
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return 'Enter priority';
                    }

                    final int? parsed = int.tryParse(
                      value.trim(),
                    );

                    if (parsed == null) {
                      return 'Enter a valid number';
                    }

                    if (parsed < 0) {
                      return 'Priority cannot be negative';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 8),

                // --------------------------------------------------------
                // ACTIVE
                // --------------------------------------------------------

                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Active',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: const Text(
                    'Use this mapping when processing SMS messages',
                  ),
                  value: _isActive,
                  onChanged: (value) {
                    setState(() {
                      _isActive = value;
                    });
                  },
                ),

                const SizedBox(height: 18),

                // --------------------------------------------------------
                // SAVE
                // --------------------------------------------------------

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: _handleSave,
                    child: Text(
                      _isEditing
                          ? 'Update Mapping'
                          : 'Add Mapping',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}