import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/account.dart';
import '../repositories/accounts_repository.dart';

part 'accounts_provider.g.dart';

@riverpod
class AccountsNotifier extends _$AccountsNotifier {
  @override
  Future<List<Account>> build() async {
    final repo = ref.watch(accountsRepositoryProvider);
    return repo.listAccounts();
  }

  Future<void> addAccount(Account account) async {
    final repo = ref.watch(accountsRepositoryProvider);
    await repo.insertAccount(account);
    ref.invalidateSelf();
  }

  Future<void> updateAccount(Account account) async {
    final repo = ref.watch(accountsRepositoryProvider);
    await repo.updateAccount(account);
    ref.invalidateSelf();
  }

  Future<void> deleteAccount(int id) async {
    final repo = ref.watch(accountsRepositoryProvider);
    await repo.deleteAccount(id);
    ref.invalidateSelf();
  }
}

@riverpod
AccountsRepository accountsRepository(AccountsRepositoryRef ref) {
  // Will be initialized by dependency injection in core
  throw UnimplementedError();
}

/// Fetch a single account by ID
@riverpod
Future<Account?> accountById(AccountByIdRef ref, int id) async {
  final repo = ref.watch(accountsRepositoryProvider);
  return repo.getAccountById(id);
}
