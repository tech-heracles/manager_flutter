// lib/features/erp_config/presentation/erp_config_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme.dart';
import '../application/erp_config_providers.dart';
import '../domain/erp_config.dart';

class ErpConfigScreen extends ConsumerStatefulWidget {
  const ErpConfigScreen({super.key});

  @override
  ConsumerState<ErpConfigScreen> createState() => _ErpConfigScreenState();
}

class _ErpConfigScreenState extends ConsumerState<ErpConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  final _serverController = TextEditingController();
  final _databaseController = TextEditingController();
  final _userController = TextEditingController();
  final _passwordController = TextEditingController();
  final _portController = TextEditingController();

  String _erpType = 'financa5';
  bool _encrypt = false;
  bool _trustServerCertificate = true;
  bool _obscurePassword = true;
  bool _saving = false;
  bool _testing = false;
  bool _initialized = false;

  @override
  void dispose() {
    _serverController.dispose();
    _databaseController.dispose();
    _userController.dispose();
    _passwordController.dispose();
    _portController.dispose();
    super.dispose();
  }

  void _hydrate(ErpConfig config) {
    if (_initialized) return;
    _erpType = config.erpType;
    _serverController.text = config.server;
    _databaseController.text = config.database;
    _userController.text = config.user;
    _encrypt = config.encrypt;
    _trustServerCertificate = config.trustServerCertificate;
    _portController.text = config.port?.toString() ?? '';
    _initialized = true;
  }

  ErpConfig _buildConfig() {
    return ErpConfig(
      erpType: _erpType,
      server: _serverController.text.trim(),
      database: _databaseController.text.trim(),
      user: _userController.text.trim(),
      encrypt: _encrypt,
      trustServerCertificate: _trustServerCertificate,
      port: _portController.text.trim().isEmpty
          ? null
          : int.tryParse(_portController.text.trim()),
    );
  }

  Future<void> _test() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _testing = true);
    try {
      final ok = await ref.read(erpConfigProvider.notifier).testConnection(
            erpType: _erpType,
            config: _buildConfig(),
            password: _passwordController.text,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? 'Connection successful' : 'Connection failed'),
          backgroundColor: ok ? null : AppColors.error,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Test failed: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password is required to save.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await ref.read(erpConfigProvider.notifier).save(
            erpType: _erpType,
            config: _buildConfig(),
            password: _passwordController.text,
          );
      _passwordController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ERP configuration saved')),
        );
      }
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
    final configAsync = ref.watch(erpConfigProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Data Source')),
      body: configAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.orange),
        ),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: AppColors.error, size: 32),
                const SizedBox(height: 12),
                const Text(
                  'Could not load ERP configuration.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () => ref.read(erpConfigProvider.notifier).refresh(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (config) {
          _hydrate(config);
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _StatusBanner(configured: config.configured, erpType: config.erpType),
                    const SizedBox(height: 16),
                    _SectionCard(
                      title: 'ERP System',
                      icon: Icons.dns_rounded,
                      children: [
                        DropdownButtonFormField<String>(
                          initialValue: _erpType,
                          decoration: const InputDecoration(labelText: 'ERP Type'),
                          dropdownColor: AppColors.surfaceHigh,
                          items: erpTypes.entries
                              .map((e) => DropdownMenuItem(
                                    value: e.key,
                                    enabled: implementedErpTypes.contains(e.key),
                                    child: Row(
                                      children: [
                                        Text(e.value),
                                        if (!implementedErpTypes.contains(e.key)) ...[
                                          const SizedBox(width: 8),
                                          const Text(
                                            '(coming soon)',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: AppColors.textMuted,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ))
                              .toList(),
                          onChanged: (v) {
                            if (v != null && implementedErpTypes.contains(v)) {
                              setState(() => _erpType = v);
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _SectionCard(
                      title: 'Connection',
                      icon: Icons.cable_rounded,
                      children: [
                        TextFormField(
                          controller: _serverController,
                          decoration: const InputDecoration(
                            labelText: 'Server',
                            hintText: r'e.g. SERVERNAME\HERACLES or 192.168.1.10',
                          ),
                          validator: (v) =>
                              (v == null || v.trim().isEmpty) ? 'Required' : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _databaseController,
                          decoration: const InputDecoration(labelText: 'Database'),
                          validator: (v) =>
                              (v == null || v.trim().isEmpty) ? 'Required' : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _portController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Port (optional)',
                            hintText: 'Leave empty for named instance auto-discovery',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _SectionCard(
                      title: 'Credentials',
                      icon: Icons.lock_outline_rounded,
                      children: [
                        TextFormField(
                          controller: _userController,
                          decoration: const InputDecoration(labelText: 'Username'),
                          validator: (v) =>
                              (v == null || v.trim().isEmpty) ? 'Required' : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: config.configured
                                ? 'Password (leave empty to keep current)'
                                : 'Password',
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: AppColors.textMuted,
                                size: 20,
                              ),
                              onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                          validator: (v) {
                            if (!config.configured &&
                                (v == null || v.isEmpty)) {
                              return 'Required';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _SectionCard(
                      title: 'Security',
                      icon: Icons.shield_outlined,
                      children: [
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          activeThumbColor: AppColors.orange,
                          title: const Text('Encrypt connection',
                              style: TextStyle(color: AppColors.textPrimary)),
                          value: _encrypt,
                          onChanged: (v) => setState(() => _encrypt = v),
                        ),
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          activeThumbColor: AppColors.orange,
                          title: const Text('Trust server certificate',
                              style: TextStyle(color: AppColors.textPrimary)),
                          value: _trustServerCertificate,
                          onChanged: (v) =>
                              setState(() => _trustServerCertificate = v),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _testing ? null : _test,
                            icon: _testing
                                ? const SizedBox(
                                    height: 16,
                                    width: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.bolt_outlined, size: 18),
                            label: const Text('Test connection'),
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
                                : const Text('Save'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.configured, required this.erpType});
  final bool configured;
  final String erpType;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(
            configured ? Icons.check_circle : Icons.circle_outlined,
            size: 16,
            color: configured ? AppColors.success : AppColors.textMuted,
          ),
          const SizedBox(width: 10),
          Text(
            configured
                ? 'Connected — ${erpTypes[erpType] ?? erpType}'
                : 'No ERP connected yet',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.orange),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}