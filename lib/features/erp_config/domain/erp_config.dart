// lib/features/erp_config/domain/erp_config.dart
class ErpConfig {
  const ErpConfig({
    required this.erpType,
    required this.server,
    required this.database,
    required this.user,
    this.encrypt = false,
    this.trustServerCertificate = true,
    this.port,
    this.configured = false,
    this.updatedAt,
  });

  final String erpType;
  final String server;
  final String database;
  final String user;
  final bool encrypt;
  final bool trustServerCertificate;
  final int? port;
  final bool configured;
  final DateTime? updatedAt;

  static const empty = ErpConfig(
    erpType: 'financa5',
    server: '',
    database: '',
    user: '',
  );

  factory ErpConfig.fromCallableResult(Map<String, dynamic> data) {
    if (data['configured'] != true) return empty;
    final config = (data['config'] as Map?)?.cast<String, dynamic>() ?? {};
    final updatedAtRaw = data['updatedAt'];
    return ErpConfig(
      erpType: data['activeErpType'] as String? ?? 'financa5',
      server: config['server'] as String? ?? '',
      database: config['database'] as String? ?? '',
      user: config['user'] as String? ?? '',
      encrypt: config['encrypt'] as bool? ?? false,
      trustServerCertificate: config['trustServerCertificate'] as bool? ?? true,
      port: config['port'] as int?,
      configured: true,
      updatedAt: updatedAtRaw is String ? DateTime.tryParse(updatedAtRaw) : null,
    );
  }

  Map<String, dynamic> toConfigMap({String? password}) {
    return {
      'server': server,
      'database': database,
      'user': user,
      if (password != null && password.isNotEmpty) 'password': password,
      'encrypt': encrypt,
      'trustServerCertificate': trustServerCertificate,
      if (port != null) 'port': port,
    };
  }
}

const erpTypes = <String, String>{
  'financa5': 'Financa 5',
  'alphaweb': 'AlphaWEB',
  'nav': 'Microsoft NAV',
  'odoo': 'Odoo',
};

const implementedErpTypes = {'financa5'};