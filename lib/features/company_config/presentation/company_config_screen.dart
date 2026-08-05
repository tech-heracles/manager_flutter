// lib/features/company_config/presentation/company_config_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme.dart';
import '../application/company_config_providers.dart';
import '../data/company_config_repository.dart';
import '../domain/company_config.dart';

const _currencies = ['ALL', 'EUR', 'USD'];

class CompanyConfigScreen extends ConsumerStatefulWidget {
  const CompanyConfigScreen({super.key});

  @override
  ConsumerState<CompanyConfigScreen> createState() =>
      _CompanyConfigScreenState();
}

class _CompanyConfigScreenState extends ConsumerState<CompanyConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _niptController = TextEditingController();
  String _currency = 'ALL';

  bool _initialized = false;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _niptController.dispose();
    super.dispose();
  }

  void _hydrate(CompanyConfig config) {
    if (_initialized) return;
    _nameController.text = config.name;
    _addressController.text = config.address ?? '';
    _phoneController.text = config.phone ?? '';
    _niptController.text = config.nipt ?? '';
    _currency = config.currency;
    _initialized = true;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final repo = ref.read(companyConfigRepositoryProvider);
      await repo.update(CompanyConfig(
        name: _nameController.text.trim(),
        address: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        nipt: _niptController.text.trim().isEmpty
            ? null
            : _niptController.text.trim(),
        currency: _currency,
      ));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Company settings saved')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final configAsync = ref.watch(companyConfigStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Company Configurations')),
      body: configAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.orange),
        ),
        error: (err, _) => Center(
          child: Text(
            'Failed to load company settings.',
            style: const TextStyle(color: AppColors.textSecondary),
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
                    _SectionCard(
                      title: 'General',
                      icon: Icons.apartment_rounded,
                      children: [
                        TextFormField(
                          controller: _nameController,
                          decoration:
                              const InputDecoration(labelText: 'Company name'),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Required'
                              : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _addressController,
                          decoration: const InputDecoration(labelText: 'Address'),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                decoration:
                                    const InputDecoration(labelText: 'Phone'),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: TextFormField(
                                controller: _niptController,
                                decoration:
                                    const InputDecoration(labelText: 'NIPT / Tax ID'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<String>(
                          initialValue: _currency,
                          decoration:
                              const InputDecoration(labelText: 'Currency'),
                          dropdownColor: AppColors.surfaceHigh,
                          items: _currencies
                              .map((c) =>
                                  DropdownMenuItem(value: c, child: Text(c)))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _currency = v ?? _currency),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _SectionCard(
                      title: 'Integration',
                      icon: Icons.dns_rounded,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.circle,
                                size: 8, color: AppColors.success),
                            const SizedBox(width: 8),
                            Text(
                              config.activeErpType == null
                                  ? 'No ERP connected'
                                  : 'Connected: ${config.activeErpType}',
                              style: const TextStyle(
                                  color: AppColors.textSecondary),
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: null, // wired up in Data Source module
                              child: const Text('Manage in Data Source'),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Save changes'),
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