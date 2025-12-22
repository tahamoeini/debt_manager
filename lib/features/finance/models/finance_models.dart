// Account model for financial tracking (savings, checking, cash, etc).
import 'package:flutter/foundation.dart';

@immutable
class Account {
  final int? id;
  final String name;
  final String type; // 'savings', 'checking', 'cash', 'credit_card', 'loan', 'investment'
  final int? balance; // optional balance tracking
  final String? notes;
  final String createdAt;

  const Account({
    this.id,
    required this.name,
    required this.type,
    this.balance,
    this.notes,
    required this.createdAt,
  });

  Account copyWith({
    int? id,
    String? name,
    String? type,
    int? balance,
    String? notes,
    String? createdAt,
  }) {
    return Account(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      balance: balance ?? this.balance,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Financial category for expenses and income (utilities, salary, groceries, etc).
@immutable
class Category {
  final int? id;
  final String name;
  final String type; // 'expense' or 'income'
  final String? color;
  final String? icon;
  final String createdAt;

  const Category({
    this.id,
    required this.name,
    required this.type,
    this.color,
    this.icon,
    required this.createdAt,
  });

  Category copyWith({
    int? id,
    String? name,
    String? type,
    String? color,
    String? icon,
    String? createdAt,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Budget line item: a budget allocation for a category in a given period.
@immutable
class BudgetLine {
  final int? id;
  final int categoryId;
  final int amount;
  final String period; // 'yyyy-MM' for monthly budgets
  final int? spent; // populated when computing budget vs. actual
  final String createdAt;

  const BudgetLine({
    this.id,
    required this.categoryId,
    required this.amount,
    required this.period,
    this.spent,
    required this.createdAt,
  });

  BudgetLine copyWith({
    int? id,
    int? categoryId,
    int? amount,
    String? period,
    int? spent,
    String? createdAt,
  }) {
    return BudgetLine(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      amount: amount ?? this.amount,
      period: period ?? this.period,
      spent: spent ?? this.spent,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
