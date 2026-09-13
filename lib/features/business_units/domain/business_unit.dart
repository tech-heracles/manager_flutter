// lib/features/business_units/domain/business_unit.dart
class ZoneTable {
  const ZoneTable({required this.id, required this.name});
  final String id;
  final String name;

  factory ZoneTable.fromMap(Map<String, dynamic> data) => ZoneTable(
        id: data['id'] as String? ?? '',
        name: data['name'] as String? ?? '',
      );

  Map<String, dynamic> toMap() => {'id': id, 'name': name};
}

class Zone {
  const Zone({required this.id, required this.name, required this.tables});
  final String id;
  final String name;
  final List<ZoneTable> tables;

  factory Zone.fromMap(Map<String, dynamic> data) => Zone(
        id: data['id'] as String? ?? '',
        name: data['name'] as String? ?? '',
        tables: (data['tables'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(ZoneTable.fromMap)
            .toList(),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'tables': tables.map((t) => t.toMap()).toList(),
      };
}

class BusinessUnit {
  const BusinessUnit({
    required this.id,
    required this.name,
    this.address,
    this.code,
    this.defaultCustomerCode,
    this.defaultLocationCode,
    this.visibleItemGroupCodes,
    this.salesMode = 'simple',
    this.zones = const [],
  });

  final String id;
  final String name;
  final String? address;
  final String? code;
  final String? defaultCustomerCode;
  final String? defaultLocationCode;

  /// null means "no restriction" — every synced Item Group is shown in POS.
  final List<String>? visibleItemGroupCodes;

  /// 'simple' (free-form tickets, e.g. retail) or 'tables' (BAR/RESTAURANT:
  /// operators pick a zone + table, which can queue several rounds before
  /// a single summary invoice closes it).
  final String salesMode;
  final List<Zone> zones;

  factory BusinessUnit.fromDoc(String id, Map<String, dynamic> data) {
    return BusinessUnit(
      id: id,
      name: data['name'] as String? ?? '',
      address: data['address'] as String?,
      code: data['code'] as String?,
      defaultCustomerCode: data['defaultCustomerCode'] as String?,
      defaultLocationCode: data['defaultLocationCode'] as String?,
      visibleItemGroupCodes: (data['visibleItemGroupCodes'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      salesMode: data['salesMode'] as String? ?? 'simple',
      zones: (data['zones'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(Zone.fromMap)
          .toList(),
    );
  }
}
