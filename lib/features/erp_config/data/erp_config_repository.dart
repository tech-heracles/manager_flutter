// lib/features/erp_config/data/erp_config_repository.dart
import 'package:cloud_functions/cloud_functions.dart';
import '../domain/erp_config.dart';

class ErpConfigRepository {
  ErpConfigRepository(this._functions);
  final FirebaseFunctions _functions;

  Future<ErpConfig> fetch() async {
    final callable = _functions.httpsCallable(
      'getErpConfig',
      options: HttpsCallableOptions(timeout: const Duration(seconds: 15)),
    );
    final result = await callable.call<Map<String, dynamic>>();
    return ErpConfig.fromCallableResult(result.data);
  }

  Future<void> save({
    required String erpType,
    required ErpConfig config,
    required String password,
  }) async {
    final callable = _functions.httpsCallable(
      'setErpConfig',
      options: HttpsCallableOptions(timeout: const Duration(seconds: 20)),
    );
    await callable.call<Map<String, dynamic>>({
      'erpType': erpType,
      'config': config.toConfigMap(password: password),
    });
  }

  Future<bool> testConnection({
    required String erpType,
    required ErpConfig config,
    required String password,
  }) async {
    final callable = _functions.httpsCallable(
      'testErpConnection',
      options: HttpsCallableOptions(timeout: const Duration(seconds: 20)),
    );
    final result = await callable.call<Map<String, dynamic>>({
      'erpType': erpType,
      'config': config.toConfigMap(password: password),
    });
    return result.data['ok'] as bool? ?? false;
  }
}