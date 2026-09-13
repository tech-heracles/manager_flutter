// lib/features/master_data/application/master_data_providers.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/master_data_repository.dart';

final masterDataRepositoryProvider = Provider<MasterDataRepository>(
  (ref) => MasterDataRepository(FirebaseFirestore.instance),
);
