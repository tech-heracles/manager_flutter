// lib/features/erp_config/data/erp_config_repository.dart
import 'dart:convert';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:http/http.dart' as http;
import '../domain/erp_config.dart';

/// INTEGRIM-F5 runs on-prem, on the same network as the Financa5 SQL
/// Server — unlike Cloud Functions, it can actually reach it. Assumes the
/// person configuring the integration is on that same machine/LAN.
const _integrationServiceBaseUrl = 'http://localhost:8080';

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

  /// Tests connectivity via the local INTEGRIM-F5 service instead of a
  /// Cloud Function: Financa5's SQL Server is on-prem, so only something
  /// running on that same network can actually reach it.
  Future<bool> testConnection({
    required String erpType,
    required ErpConfig config,
    required String password,
  }) async {
    final http.Response response;
    try {
      response = await http
          .post(
            Uri.parse('$_integrationServiceBaseUrl/erp/test-connection'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(config.toConfigMap(password: password)),
          )
          .timeout(const Duration(seconds: 20));
    } catch (_) {
      throw Exception(
        'Could not reach the local integration service (INTEGRIM-F5) at '
        '$_integrationServiceBaseUrl. Make sure it is running on this '
        'machine/network.',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (data['ok'] != true) {
      throw Exception(data['error'] as String? ?? 'Connection failed');
    }
    return true;
  }
}