import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:debt_manager/features/accounts/models/account.dart';
import 'package:debt_manager/features/accounts/repositories/accounts_repository.dart';
import 'package:debt_manager/core/providers/core_providers.dart';

/// Provides a list of all accounts
final accountsListProvider = FutureProvider<List<Account>>((ref) async {
  final repo = ref.watch(accountsRepositoryProvider);
  return repo.listAccounts();
});

/// Provides a single account by ID
final accountByIdProvider = FutureProviderFamily<Account?, int>((ref, id) async {
  final repo = ref.watch(accountsRepositoryProvider);
  return repo.getAccountById(id);
});

/// Notifier for managing account operations
class AccountsNotifier extends StateNotifier<AsyncValue<List<Account>>> {
  final AccountsRepository _repository;

  AccountsNotifier(this._repository)
      : super(const AsyncValue.loading());

  Future<void> loadAccounts() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.listAccounts());
  }

  Future<void> addAccount(Account account) async {
    await _repository.insertAccount(account);
    await loadAccounts();
  }

  Future<void> updateAccount(Account account) async {
    await _repository.updateAccount(account);
    await loadAccounts();
  }

  Future<void> deleteAccount(int id) async {
    await _repository.deleteAccount(id);
    await loadAccounts();
  }
}

/// Provides the accounts notifier
final accountsNotifierProvider =
    StateNotifierProvider<AccountsNotifier, AsyncValue<List<Account>>>((ref) {
  final repo = ref.watch(accountsRepositoryProvider);
  return AccountsNotifier(repo)..loadAccounts();
});
