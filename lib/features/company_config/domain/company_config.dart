// lib/features/company_config/domain/company_config.dart
class CompanyConfig {
  const CompanyConfig({
    required this.name,
    this.address,
    this.phone,
    this.nipt,
    this.currency = 'ALL',
    this.activeErpType,
  });

  final String name;
  final String? address;
  final String? phone;
  final String? nipt;
  final String currency;
  final String? activeErpType;

  factory CompanyConfig.fromMap(Map<String, dynamic> data) {
    return CompanyConfig(
      name: data['name'] as String? ?? '',
      address: data['address'] as String?,
      phone: data['phone'] as String?,
      nipt: data['nipt'] as String?,
      currency: data['currency'] as String? ?? 'ALL',
      activeErpType: data['activeErpType'] as String?,
    );
  }

  Map<String, dynamic> toUpdateMap() {
    return {
      'name': name,
      'address': address,
      'phone': phone,
      'nipt': nipt,
      'currency': currency,
    };
  }

  CompanyConfig copyWith({
    String? name,
    String? address,
    String? phone,
    String? nipt,
    String? currency,
  }) {
    return CompanyConfig(
      name: name ?? this.name,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      nipt: nipt ?? this.nipt,
      currency: currency ?? this.currency,
      activeErpType: activeErpType,
    );
  }
}