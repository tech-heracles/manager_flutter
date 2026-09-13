// lib/features/users/presentation/users_screen.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme.dart';
import '../../auth/application/auth_providers.dart';
import '../../auth/domain/user_role.dart';
import '../../business_units/application/business_unit_providers.dart';
import '../../business_units/domain/business_unit.dart';
import '../application/user_providers.dart';
import '../domain/managed_user.dart';

const _roleLabels = {
  UserRole.admin: 'Admin',
  UserRole.supervisor: 'Supervisor',
  UserRole.operator: 'Operator',
};

class UsersScreen extends ConsumerWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(managedUsersStreamProvider);
    final unitsAsync = ref.watch(businessUnitsStreamProvider);
    final currentUid = ref.watch(currentAppUserProvider).value?.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('Users')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openInvite(context, ref),
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Invite'),
      ),
      body: usersAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.orange),
        ),
        error: (err, _) => const Center(
          child: Text(
            'Failed to load users.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
        data: (users) {
          final units = unitsAsync.value ?? const <BusinessUnit>[];
          final unitNames = {for (final u in units) u.id: u.name};

          if (users.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.groups_outlined,
                        size: 40, color: AppColors.textMuted),
                    const SizedBox(height: 12),
                    const Text(
                      'No team members yet.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => _openInvite(context, ref),
                      child: const Text('Invite the first one'),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
            itemCount: users.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final user = users[index];
              final isSelf = user.uid == currentUid;
              return _UserTile(
                user: user,
                unitNames: unitNames,
                isSelf: isSelf,
                onEdit: () => _openEdit(context, ref, user),
                onToggleActive: () => _confirmToggleActive(context, ref, user),
                onResetPin: () => _openResetPin(context, user),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _openInvite(BuildContext context, WidgetRef ref) {
    return showDialog(
      context: context,
      builder: (_) => const _InviteUserDialog(),
    );
  }

  Future<void> _openEdit(BuildContext context, WidgetRef ref, ManagedUser user) {
    return showDialog(
      context: context,
      builder: (_) => _EditUserDialog(user: user),
    );
  }

  Future<void> _openResetPin(BuildContext context, ManagedUser user) {
    return showDialog(
      context: context,
      builder: (_) => _ResetPinDialog(user: user),
    );
  }

  Future<void> _confirmToggleActive(
    BuildContext context,
    WidgetRef ref,
    ManagedUser user,
  ) async {
    final activating = !user.active;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(activating ? 'Activate user?' : 'Deactivate user?'),
        content: Text(
          activating
              ? '${user.displayName} will regain access to the manager app.'
              : '${user.displayName} will lose access immediately. Their data is kept and this can be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: activating
                ? null
                : FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(activating ? 'Activate' : 'Deactivate'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(userRepositoryProvider).setActive(user.uid, activating);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not update: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

class _UserTile extends StatelessWidget {
  const _UserTile({
    required this.user,
    required this.unitNames,
    required this.isSelf,
    required this.onEdit,
    required this.onToggleActive,
    required this.onResetPin,
  });

  final ManagedUser user;
  final Map<String, String> unitNames;
  final bool isSelf;
  final VoidCallback onEdit;
  final VoidCallback onToggleActive;
  final VoidCallback onResetPin;

  @override
  Widget build(BuildContext context) {
    final assignedUnits =
        user.businessUnitIds.map((id) => unitNames[id] ?? id).toList();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.orange.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(
              user.displayName.isNotEmpty
                  ? user.displayName[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                color: AppColors.orange,
                fontWeight: FontWeight.w700,
              ),
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
                        user.displayName,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (isSelf) ...[
                      const SizedBox(width: 6),
                      const _Pill(label: 'You', color: AppColors.textMuted),
                    ],
                  ],
                ),
                if (user.email != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      user.email!,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _Pill(
                      label: _roleLabels[user.role] ?? user.role.name,
                      color: AppColors.orange,
                    ),
                    _Pill(
                      label: user.active ? 'Active' : 'Inactive',
                      color: user.active ? AppColors.success : AppColors.error,
                    ),
                    for (final name in assignedUnits)
                      _Pill(label: name, color: AppColors.textMuted),
                  ],
                ),
              ],
            ),
          ),
          if (!isSelf)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: AppColors.textMuted),
              onSelected: (value) {
                if (value == 'edit') {
                  onEdit();
                } else if (value == 'toggle') {
                  onToggleActive();
                } else if (value == 'resetPin') {
                  onResetPin();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit role & units')),
                if (user.role == UserRole.operator)
                  const PopupMenuItem(value: 'resetPin', child: Text('Reset PIN')),
                PopupMenuItem(
                  value: 'toggle',
                  child: Text(user.active ? 'Deactivate' : 'Activate'),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color});
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

class _BusinessUnitCheckboxList extends ConsumerWidget {
  const _BusinessUnitCheckboxList({
    required this.selected,
    required this.onChanged,
  });

  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unitsAsync = ref.watch(businessUnitsStreamProvider);
    final units = unitsAsync.value ?? const <BusinessUnit>[];

    if (units.isEmpty) {
      return const Text(
        'No business units yet.',
        style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final unit in units)
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: AppColors.orange,
            title: Text(unit.name, style: const TextStyle(color: AppColors.textPrimary)),
            value: selected.contains(unit.id),
            onChanged: (checked) {
              final next = Set<String>.from(selected);
              if (checked == true) {
                next.add(unit.id);
              } else {
                next.remove(unit.id);
              }
              onChanged(next);
            },
          ),
      ],
    );
  }
}

class _InviteUserDialog extends ConsumerStatefulWidget {
  const _InviteUserDialog();

  @override
  ConsumerState<_InviteUserDialog> createState() => _InviteUserDialogState();
}

class _InviteUserDialogState extends ConsumerState<_InviteUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _pinController = TextEditingController();
  UserRole _role = UserRole.operator;
  Set<String> _selectedUnits = {};
  bool _saving = false;

  bool get _isOperator => _role == UserRole.operator;

  @override
  void initState() {
    super.initState();
    _pinController.text = _generatePin();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _invite() async {
    if (!_formKey.currentState!.validate()) return;
    final appUser = ref.read(currentAppUserProvider).value;
    if (appUser == null) return;

    setState(() => _saving = true);
    try {
      final result = await ref.read(userRepositoryProvider).invite(
            companyId: appUser.companyId,
            displayName: _nameController.text.trim(),
            role: _role,
            email: _isOperator ? null : _emailController.text.trim(),
            pin: _isOperator ? _pinController.text.trim() : null,
            businessUnitIds: _selectedUnits.toList(),
          );
      if (mounted) {
        Navigator.of(context).pop();
        if (result.pin != null) {
          _showPin(context, _nameController.text.trim(), result.pin!);
        } else {
          _showResetLink(context, result.resetLink ?? '');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invite failed: ${e.toString()}'),
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
    return AlertDialog(
      title: const Text('Invite user'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 380,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Display name'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 14),
                if (_isOperator)
                  TextFormField(
                    controller: _pinController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: InputDecoration(
                      labelText: 'PIN (for POS login)',
                      counterText: '',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.refresh, size: 20),
                        tooltip: 'Generate a new PIN',
                        onPressed: () =>
                            setState(() => _pinController.text = _generatePin()),
                      ),
                    ),
                    validator: (v) => (v == null || !RegExp(r'^\d{6}$').hasMatch(v))
                        ? 'Must be exactly 6 digits'
                        : null,
                  )
                else
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: (v) => (v == null || !v.contains('@'))
                        ? 'Valid email required'
                        : null,
                  ),
                const SizedBox(height: 14),
                DropdownButtonFormField<UserRole>(
                  initialValue: _role,
                  decoration: const InputDecoration(labelText: 'Role'),
                  dropdownColor: AppColors.surfaceHigh,
                  items: UserRole.values
                      .map((r) => DropdownMenuItem(
                            value: r,
                            child: Text(_roleLabels[r] ?? r.name),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _role = v ?? _role),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Business units',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                _BusinessUnitCheckboxList(
                  selected: _selectedUnits,
                  onChanged: (next) => setState(() => _selectedUnits = next),
                ),
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
          onPressed: _saving ? null : _invite,
          child: _saving
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Invite'),
        ),
      ],
    );
  }
}

class _EditUserDialog extends ConsumerStatefulWidget {
  const _EditUserDialog({required this.user});
  final ManagedUser user;

  @override
  ConsumerState<_EditUserDialog> createState() => _EditUserDialogState();
}

class _EditUserDialogState extends ConsumerState<_EditUserDialog> {
  late UserRole _role = widget.user.role;
  late Set<String> _selectedUnits = widget.user.businessUnitIds.toSet();
  bool _saving = false;

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(userRepositoryProvider).updateUser(
            uid: widget.user.uid,
            role: _role,
            businessUnitIds: _selectedUnits.toList(),
          );
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
    return AlertDialog(
      title: Text('Edit ${widget.user.displayName}'),
      content: SizedBox(
        width: 380,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<UserRole>(
                initialValue: _role,
                decoration: const InputDecoration(labelText: 'Role'),
                dropdownColor: AppColors.surfaceHigh,
                items: UserRole.values
                    .map((r) => DropdownMenuItem(
                          value: r,
                          child: Text(_roleLabels[r] ?? r.name),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _role = v ?? _role),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Business units',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              _BusinessUnitCheckboxList(
                selected: _selectedUnits,
                onChanged: (next) => setState(() => _selectedUnits = next),
              ),
            ],
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
              : const Text('Save'),
        ),
      ],
    );
  }
}

String _generatePin() {
  final rand = Random();
  return List.generate(6, (_) => rand.nextInt(10)).join();
}

class _ResetPinDialog extends ConsumerStatefulWidget {
  const _ResetPinDialog({required this.user});
  final ManagedUser user;

  @override
  ConsumerState<_ResetPinDialog> createState() => _ResetPinDialogState();
}

class _ResetPinDialogState extends ConsumerState<_ResetPinDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _pinController = TextEditingController(text: _generatePin());
  bool _saving = false;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final pin = _pinController.text.trim();
      await ref.read(userRepositoryProvider).resetPin(
            uid: widget.user.uid,
            pin: pin,
          );
      if (mounted) {
        Navigator.of(context).pop();
        _showPin(context, widget.user.displayName, pin);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reset failed: ${e.toString()}'),
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
    return AlertDialog(
      title: Text('Reset PIN — ${widget.user.displayName}'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 320,
          child: TextFormField(
            controller: _pinController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: InputDecoration(
              labelText: 'New PIN',
              counterText: '',
              suffixIcon: IconButton(
                icon: const Icon(Icons.refresh, size: 20),
                tooltip: 'Generate a new PIN',
                onPressed: () => setState(() => _pinController.text = _generatePin()),
              ),
            ),
            validator: (v) => (v == null || !RegExp(r'^\d{6}$').hasMatch(v))
                ? 'Must be exactly 6 digits'
                : null,
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
              : const Text('Save'),
        ),
      ],
    );
  }
}

void _showPin(BuildContext context, String displayName, String pin) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('PIN set'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tell $displayName their PIN for logging into the POS:',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          SelectableText(
            pin,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w700,
              letterSpacing: 4,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: pin));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Copied to clipboard')),
            );
          },
          child: const Text('Copy'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Done'),
        ),
      ],
    ),
  );
}

void _showResetLink(BuildContext context, String resetLink) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('User invited'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Share this link with them so they can set their password:',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          SelectableText(
            resetLink.isEmpty ? '(no link returned)' : resetLink,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 12.5),
          ),
        ],
      ),
      actions: [
        if (resetLink.isNotEmpty)
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: resetLink));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Copied to clipboard')),
              );
            },
            child: const Text('Copy'),
          ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Done'),
        ),
      ],
    ),
  );
}
