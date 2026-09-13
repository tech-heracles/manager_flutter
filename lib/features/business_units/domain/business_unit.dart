// lib/features/business_units/domain/business_unit.dart
class BusinessUnit {
  const BusinessUnit({required this.id, required this.name, this.address});

  final String id;
  final String name;
  final String? address;

  factory BusinessUnit.fromDoc(String id, Map<String, dynamic> data) {
    return BusinessUnit(
      id: id,
      name: data['name'] as String? ?? '',
      address: data['address'] as String?,
    );
  }
}
