// lib/features/master_data/data/master_data_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class MasterDataPage {
  const MasterDataPage({required this.docs, required this.hasMore});

  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;
  final bool hasMore;
}

class MasterDataRepository {
  MasterDataRepository(this._firestore);
  final FirebaseFirestore _firestore;

  static const pageSize = 50;

  Future<MasterDataPage> fetchPage({
    required String companyId,
    required String collection,
    required String sortField,
    String? searchPrefix,
    QueryDocumentSnapshot<Map<String, dynamic>>? startAfter,
  }) async {
    Query<Map<String, dynamic>> query = _firestore
        .collection('companies')
        .doc(companyId)
        .collection(collection)
        .orderBy(sortField);

    if (searchPrefix != null && searchPrefix.isNotEmpty) {
      query = query
          .where(sortField, isGreaterThanOrEqualTo: searchPrefix)
          .where(sortField, isLessThan: '$searchPrefix');
    }
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }
    query = query.limit(pageSize);

    final snapshot = await query.get();
    return MasterDataPage(
      docs: snapshot.docs,
      hasMore: snapshot.docs.length == pageSize,
    );
  }

  /// SYNC_META doc ids match the collection names 1:1 (see INTEGRIM-F5's
  /// sync services), so `entity` is just the collection name.
  Future<DateTime?> lastSyncedAt(String companyId, String entity) async {
    final snap = await _firestore
        .collection('companies')
        .doc(companyId)
        .collection('SYNC_META')
        .doc(entity)
        .get();
    final ts = snap.data()?['lastSyncTime'];
    return ts is Timestamp ? ts.toDate() : null;
  }
}
