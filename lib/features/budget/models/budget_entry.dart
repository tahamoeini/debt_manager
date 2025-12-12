import 'package:flutter/foundation.dart';

@immutable
class BudgetEntry {
  final int? id;
  final String? category;
  final int amount;
  final String? period; // yyyy-MM for overrides
  final String? dateJalali; // yyyy-MM-dd for one-off entries
  final bool isOneOff;
  final String? note;
  final String createdAt;

  const BudgetEntry({
    this.id,
    this.category,
    required this.amount,
    this.period,
    this.dateJalali,
    required this.isOneOff,
    this.note,
    required this.createdAt,
  });

  BudgetEntry copyWith({
    int? id,
    String? category,
    int? amount,
    String? period,
    String? dateJalali,
    bool? isOneOff,
    String? note,
    String? createdAt,
  }) {
    return BudgetEntry(
      id: id ?? this.id,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      period: period ?? this.period,
      dateJalali: dateJalali ?? this.dateJalali,
      isOneOff: isOneOff ?? this.isOneOff,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'category': category,
      'amount': amount,
      'period': period,
      'date_jalali': dateJalali,
      'is_one_off': isOneOff ? 1 : 0,
      'note': note,
      'created_at': createdAt,
    };
  }

  factory BudgetEntry.fromMap(Map<String, dynamic> map) {
    return BudgetEntry(
      id: map['id'] is int
          ? map['id'] as int
          : (map['id'] != null ? int.tryParse(map['id'].toString()) : null),
      category: map['category'] as String?,
      amount: map['amount'] is int
          ? map['amount'] as int
          : int.parse(map['amount'].toString()),
      period: map['period'] as String?,
      dateJalali: map['date_jalali'] as String?,
      isOneOff: (map['is_one_off'] is int
              ? (map['is_one_off'] as int)
              : int.tryParse(map['is_one_off'].toString())) ==
          1,
      note: map['note'] as String?,
      createdAt: map['created_at'] as String? ?? '',
    );
  }
}
