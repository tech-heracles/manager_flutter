// lib/features/dashboard/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../common_widgets/app_logo.dart';
import '../auth/application/auth_controller.dart';
import '../auth/application/auth_providers.dart';
import '../auth/domain/user_role.dart';

class DashboardModule {
  const DashboardModule({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.route,
    this.enabled = true,
    this.requiresAdmin = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String route;
  final bool enabled;
  final bool requiresAdmin;
}

const _modules = [
  DashboardModule(
    title: 'Company Configurations',
    subtitle: 'Business info & preferences',
    icon: Icons.apartment_rounded,
    route: '/company-config',
  ),
  DashboardModule(
    title: 'Users',
    subtitle: 'Team members & roles',
    icon: Icons.groups_rounded,
    route: '/users',
    requiresAdmin: true,
  ),
  DashboardModule(
    title: 'Data Source',
    subtitle: 'ERP integrations',
    icon: Icons.dns_rounded,
    route: '/erp-config',
    requiresAdmin: true,
  ),
  DashboardModule(
    title: 'Business Units',
    subtitle: 'Locations & branches',
    icon: Icons.store_mall_directory_rounded,
    route: '/business-units',
  ),
  DashboardModule(
    title: 'Master Data',
    subtitle: 'Items, customers, categories',
    icon: Icons.dataset_rounded,
    route: '/master-data',
  ),
  DashboardModule(
    title: 'Documents',
    subtitle: 'Invoices & reports',
    icon: Icons.description_rounded,
    route: '/documents',
    enabled: false,
  ),
];

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appUserAsync = ref.watch(currentAppUserProvider);
    final role = appUserAsync.value?.role;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _Header(
                displayEmail: ref
                    .watch(authRepositoryProvider)
                    .currentUser
                    ?.email,
                onLogout: () =>
                    ref.read(authControllerProvider.notifier).logout(),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              sliver: SliverLayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.crossAxisExtent;
                  final columns = width > 900
                      ? 3
                      : width > 560
                      ? 2
                      : 1;
                  return SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 1.6,
                    ),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final module = _modules[index];
                      final locked =
                          module.requiresAdmin &&
                          role != null &&
                          role != UserRole.admin;
                      return _ModuleCard(
                        module: module,
                        locked: locked,
                        onTap: (module.enabled && !locked)
                            ? () => context.push(module.route)
                            : null,
                      );
                    }, childCount: _modules.length),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.displayEmail, required this.onLogout});

  final String? displayEmail;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          const AppLogo(markSize: 36),
          const Spacer(),
          if (displayEmail != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Text(
                displayEmail!,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.textSecondary),
            tooltip: 'Sign out',
            onPressed: onLogout,
          ),
        ],
      ),
    );
  }
}

class _ModuleCard extends StatefulWidget {
  const _ModuleCard({
    required this.module,
    required this.locked,
    required this.onTap,
  });

  final DashboardModule module;
  final bool locked;
  final VoidCallback? onTap;

  @override
  State<_ModuleCard> createState() => _ModuleCardState();
}

class _ModuleCardState extends State<_ModuleCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onTap == null;
    final module = widget.module;

    return MouseRegion(
      cursor: disabled ? SystemMouseCursors.basic : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _hovering && !disabled ? AppColors.orange : AppColors.border,
            width: _hovering && !disabled ? 1.4 : 1,
          ),
          boxShadow: _hovering && !disabled
              ? [
                  BoxShadow(
                    color: AppColors.orange.withValues(alpha: 0.15),
                    blurRadius: 20,
                    spreadRadius: -4,
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: widget.onTap,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: disabled
                              ? AppColors.surfaceHighest
                              : AppColors.orange.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          module.icon,
                          color: disabled
                              ? AppColors.textMuted
                              : AppColors.orange,
                          size: 22,
                        ),
                      ),
                      const Spacer(),
                      if (widget.locked)
                        const Icon(
                          Icons.lock_outline,
                          size: 16,
                          color: AppColors.textMuted,
                        )
                      else if (disabled)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceHighest,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Soon',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textMuted,
                            ),
                          ),
                        )
                      else
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 18,
                          color: AppColors.textMuted,
                        ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    module.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: disabled
                          ? AppColors.textMuted
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    module.subtitle,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
