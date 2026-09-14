// lib/features/business_units/presentation/business_unit_edit_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme.dart';
import '../../auth/application/auth_providers.dart';
import '../../master_data/application/master_data_providers.dart';
import '../application/business_unit_providers.dart';
import '../domain/business_unit.dart';

/// Full page (not a dialog) — the business unit form outgrew a modal once
/// item-group visibility and the zones/tables editor were added, and more
/// sales modes (distribution, ...) are coming later that will need even
/// more room.
class BusinessUnitEditScreen extends ConsumerWidget {
  const BusinessUnitEditScreen({super.key, this.businessUnitId});

  /// null means "create new".
  final String? businessUnitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (businessUnitId == null) {
      return const _BusinessUnitForm(existing: null);
    }

    final unitsAsync = ref.watch(businessUnitsStreamProvider);
    return unitsAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.orange)),
      ),
      error: (err, _) => Scaffold(
        appBar: AppBar(title: const Text('Business unit')),
        body: const Center(
          child: Text('Failed to load.', style: TextStyle(color: AppColors.textSecondary)),
        ),
      ),
      data: (units) {
        final matches = units.where((u) => u.id == businessUnitId);
        if (matches.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('Business unit')),
            body: const Center(
              child: Text(
                'This business unit no longer exists.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          );
        }
        return _BusinessUnitForm(existing: matches.first);
      },
    );
  }
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

class _BusinessUnitForm extends ConsumerStatefulWidget {
  const _BusinessUnitForm({required this.existing});
  final BusinessUnit? existing;

  @override
  ConsumerState<_BusinessUnitForm> createState() => _BusinessUnitFormState();
}

class _BusinessUnitFormState extends ConsumerState<_BusinessUnitForm> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(text: widget.existing?.name ?? '');
  late final _addressController = TextEditingController(text: widget.existing?.address ?? '');
  late final _codeController = TextEditingController(text: widget.existing?.code ?? '');
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
      final code = _codeController.text.trim().isEmpty ? null : _codeController.text.trim();
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
    final wide = MediaQuery.sizeOf(context).width >= 900;

    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit business unit' : 'Add business unit')),
      body: _loadingOptions
          ? const Center(child: CircularProgressIndicator(color: AppColors.orange))
          : Form(
              key: _formKey,
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: wide ? 720 : double.infinity),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _SectionCard(
                          title: 'Basics',
                          child: Column(
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
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _SectionCard(
                          title: 'Defaults',
                          child: Column(
                            children: [
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
                                            (d.data()['description'] as String?)
                                                        ?.isNotEmpty ==
                                                    true
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
                                            (d.data()['description'] as String?)
                                                        ?.isNotEmpty ==
                                                    true
                                                ? d.data()['description'] as String
                                                : d.id,
                                          ),
                                        ))
                                    .toList(),
                                onChanged: (v) => setState(() => _defaultLocationCode = v),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _SectionCard(
                          title: 'Visible item groups',
                          subtitle:
                              'All are shown to operators by default — untick any you want hidden in POS.',
                          child: _ItemGroupCheckboxList(
                            groups: _itemGroups,
                            selected: _visibleGroupCodes ?? _itemGroups.map((d) => d.id).toSet(),
                            onChanged: (next) => setState(() => _visibleGroupCodes = next),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _SectionCard(
                          title: 'Sales mode',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SegmentedButton<String>(
                                segments: const [
                                  ButtonSegment(value: 'simple', label: Text('Simple')),
                                  ButtonSegment(
                                      value: 'tables', label: Text('Bar / Restaurant')),
                                ],
                                selected: {_salesMode},
                                onSelectionChanged: (next) =>
                                    setState(() => _salesMode = next.first),
                              ),
                              if (_salesMode == 'tables') ...[
                                const SizedBox(height: 16),
                                _ZonesEditor(
                                  zones: _zones,
                                  onChanged: (next) => setState(() => _zones = next),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _saving ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(isEdit ? 'Save' : 'Add'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child, this.subtitle});
  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
          const SizedBox(height: 12),
          child,
        ],
      ),
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
    return Wrap(
      spacing: 4,
      runSpacing: 0,
      children: [
        for (final doc in groups)
          SizedBox(
            width: 240,
            child: CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              dense: true,
              activeColor: AppColors.orange,
              title: Text(
                (doc.data()['description'] as String?)?.isNotEmpty == true
                    ? doc.data()['description'] as String
                    : doc.id,
                overflow: TextOverflow.ellipsis,
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
