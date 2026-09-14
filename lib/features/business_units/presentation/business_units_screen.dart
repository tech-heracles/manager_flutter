// lib/features/business_units/presentation/business_units_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../application/business_unit_providers.dart';
import '../domain/business_unit.dart';

class BusinessUnitsScreen extends ConsumerWidget {
  const BusinessUnitsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unitsAsync = ref.watch(businessUnitsStreamProvider);
    final compact = MediaQuery.sizeOf(context).width < 600;

    return Scaffold(
      appBar: AppBar(title: const Text('Business Units')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/business-units/new'),
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
                      onPressed: () => context.push('/business-units/new'),
                      child: const Text('Add the first one'),
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.separated(
            padding: EdgeInsets.fromLTRB(
              compact ? 12 : 20,
              12,
              compact ? 12 : 20,
              96,
            ),
            itemCount: units.length,
            separatorBuilder: (_, _) => SizedBox(height: compact ? 6 : 10),
            itemBuilder: (context, index) {
              final unit = units[index];
              return _BusinessUnitCard(
                unit: unit,
                compact: compact,
                onTap: () => context.push('/business-units/${unit.id}'),
                onDelete: () => _confirmDelete(context, ref, unit),
              );
            },
          );
        },
      ),
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

class _BusinessUnitCard extends StatelessWidget {
  const _BusinessUnitCard({
    required this.unit,
    required this.compact,
    required this.onTap,
    required this.onDelete,
  });

  final BusinessUnit unit;
  final bool compact;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final iconSize = compact ? 32.0 : 40.0;
    final isTablesMode = unit.salesMode == 'tables';

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(compact ? 12 : 14),
      child: InkWell(
        borderRadius: BorderRadius.circular(compact ? 12 : 14),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(compact ? 12 : 14),
            border: Border.all(color: AppColors.border),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 10 : 16,
            vertical: compact ? 6 : 4,
          ),
          child: Row(
            children: [
              Container(
                width: iconSize,
                height: iconSize,
                decoration: BoxDecoration(
                  color: AppColors.orange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isTablesMode
                      ? Icons.table_bar_rounded
                      : Icons.store_mall_directory_rounded,
                  color: AppColors.orange,
                  size: compact ? 16 : 20,
                ),
              ),
              SizedBox(width: compact ? 10 : 14),
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
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: compact ? 13.5 : 14,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (unit.code != null && unit.code!.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          _Tag(label: unit.code!),
                        ],
                      ],
                    ),
                    if (!compact && unit.address != null && unit.address!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          unit.address!,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    if (isTablesMode)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          'Bar / Restaurant · ${unit.zones.length} zone${unit.zones.length == 1 ? '' : 's'}',
                          style: const TextStyle(fontSize: 11, color: AppColors.orange),
                        ),
                      ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: AppColors.textMuted, size: compact ? 18 : 20),
                onSelected: (value) {
                  if (value == 'edit') {
                    onTap();
                  } else if (value == 'delete') {
                    onDelete();
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.textMuted.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.textMuted,
        ),
      ),
    );
  }
}
