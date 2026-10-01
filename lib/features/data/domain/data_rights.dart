import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/failure.dart';

/// Where `exportShop` put the files (Cloud Storage paths).
class ShopExport extends Equatable {
  const ShopExport({required this.xlsxPath, required this.jsonPath});

  final String xlsxPath;
  final String jsonPath;

  @override
  List<Object?> get props => [xlsxPath, jsonPath];
}

/// Why a data request was refused (`ValidationFailure.message`).
abstract final class DataRefusal {
  /// The customer still owes, or is owed: settle first.
  static const balanceNotZero = 'balance-not-zero';

  /// The typed shop name didn't match.
  static const nameMismatch = 'name-mismatch';

  /// An owner deletes the shop before the account.
  static const deleteShopFirst = 'delete-shop-first';
}

/// The shop's data belongs to the shop (PRD N1, C9) and people's data to
/// them (PDPA): export it, erase a customer, delete the shop or an account.
/// All of these are server calls and need a connection.
abstract interface class DataRightsRepository {
  AsyncResult<ShopExport> exportShop(String shopId);

  /// Downloads an exported file (owner only, storage.rules).
  AsyncResult<Uint8List> download(String path);

  AsyncResult<Unit> eraseCustomer(String shopId, String customerId);

  AsyncResult<Unit> deleteShop(String shopId, {required String confirmName});

  AsyncResult<Unit> deleteMyAccount();
}
