import 'package:cloud_functions/cloud_functions.dart';

class CompanyRepository {
  CompanyRepository(this._functions);
  final FirebaseFunctions _functions;

  Future<String> createCompany({
    required String companyName,
    required String displayName,
  }) async {
    final callable = _functions.httpsCallable('createCompany');
    final result = await callable.call<Map<String, dynamic>>({
      'companyName': companyName,
      'displayName': displayName,
    });
    return result.data['companyId'] as String;
  }

  Future<CompanyLookupResult> lookupCompanyForEmail(String email) async {
    final callable = _functions.httpsCallable('lookupCompanyForEmail');
    final result = await callable.call<Map<String, dynamic>>({'email': email});
    return CompanyLookupResult(
      found: result.data['found'] as bool? ?? false,
      companyName: result.data['companyName'] as String?,
    );
  }
}

class CompanyLookupResult {
  const CompanyLookupResult({required this.found, this.companyName});
  final bool found;
  final String? companyName;
}