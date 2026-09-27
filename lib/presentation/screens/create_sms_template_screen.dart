import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import 'package:wallet/core/boxes.dart';
import 'package:wallet/core/category_icons.dart';
import 'package:wallet/core/source_icons.dart';
import 'package:wallet/data/models/category.dart';
import 'package:wallet/data/models/sms_pattern_builder.dart';
import 'package:wallet/data/models/sms_preview_item.dart';
import 'package:wallet/data/models/sms_template.dart';
import 'package:wallet/data/models/source.dart';
import 'package:wallet/data/models/transaction_type.dart';
import 'package:wallet/data/repository/sms_template_repository.dart';

/// The 7 fields shown in order, in the mapping list.
const List<SmsFieldKey> _orderedFields = [
  SmsFieldKey.amount,
  SmsFieldKey.date,
  SmsFieldKey.type,
  SmsFieldKey.category,
  SmsFieldKey.source,
  SmsFieldKey.destinationSource,
  SmsFieldKey.note,
];

/// Create-a-template page: shows the source SMS at the top
/// (select-to-map), and every field the manual input screen asks for
/// below it, each resolvable as "map from message" / "ask later" /
/// "default value".
///
/// Pass [onSave] to persist the built [SmsTemplate] yourself; if you
/// leave it null the screen just pops with the template as the
/// navigation result.
class CreateSmsTemplateScreen extends StatefulWidget {
  final SmsPreviewItem message;
  final void Function(SmsTemplate template)? onSave;

  const CreateSmsTemplateScreen({
    super.key,
    required this.message,
    this.onSave,
  });

  @override
  State<CreateSmsTemplateScreen> createState() =>
      _CreateSmsTemplateScreenState();
}

class _CreateSmsTemplateScreenState extends State<CreateSmsTemplateScreen> {
  static const double _messageBoxHeight = 190;

  final _nameController = TextEditingController();
  final _senderController = TextEditingController();
  final _templateRepository = SmsTemplateRepository();

  TextSelection? _currentSelection;
  final Map<SmsFieldKey, SmsFieldMapping> _mappings = {};

  @override
  void initState() {
    super.initState();

    _nameController.text = widget.message.sender;
    _senderController.text = SmsPatternBuilder.defaultSenderPattern(
      widget.message.sender,
    );

    for (final key in _orderedFields) {
      _mappings[key] = SmsFieldMapping(
        fieldKey: key,
        mode: key == SmsFieldKey.destinationSource
            ? SmsFieldMappingMode.ask
            : SmsFieldMappingMode.ask,
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _senderController.dispose();
    super.dispose();
  }

  bool get _hasActiveSelection =>
      _currentSelection != null && !_currentSelection!.isCollapsed;

  String get _selectedText {
    if (!_hasActiveSelection) return '';
    final sel = _currentSelection!;
    return widget.message.body.substring(sel.start, sel.end);
  }

  void _onSelectionChanged(TextSelection selection, SelectionChangedCause? cause) {
    setState(() => _currentSelection = selection);
  }

  void _applySelectionToField(SmsFieldKey key) {
    if (!_hasActiveSelection) {
      _showSnack('Select some text in the message above first');
      return;
    }

    final sel = _currentSelection!;
    final mapping = SmsFieldMapping.fromSelection(
      fieldKey: key,
      fullText: widget.message.body,
      selectionStart: sel.start,
      selectionEnd: sel.end,
    );

    setState(() {
      _mappings[key] = mapping;
      _currentSelection = null;
    });
  }

  void _clearMapping(SmsFieldKey key) {
    setState(() {
      _mappings[key] = SmsFieldMapping(
        fieldKey: key,
        mode: SmsFieldMappingMode.ask,
      );
    });
  }

  void _setMode(SmsFieldKey key, SmsFieldMappingMode mode) {
    setState(() {
      final existing = _mappings[key]!;
      if (mode == SmsFieldMappingMode.mapped && existing.pattern == null) {
        // Nothing captured yet - stay in "ask" until they actually
        // select some text, so the UI doesn't show a fake "mapped"
        // state with no data behind it.
        _showSnack('Select text above, then tap "Use Selected Text"');
        return;
      }
      _mappings[key] = existing.copyWith(mode: mode);
    });
  }

  void _setDefaultValue(SmsFieldKey key, String? value) {
    setState(() {
      _mappings[key] = _mappings[key]!.copyWith(
        mode: SmsFieldMappingMode.defaultValue,
        defaultValue: value,
      );
    });
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final senderPattern = _senderController.text.trim();

    if (name.isEmpty) {
      _showSnack('Give this template a name');
      return;
    }
    if (senderPattern.isEmpty) {
      _showSnack('Sender pattern cannot be empty');
      return;
    }

    final template = SmsTemplate(
      id: const Uuid().v4(),
      name: name,
      senderPattern: senderPattern,
      sampleMessage: widget.message.body,
      createdAt: DateTime.now(),
      fieldMappings: _orderedFields.map((k) => _mappings[k]!).toList(),
    );

    if (widget.onSave != null) {
      widget.onSave!(template);
      return;
    }

    await _templateRepository.save(template);

    if (!mounted) return;
    _showSnack('Template saved');
    Navigator.pop(context, template);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create SMS Template'),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _save,
        icon: const Icon(Icons.check),
        label: const Text('Save Template'),
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
          children: [
            _buildNameAndSenderFields(),
            const SizedBox(height: 16),
            _buildMessageBox(),
            const SizedBox(height: 8),
            _buildSelectionBanner(),
            const SizedBox(height: 20),
            const Text(
              'Fields',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 4),
            const Text(
              'For each field, map it from the message above, ask at '
              'approval time, or set a fixed default.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 12),
            ..._orderedFields.map(_buildFieldCard),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------
  // Top: name / sender pattern
  // ---------------------------------------------------------------

  Widget _buildNameAndSenderFields() {
    return Column(
      children: [
        TextField(
          controller: _nameController,
          decoration: _fieldDecoration('Template Name'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _senderController,
          decoration: _fieldDecoration(
            'Sender Pattern',
            helper:
                'Matched if the SMS sender contains this text. '
                'Operator prefixes like "AX-" / "AD-" are ignored '
                'automatically.',
          ),
        ),
      ],
    );
  }

  InputDecoration _fieldDecoration(String label, {String? helper}) {
    return InputDecoration(
      labelText: label,
      helperText: helper,
      helperMaxLines: 3,
      filled: true,
      fillColor: Colors.grey.shade200.withValues(alpha: 0.5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.blueGrey.shade100),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.blueGrey.shade300, width: 2),
      ),
    );
  }

  // ---------------------------------------------------------------
  // Message box (fixed height, selectable)
  // ---------------------------------------------------------------

  Widget _buildMessageBox() {
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    return Container(
      height: _messageBoxHeight,
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.message.sender,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                dateFormat.format(widget.message.date),
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
            ],
          ),
          const Divider(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: SelectableText(
                widget.message.body,
                style: const TextStyle(fontSize: 14.5, height: 1.45),
                selectionControls: materialTextSelectionControls,
                onSelectionChanged: _onSelectionChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionBanner() {
    if (!_hasActiveSelection) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Text(
          'Long-press a word in the message to select it, then drag the '
          'handles to adjust - then tap "Use Selected Text" on a field '
          'below.',
          style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        children: [
          Icon(Icons.text_fields, size: 18, color: Colors.blue.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Selected: "$_selectedText"',
              style: TextStyle(
                color: Colors.blue.shade900,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          TextButton(
            onPressed: () => setState(() => _currentSelection = null),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------
  // Field cards
  // ---------------------------------------------------------------

  Widget _buildFieldCard(SmsFieldKey key) {
    final mapping = _mappings[key]!;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // LEFT: mapped-section preview.
              Expanded(
                flex: 4,
                child: _buildPreviewBox(mapping),
              ),
              const SizedBox(width: 12),
              // RIGHT: label + mode selector.
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(_iconFor(key), size: 18, color: Colors.grey.shade700),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            key.label,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _modeChip(key, SmsFieldMappingMode.mapped, 'Map'),
                        _modeChip(key, SmsFieldMappingMode.ask, 'Ask'),
                        _modeChip(key, SmsFieldMappingMode.defaultValue, 'Default'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (mapping.mode == SmsFieldMappingMode.mapped || _hasActiveSelection)  ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _applySelectionToField(key),
                icon: const Icon(Icons.text_fields, size: 16),
                label: Text(
                  mapping.sampleValue == null
                      ? 'Use Selected Text'
                      : 'Re-map From Selection',
                ),
              ),
            ),
          ],

          if (mapping.mode == SmsFieldMappingMode.defaultValue) ...[
            const SizedBox(height: 10),
            _buildDefaultValueInput(key, mapping),
          ],
        ],
      ),
    );
  }

  Widget _buildPreviewBox(SmsFieldMapping mapping) {
    late final String text;
    late final Color background;
    late final Color foreground;

    switch (mapping.mode) {
      case SmsFieldMappingMode.mapped:
        text = mapping.sampleValue == null
            ? 'Not mapped yet'
            : '"${mapping.sampleValue}"';
        background = mapping.sampleValue == null
            ? Colors.grey.shade100
            : Colors.blue.shade50;
        foreground = mapping.sampleValue == null
            ? Colors.grey.shade500
            : Colors.blue.shade800;
        break;
      case SmsFieldMappingMode.ask:
        text = 'Ask when approving';
        background = Colors.grey.shade100;
        foreground = Colors.grey.shade600;
        break;
      case SmsFieldMappingMode.defaultValue:
        text = _defaultValueDisplay(mapping);
        background = Colors.orange.shade50;
        foreground = Colors.orange.shade800;
        break;
    }

    return Container(
      height: 56,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: foreground,
          fontStyle: FontStyle.italic,
          fontSize: 13,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  String _defaultValueDisplay(SmsFieldMapping mapping) {
    if (mapping.defaultValue == null || mapping.defaultValue!.isEmpty) {
      return 'Set a default below';
    }

    switch (mapping.fieldKey) {
      case SmsFieldKey.category:
        return Boxes.getCategories().get(mapping.defaultValue)?.name ??
            'Unknown category';
      case SmsFieldKey.source:
      case SmsFieldKey.destinationSource:
        return Boxes.getSources().get(mapping.defaultValue)?.name ??
            'Unknown source';
      case SmsFieldKey.type:
        return mapping.defaultValue!;
      default:
        return mapping.defaultValue!;
    }
  }

  Widget _modeChip(SmsFieldKey key, SmsFieldMappingMode mode, String label) {
    final mapping = _mappings[key]!;
    final selected = mapping.mode == mode;

    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: selected,
      onSelected: (_) => _setMode(key, mode),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildDefaultValueInput(SmsFieldKey key, SmsFieldMapping mapping) {
    switch (key) {
      case SmsFieldKey.category:
        return _buildCategoryDropdown(key, mapping);
      case SmsFieldKey.source:
      case SmsFieldKey.destinationSource:
        return _buildSourceDropdown(key, mapping);
      case SmsFieldKey.type:
        return _buildTypeSegmented(key, mapping);
      case SmsFieldKey.date:
        return _buildDatePickerButton(key, mapping);
      case SmsFieldKey.amount:
      case SmsFieldKey.note:
        return _buildTextDefaultInput(key, mapping);
    }
  }

  Widget _buildTextDefaultInput(SmsFieldKey key, SmsFieldMapping mapping) {
    return TextFormField(
      initialValue: mapping.defaultValue ?? '',
      keyboardType: key == SmsFieldKey.amount
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      decoration: InputDecoration(
        isDense: true,
        hintText: key == SmsFieldKey.amount ? 'e.g. 649.00' : 'Default note',
        filled: true,
        fillColor: Colors.grey.shade100,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
      onChanged: (value) => _setDefaultValue(key, value),
    );
  }

  Widget _buildCategoryDropdown(SmsFieldKey key, SmsFieldMapping mapping) {
    final categories = Boxes.getCategories().values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    final validValue = categories.any((c) => c.id == mapping.defaultValue)
        ? mapping.defaultValue
        : null;

    return DropdownButtonFormField<String>(
      value: validValue,
      isExpanded: true,
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: Colors.grey.shade100,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
      items: categories
          .map(
            (Category c) => DropdownMenuItem(
              value: c.id,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(CategoryIcons.icons[c.iconIndex], size: 16),
                  const SizedBox(width: 8),
                  Flexible(child: Text(c.name, overflow: TextOverflow.ellipsis)),
                ],
              ),
            ),
          )
          .toList(),
      onChanged: (value) => _setDefaultValue(key, value),
    );
  }

  Widget _buildSourceDropdown(SmsFieldKey key, SmsFieldMapping mapping) {
    final sources = Boxes.getSources().values.toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    final validValue = sources.any((s) => s.id == mapping.defaultValue)
        ? mapping.defaultValue
        : null;

    return DropdownButtonFormField<String>(
      value: validValue,
      isExpanded: true,
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: Colors.grey.shade100,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
      items: sources
          .map(
            (Source s) => DropdownMenuItem(
              value: s.id,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(SourceIcons.icons[s.iconIndex], size: 16),
                  const SizedBox(width: 8),
                  Flexible(child: Text(s.name, overflow: TextOverflow.ellipsis)),
                ],
              ),
            ),
          )
          .toList(),
      onChanged: (value) => _setDefaultValue(key, value),
    );
  }

  Widget _buildTypeSegmented(SmsFieldKey key, SmsFieldMapping mapping) {
    final current = TransactionType.values
        .cast<TransactionType?>()
        .firstWhere((t) => t?.name == mapping.defaultValue, orElse: () => null);

    return SegmentedButton<TransactionType>(
      segments: const [
        ButtonSegment(value: TransactionType.income, label: Text('Income')),
        ButtonSegment(value: TransactionType.expense, label: Text('Expense')),
        ButtonSegment(value: TransactionType.transfer, label: Text('Transfer')),
      ],
      selected: current == null ? {} : {current},
      emptySelectionAllowed: true,
      onSelectionChanged: (selection) {
        if (selection.isEmpty) return;
        _setDefaultValue(key, selection.first.name);
      },
    );
  }

  Widget _buildDatePickerButton(SmsFieldKey key, SmsFieldMapping mapping) {
    final selectedDate = mapping.defaultValue != null
        ? DateTime.tryParse(mapping.defaultValue!)
        : null;

    return OutlinedButton.icon(
      icon: const Icon(Icons.calendar_today_outlined, size: 16),
      label: Text(
        selectedDate == null
            ? 'Pick a fixed default date'
            : DateFormat('dd MMM yyyy').format(selectedDate),
      ),
      onPressed: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: selectedDate ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
        );
        if (picked != null) {
          _setDefaultValue(key, picked.toIso8601String());
        }
      },
    );
  }

  IconData _iconFor(SmsFieldKey key) {
    switch (key) {
      case SmsFieldKey.amount:
        return Icons.currency_rupee;
      case SmsFieldKey.date:
        return Icons.calendar_today_outlined;
      case SmsFieldKey.category:
        return Icons.category_outlined;
      case SmsFieldKey.source:
        return Icons.account_balance_wallet_outlined;
      case SmsFieldKey.destinationSource:
        return Icons.compare_arrows;
      case SmsFieldKey.type:
        return Icons.swap_vert;
      case SmsFieldKey.note:
        return Icons.notes;
    }
  }
}