// lib/features/business_units/domain/business_unit.dart
class BusinessUnit {
  const BusinessUnit({
    required this.id,
    required this.name,
    this.address,
    this.code,
    this.defaultCustomerCode,
    this.defaultLocationCode,
  });

  final String id;
  final String name;
  final String? address;
  final String? code;
  final String? defaultCustomerCode;
  final String? defaultLocationCode;

  factory BusinessUnit.fromDoc(String id, Map<String, dynamic> data) {
    return BusinessUnit(
      id: id,
      name: data['name'] as String? ?? '',
      address: data['address'] as String?,
      code: data['code'] as String?,
      defaultCustomerCode: data['defaultCustomerCode'] as String?,
      defaultLocationCode: data['defaultLocationCode'] as String?,
    );
  }
}
