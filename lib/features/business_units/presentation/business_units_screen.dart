// lib/features/business_units/presentation/business_units_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme.dart';
import '../../auth/application/auth_providers.dart';
import '../../master_data/application/master_data_providers.dart';
import '../application/business_unit_providers.dart';
import '../domain/business_unit.dart';

class BusinessUnitsScreen extends ConsumerWidget {
  const BusinessUnitsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unitsAsync = ref.watch(businessUnitsStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Business Units')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
      body: unitsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.orange),
        ),
        error: (err, _) => const Center(
          child: Text(
            'Failed to load business units.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
        data: (units) {
          if (units.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.store_mall_directory_outlined,
                      size: 40,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'No business units yet.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => _openForm(context, ref),
                      child: const Text('Add the first one'),
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
            itemCount: units.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final unit = units[index];
              return Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.orange.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.store_mall_directory_rounded,
                        color: AppColors.orange,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  unit.name,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              if (unit.code != null && unit.code!.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.textMuted.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    unit.code!,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (unit.address != null && unit.address!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                unit.address!,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: AppColors.textMuted),
                      onSelected: (value) {
                        if (value == 'edit') {
                          _openForm(context, ref, existing: unit);
                        } else if (value == 'delete') {
                          _confirmDelete(context, ref, unit);
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'edit', child: Text('Edit')),
                        PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _openForm(
    BuildContext context,
    WidgetRef ref, {
    BusinessUnit? existing,
  }) {
    return showDialog(
      context: context,
      builder: (_) => _BusinessUnitFormDialog(existing: existing),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    BusinessUnit unit,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete business unit?'),
        content: Text(
          'This will permanently remove "${unit.name}". This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(businessUnitRepositoryProvider).delete(unit.id);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not delete: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

class _BusinessUnitFormDialog extends ConsumerStatefulWidget {
  const _BusinessUnitFormDialog({this.existing});
  final BusinessUnit? existing;

  @override
  ConsumerState<_BusinessUnitFormDialog> createState() =>
      _BusinessUnitFormDialogState();
}

class _TableDraft {
  _TableDraft({required this.id, this.name = ''});
  final String id;
  String name;
}

class _ZoneDraft {
  _ZoneDraft({required this.id, this.name = '', List<_TableDraft>? tables})
      : tables = tables ?? [];
  final String id;
  String name;
  List<_TableDraft> tables;
}

String _newDraftId() => DateTime.now().microsecondsSinceEpoch.toString();

class _BusinessUnitFormDialogState
    extends ConsumerState<_BusinessUnitFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController =
      TextEditingController(text: widget.existing?.name ?? '');
  late final _addressController =
      TextEditingController(text: widget.existing?.address ?? '');
  late final _codeController =
      TextEditingController(text: widget.existing?.code ?? '');
  late String? _defaultCustomerCode = widget.existing?.defaultCustomerCode;
  late String? _defaultLocationCode = widget.existing?.defaultLocationCode;
  late Set<String>? _visibleGroupCodes = widget.existing?.visibleItemGroupCodes?.toSet();
  late String _salesMode = widget.existing?.salesMode ?? 'simple';
  late List<_ZoneDraft> _zones = (widget.existing?.zones ?? const [])
      .map((z) => _ZoneDraft(
            id: z.id,
            name: z.name,
            tables: z.tables.map((t) => _TableDraft(id: t.id, name: t.name)).toList(),
          ))
      .toList();
  bool _saving = false;
  bool _loadingOptions = true;
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _customers = [];
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _locations = [];
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _itemGroups = [];

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  Future<void> _loadOptions() async {
    final companyId = ref.read(currentAppUserProvider).value?.companyId;
    if (companyId == null || companyId.isEmpty) {
      if (mounted) setState(() => _loadingOptions = false);
      return;
    }
    final repo = ref.read(masterDataRepositoryProvider);
    final results = await Future.wait([
      repo.fetchPage(companyId: companyId, collection: 'CUSTOMER', sortField: 'code'),
      repo.fetchPage(companyId: companyId, collection: 'LOCATION', sortField: 'code'),
      repo.fetchPage(companyId: companyId, collection: 'ITEM_GROUP', sortField: 'code'),
    ]);
    if (!mounted) return;
    setState(() {
      _customers = results[0].docs;
      _locations = results[1].docs;
      _itemGroups = results[2].docs;
      _loadingOptions = false;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  List<String>? get _visibleGroupCodesToSave {
    if (_visibleGroupCodes == null) return null;
    if (_itemGroups.isNotEmpty && _visibleGroupCodes!.length == _itemGroups.length) {
      return null; // everything selected == no restriction
    }
    return _visibleGroupCodes!.toList();
  }

  List<Zone> get _zonesToSave => _zones
      .where((z) => z.name.trim().isNotEmpty)
      .map((z) => Zone(
            id: z.id,
            name: z.name.trim(),
            tables: z.tables
                .where((t) => t.name.trim().isNotEmpty)
                .map((t) => ZoneTable(id: t.id, name: t.name.trim()))
                .toList(),
          ))
      .toList();

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final repo = ref.read(businessUnitRepositoryProvider);
      final name = _nameController.text.trim();
      final address =
          _addressController.text.trim().isEmpty ? null : _addressController.text.trim();
      final code =
          _codeController.text.trim().isEmpty ? null : _codeController.text.trim();
      if (widget.existing == null) {
        await repo.create(
          name: name,
          address: address,
          code: code,
          defaultCustomerCode: _defaultCustomerCode,
          defaultLocationCode: _defaultLocationCode,
          visibleItemGroupCodes: _visibleGroupCodesToSave,
          salesMode: _salesMode,
          zones: _zonesToSave,
        );
      } else {
        await repo.update(
          businessUnitId: widget.existing!.id,
          name: name,
          address: address,
          code: code,
          defaultCustomerCode: _defaultCustomerCode,
          defaultLocationCode: _defaultLocationCode,
          visibleItemGroupCodes: _visibleGroupCodesToSave,
          salesMode: _salesMode,
          zones: _zonesToSave,
        );
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Save failed: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return AlertDialog(
      title: Text(isEdit ? 'Edit business unit' : 'Add business unit'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 360,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(labelText: 'Address'),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _codeController,
                  decoration: const InputDecoration(
                    labelText: 'Code',
                    hintText: 'e.g. BAR1 (used by POS)',
                  ),
                ),
                const SizedBox(height: 14),
                if (_loadingOptions)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else ...[
                  DropdownButtonFormField<String>(
                    initialValue: _customers.any((d) => d.id == _defaultCustomerCode)
                        ? _defaultCustomerCode
                        : null,
                    decoration: const InputDecoration(labelText: 'Default customer'),
                    dropdownColor: AppColors.surfaceHigh,
                    items: _customers
                        .map((d) => DropdownMenuItem(
                              value: d.id,
                              child: Text(
                                (d.data()['description'] as String?)?.isNotEmpty == true
                                    ? d.data()['description'] as String
                                    : d.id,
                              ),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _defaultCustomerCode = v),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: _locations.any((d) => d.id == _defaultLocationCode)
                        ? _defaultLocationCode
                        : null,
                    decoration: const InputDecoration(labelText: 'Default location'),
                    dropdownColor: AppColors.surfaceHigh,
                    items: _locations
                        .map((d) => DropdownMenuItem(
                              value: d.id,
                              child: Text(
                                (d.data()['description'] as String?)?.isNotEmpty == true
                                    ? d.data()['description'] as String
                                    : d.id,
                              ),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _defaultLocationCode = v),
                  ),
                  const SizedBox(height: 18),
                  const Divider(),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Visible item groups',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  const Text(
                    'All are shown to operators by default — untick any you want hidden in POS.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  _ItemGroupCheckboxList(
                    groups: _itemGroups,
                    selected: _visibleGroupCodes ?? _itemGroups.map((d) => d.id).toSet(),
                    onChanged: (next) => setState(() => _visibleGroupCodes = next),
                  ),
                  const SizedBox(height: 18),
                  const Divider(),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Sales mode',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'simple', label: Text('Simple')),
                      ButtonSegment(value: 'tables', label: Text('Bar / Restaurant')),
                    ],
                    selected: {_salesMode},
                    onSelectionChanged: (next) => setState(() => _salesMode = next.first),
                  ),
                  if (_salesMode == 'tables') ...[
                    const SizedBox(height: 14),
                    _ZonesEditor(
                      zones: _zones,
                      onChanged: (next) => setState(() => _zones = next),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(isEdit ? 'Save' : 'Add'),
        ),
      ],
    );
  }
}

class _ItemGroupCheckboxList extends StatelessWidget {
  const _ItemGroupCheckboxList({
    required this.groups,
    required this.selected,
    required this.onChanged,
  });

  final List<QueryDocumentSnapshot<Map<String, dynamic>>> groups;
  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    if (groups.isEmpty) {
      return const Text(
        'No item groups synced yet.',
        style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final doc in groups)
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            dense: true,
            activeColor: AppColors.orange,
            title: Text(
              (doc.data()['description'] as String?)?.isNotEmpty == true
                  ? doc.data()['description'] as String
                  : doc.id,
              style: const TextStyle(color: AppColors.textPrimary),
            ),
            value: selected.contains(doc.id),
            onChanged: (checked) {
              final next = Set<String>.from(selected);
              if (checked == true) {
                next.add(doc.id);
              } else {
                next.remove(doc.id);
              }
              onChanged(next);
            },
          ),
      ],
    );
  }
}

class _ZonesEditor extends StatefulWidget {
  const _ZonesEditor({required this.zones, required this.onChanged});
  final List<_ZoneDraft> zones;
  final ValueChanged<List<_ZoneDraft>> onChanged;

  @override
  State<_ZonesEditor> createState() => _ZonesEditorState();
}

class _ZonesEditorState extends State<_ZonesEditor> {
  late List<_ZoneDraft> _zones = widget.zones;

  void _notify() => widget.onChanged(_zones);

  void _addZone() {
    setState(() => _zones = [..._zones, _ZoneDraft(id: _newDraftId())]);
    _notify();
  }

  void _removeZone(_ZoneDraft zone) {
    setState(() => _zones = _zones.where((z) => z.id != zone.id).toList());
    _notify();
  }

  void _addTable(_ZoneDraft zone) {
    setState(() => zone.tables = [...zone.tables, _TableDraft(id: _newDraftId())]);
    _notify();
  }

  void _removeTable(_ZoneDraft zone, _TableDraft table) {
    setState(() => zone.tables = zone.tables.where((t) => t.id != table.id).toList());
    _notify();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final zone in _zones)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surfaceHigh,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        key: ValueKey('zone-name-${zone.id}'),
                        initialValue: zone.name,
                        decoration: const InputDecoration(labelText: 'Zone name', isDense: true),
                        onChanged: (v) {
                          zone.name = v;
                          _notify();
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                      tooltip: 'Remove zone',
                      onPressed: () => _removeZone(zone),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    for (final table in zone.tables)
                      SizedBox(
                        width: 130,
                        child: TextFormField(
                          key: ValueKey('table-name-${table.id}'),
                          initialValue: table.name,
                          decoration: InputDecoration(
                            labelText: 'Table',
                            isDense: true,
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.close, size: 16),
                              onPressed: () => _removeTable(zone, table),
                            ),
                          ),
                          onChanged: (v) {
                            table.name = v;
                            _notify();
                          },
                        ),
                      ),
                    OutlinedButton.icon(
                      onPressed: () => _addTable(zone),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Table'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        OutlinedButton.icon(
          onPressed: _addZone,
          icon: const Icon(Icons.add, size: 16),
          label: const Text('Add zone'),
        ),
      ],
    );
  }
}
