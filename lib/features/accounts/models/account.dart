import 'package:freezed_annotation/freezed_annotation.dart';

part 'account.freezed.dart';

/// Account types: Bank, Wallet, Cash
enum AccountType { bank, wallet, cash }

@freezed
class Account with _$Account {
  const factory Account({
    required int id,
    required String name,
    required AccountType type,
    required double balance,
    required String? notes,
    required String createdAt, // ISO 8601
  }) = _Account;

  const Account._();

  /// Display name with type emoji
  String get displayName {
    final emoji = switch (type) {
      AccountType.bank => '🏦',
      AccountType.wallet => '👜',
      AccountType.cash => '💵',
    };
    return '$emoji $name';
  }

  /// Type label in Persian
  String get typeLabel {
    return switch (type) {
      AccountType.bank => 'حساب بانکی',
      AccountType.wallet => 'کیف پول',
      AccountType.cash => 'نقد',
    };
  }
}
