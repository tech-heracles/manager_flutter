// lib/features/erp_config/application/erp_config_providers.dart
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/erp_config_repository.dart';
import '../domain/erp_config.dart';

final erpConfigRepositoryProvider = Provider<ErpConfigRepository>(
  (ref) => ErpConfigRepository(FirebaseFunctions.instance),
);

final erpConfigProvider =
    AsyncNotifierProvider.autoDispose<ErpConfigController, ErpConfig>(
  ErpConfigController.new,
);

class ErpConfigController extends AutoDisposeAsyncNotifier<ErpConfig> {
  @override
  Future<ErpConfig> build() {
    return ref.read(erpConfigRepositoryProvider).fetch();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(erpConfigRepositoryProvider).fetch(),
    );
  }

  Future<void> save({
    required String erpType,
    required ErpConfig config,
    required String password,
  }) async {
    await ref.read(erpConfigRepositoryProvider).save(
          erpType: erpType,
          config: config,
          password: password,
        );
    await refresh();
  }

  Future<bool> testConnection({
    required String erpType,
    required ErpConfig config,
    required String password,
  }) {
    return ref.read(erpConfigRepositoryProvider).testConnection(
          erpType: erpType,
          config: config,
          password: password,
        );
  }
}