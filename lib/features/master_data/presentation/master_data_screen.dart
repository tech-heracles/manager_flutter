// lib/features/master_data/presentation/master_data_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme.dart';
import '../../auth/application/auth_providers.dart';
import '../application/master_data_providers.dart';

typedef _RowBuilder = Widget Function(Map<String, dynamic> data);

class _EntityConfig {
  const _EntityConfig({
    required this.collection,
    required this.sortField,
    required this.label,
    required this.icon,
    required this.searchHint,
    required this.rowBuilder,
  });

  final String collection;
  final String sortField;
  final String label;
  final IconData icon;
  final String searchHint;
  final _RowBuilder rowBuilder;
}

String _text(Map<String, dynamic> d, String field, [String fallback = '']) {
  final v = d[field];
  if (v == null) return fallback;
  final s = v.toString().trim();
  return s.isEmpty ? fallback : s;
}

String _formatMoney(dynamic value) {
  final n = value is num ? value : num.tryParse(value?.toString() ?? '');
  return n == null ? '' : n.toStringAsFixed(2);
}

bool _isActive(dynamic value) => value == true || value == 1;

final _entityConfigs = <_EntityConfig>[
  _EntityConfig(
    collection: 'ITEM',
    sortField: 'Code',
    label: 'Items',
    icon: Icons.inventory_2_outlined,
    searchHint: 'Search by code…',
    rowBuilder: (d) => _MasterDataRow(
      title: _text(d, 'Description', _text(d, 'Code')),
      subtitle: _text(d, 'Code'),
      trailing: _formatMoney(d['BasePrice']),
      badges: [
        _Pill(
          label: _isActive(d['Active']) ? 'Active' : 'Inactive',
          color: _isActive(d['Active']) ? AppColors.success : AppColors.error,
        ),
        if (_text(d, 'CategoryCode').isNotEmpty)
          _Pill(label: _text(d, 'CategoryCode'), color: AppColors.textMuted),
      ],
    ),
  ),
  _EntityConfig(
    collection: 'ITEM_CATEGORY',
    sortField: 'code',
    label: 'Categories',
    icon: Icons.category_outlined,
    searchHint: 'Search by code…',
    rowBuilder: (d) => _MasterDataRow(
      title: _text(d, 'description', _text(d, 'code')),
      subtitle: _text(d, 'code'),
      badges: [
        for (final g in (d['groupCodes'] as List<dynamic>? ?? const []))
          _Pill(label: g.toString(), color: AppColors.textMuted),
      ],
    ),
  ),
  _EntityConfig(
    collection: 'ITEM_GROUP',
    sortField: 'code',
    label: 'Groups',
    icon: Icons.workspaces_outlined,
    searchHint: 'Search by code…',
    rowBuilder: (d) => _MasterDataRow(
      title: _text(d, 'description', _text(d, 'code')),
      subtitle: _text(d, 'code'),
    ),
  ),
  _EntityConfig(
    collection: 'CUSTOMER',
    sortField: 'code',
    label: 'Customers',
    icon: Icons.people_outline,
    searchHint: 'Search by code…',
    rowBuilder: (d) => _MasterDataRow(
      title: _text(d, 'description', _text(d, 'code')),
      subtitle: _text(d, 'code'),
      trailing: _text(d, 'nipt'),
      badges: [
        if (_text(d, 'priceLevel').isNotEmpty)
          _Pill(label: 'Price ${_text(d, 'priceLevel')}', color: AppColors.textMuted),
      ],
    ),
  ),
  _EntityConfig(
    collection: 'LOCATION',
    sortField: 'code',
    label: 'Locations',
    icon: Icons.place_outlined,
    searchHint: 'Search by code…',
    rowBuilder: (d) => _MasterDataRow(
      title: _text(d, 'description', _text(d, 'code')),
      subtitle: _text(d, 'code'),
    ),
  ),
];

class MasterDataScreen extends StatelessWidget {
  const MasterDataScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _entityConfigs.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Master Data'),
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              for (final c in _entityConfigs)
                Tab(icon: Icon(c.icon, size: 18), text: c.label),
            ],
          ),
        ),
        body: TabBarView(
          children: [for (final c in _entityConfigs) _EntityTab(config: c)],
        ),
      ),
    );
  }
}

class _EntityTab extends ConsumerStatefulWidget {
  const _EntityTab({required this.config});
  final _EntityConfig config;

  @override
  ConsumerState<_EntityTab> createState() => _EntityTabState();
}

class _EntityTabState extends ConsumerState<_EntityTab>
    with AutomaticKeepAliveClientMixin {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  final _docs = <QueryDocumentSnapshot<Map<String, dynamic>>>[];

  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  String _search = '';
  Object? _error;
  DateTime? _lastSynced;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadFirst();
    _loadLastSynced();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_hasMore &&
        !_loadingMore &&
        !_loading &&
        _scrollController.hasClients &&
        _scrollController.position.pixels >
            _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  String? get _companyId => ref.read(currentAppUserProvider).value?.companyId;

  Future<void> _loadLastSynced() async {
    final companyId = _companyId;
    if (companyId == null || companyId.isEmpty) return;
    final ts = await ref
        .read(masterDataRepositoryProvider)
        .lastSyncedAt(companyId, widget.config.collection);
    if (mounted) setState(() => _lastSynced = ts);
  }

  Future<void> _loadFirst() => _fetch(reset: true);

  Future<void> _loadMore() => _fetch(reset: false);

  Future<void> _fetch({required bool reset}) async {
    final companyId = _companyId;
    if (companyId == null || companyId.isEmpty) {
      setState(() => _loading = false);
      return;
    }

    setState(() {
      if (reset) {
        _loading = true;
        _docs.clear();
        _hasMore = true;
        _error = null;
      } else {
        _loadingMore = true;
      }
    });

    try {
      final page = await ref.read(masterDataRepositoryProvider).fetchPage(
            companyId: companyId,
            collection: widget.config.collection,
            sortField: widget.config.sortField,
            searchPrefix: _search.isEmpty ? null : _search,
            startAfter: reset ? null : (_docs.isEmpty ? null : _docs.last),
          );
      if (!mounted) return;
      setState(() {
        _docs.addAll(page.docs);
        _hasMore = page.hasMore;
        _loading = false;
        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
        _loadingMore = false;
      });
    }
  }

  void _onSearchChanged(String value) {
    final normalized = value.trim().toUpperCase();
    if (normalized == _search) return;
    _search = normalized;
    _loadFirst();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search, size: 20),
                    hintText: widget.config.searchHint,
                    isDense: true,
                  ),
                  onChanged: _onSearchChanged,
                ),
              ),
              if (_lastSynced != null) ...[
                const SizedBox(width: 12),
                Text(
                  'Synced ${_formatRelative(_lastSynced!)}',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ],
          ),
        ),
        Expanded(child: _buildBody()),
      ],
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.orange),
      );
    }
    if (_error != null) {
      return Center(
        child: Text(
          'Failed to load ${widget.config.label.toLowerCase()}.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      );
    }
    if (_docs.isEmpty) {
      return Center(
        child: Text(
          'No ${widget.config.label.toLowerCase()} synced yet.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      );
    }
    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      itemCount: _docs.length + (_hasMore ? 1 : 0),
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        if (index >= _docs.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.orange,
                ),
              ),
            ),
          );
        }
        return widget.config.rowBuilder(_docs[index].data());
      },
    );
  }
}

String _formatRelative(DateTime dateTime) {
  final diff = DateTime.now().difference(dateTime);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  return '${diff.inDays}d ago';
}

class _MasterDataRow extends StatelessWidget {
  const _MasterDataRow({
    required this.title,
    required this.subtitle,
    this.trailing,
    this.badges = const [],
  });

  final String title;
  final String subtitle;
  final String? trailing;
  final List<Widget> badges;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (subtitle.isNotEmpty && subtitle != title)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                if (badges.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Wrap(spacing: 6, runSpacing: 6, children: badges),
                  ),
              ],
            ),
          ),
          if (trailing != null && trailing!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Text(
                trailing!,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, this.color = AppColors.textMuted});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
