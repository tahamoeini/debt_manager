import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:debt_manager/core/db/database_helper.dart';
import 'package:debt_manager/features/finance/models/finance_models.dart';

class FinanceRepository {
  final _db = DatabaseHelper.instance;

  Future<List<Account>> getAccounts() => _db.getAccounts();
  Future<int> insertAccount(Account a) => _db.insertAccount(a);
  Future<int> updateAccount(Account a) => _db.updateAccount(a);
  Future<int> deleteAccount(int id) => _db.deleteAccount(id);

  Future<List<Category>> getCategories() => _db.getCategories();
  Future<int> insertCategory(Category c) => _db.insertCategory(c);
  Future<int> updateCategory(Category c) => _db.updateCategory(c);
  Future<int> deleteCategory(int id) => _db.deleteCategory(id);

  Future<List<BudgetLine>> getBudgetLines() => _db.getBudgetLines();
  Future<int> insertBudgetLine(BudgetLine b) => _db.insertBudgetLine(b);
  Future<int> updateBudgetLine(BudgetLine b) => _db.updateBudgetLine(b);
  Future<int> deleteBudgetLine(int id) => _db.deleteBudgetLine(id);

  Future<int> getBudgetSpent(int categoryId, String period) => _db.getBudgetSpent(categoryId, period);
  Future<int> getNetWorth() => _db.getNetWorth();
  Future<int> getMonthlyCashflow(String period) => _db.getMonthlyCashflow(period);
}

final financeRepositoryProvider = Provider<FinanceRepository>((ref) {
  return FinanceRepository();
});
