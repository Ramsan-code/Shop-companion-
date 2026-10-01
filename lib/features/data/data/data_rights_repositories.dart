import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_functions/cloud_functions.dart' hide Result;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/failure.dart';
import '../../auth/data/firebase_errors.dart';
import '../domain/data_rights.dart';

class FirebaseDataRightsRepository implements DataRightsRepository {
  FirebaseDataRightsRepository({
    required this._functions,
    required this._storage,
  });

  final FirebaseFunctions _functions;
  final FirebaseStorage _storage;

  /// Exports can be large; refuse anything absurd.
  static const _maxBytes = 50 * 1024 * 1024;

  AsyncResult<Map<String, dynamic>> _call(
    String name,
    Map<String, Object?> data,
  ) => TaskEither.tryCatch(() async {
    final result = await _functions
        .httpsCallable(
          name,
          options: HttpsCallableOptions(timeout: const Duration(minutes: 5)),
        )
        .call<Map<String, dynamic>>(data);
    return result.data;
  }, (e, _) => _failure(e));

  /// The server names why it refused (DataRefusal) in the message.
  static Failure _failure(Object e) =>
      e is FirebaseFunctionsException && e.code == 'failed-precondition'
      ? ValidationFailure(e.message ?? 'failed-precondition')
      : failureFromFirebase(e);

  @override
  AsyncResult<ShopExport> exportShop(String shopId) =>
      _call('exportShop', {'shopId': shopId}).map(
        (d) => ShopExport(
          xlsxPath: d['xlsxPath'] as String,
          jsonPath: d['jsonPath'] as String,
        ),
      );

  @override
  AsyncResult<Uint8List> download(String path) => TaskEither.tryCatch(() async {
    final bytes = await _storage.ref(path).getData(_maxBytes);
    if (bytes == null) throw const NotFoundFailure();
    return bytes;
  }, (e, _) => e is Failure ? e : failureFromFirebase(e));

  @override
  AsyncResult<Unit> eraseCustomer(String shopId, String customerId) => _call(
    'eraseCustomer',
    {'shopId': shopId, 'customerId': customerId},
  ).map((_) => unit);

  @override
  AsyncResult<Unit> deleteShop(String shopId, {required String confirmName}) =>
      _call('deleteShop', {
        'shopId': shopId,
        'confirmName': confirmName,
      }).map((_) => unit);

  @override
  AsyncResult<Unit> deleteMyAccount() =>
      _call('deleteMyAccount', const {}).map((_) => unit);
}

/// The fake backend: records what was asked and answers like the server.
class FakeDataRightsRepository implements DataRightsRepository {
  FakeDataRightsRepository({
    this.shopName = 'Demo Shop',
    this.balanceOf,
    this.isOwner = true,
  });

  final String shopName;

  /// Balance of a customer, to refuse erasing one who owes.
  int Function(String customerId)? balanceOf;
  bool isOwner;

  final calls = <String>[];
  final files = <String, Uint8List>{};

  @override
  AsyncResult<ShopExport> exportShop(String shopId) => TaskEither(() async {
    calls.add('exportShop');
    const base = 'shops/fake-shop/exports/now/shop-companion';
    files['$base.xlsx'] = Uint8List.fromList(utf8.encode('xlsx'));
    files['$base.json'] = Uint8List.fromList(utf8.encode('{}'));
    return right(
      const ShopExport(xlsxPath: '$base.xlsx', jsonPath: '$base.json'),
    );
  });

  @override
  AsyncResult<Uint8List> download(String path) => TaskEither(
    () async => files[path] == null
        ? left(const NotFoundFailure())
        : right(files[path]!),
  );

  @override
  AsyncResult<Unit> eraseCustomer(String shopId, String customerId) =>
      TaskEither(() async {
        if ((balanceOf?.call(customerId) ?? 0) != 0) {
          return left(const ValidationFailure(DataRefusal.balanceNotZero));
        }
        calls.add('eraseCustomer:$customerId');
        return right(unit);
      });

  @override
  AsyncResult<Unit> deleteShop(String shopId, {required String confirmName}) =>
      TaskEither(() async {
        if (confirmName.trim() != shopName.trim()) {
          return left(const ValidationFailure(DataRefusal.nameMismatch));
        }
        calls.add('deleteShop');
        return right(unit);
      });

  @override
  AsyncResult<Unit> deleteMyAccount() => TaskEither(() async {
    if (isOwner) {
      return left(const ValidationFailure(DataRefusal.deleteShopFirst));
    }
    calls.add('deleteMyAccount');
    return right(unit);
  });
}
