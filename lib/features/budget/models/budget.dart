import 'package:flutter/foundation.dart';

@immutable
class Budget {
  final int? id;
  final String? category; // null means general (all categories)
  final int amount; // stored in cents or lowest currency unit (app uses integers)
  final String period; // yyyy-MM
  final bool rollover;
  final String createdAt;

  const Budget({this.id, this.category, required this.amount, required this.period, required this.rollover, required this.createdAt});

  Budget copyWith({int? id, String? category, int? amount, String? period, bool? rollover, String? createdAt}) {
    return Budget(
      id: id ?? this.id,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      period: period ?? this.period,
      rollover: rollover ?? this.rollover,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'category': category,
      'amount': amount,
      'period': period,
      'rollover': rollover ? 1 : 0,
      'created_at': createdAt,
    };
  }

  factory Budget.fromMap(Map<String, dynamic> map) {
    return Budget(
      id: map['id'] is int ? map['id'] as int : (map['id'] != null ? int.tryParse(map['id'].toString()) : null),
      category: map['category'] as String?,
      amount: map['amount'] is int ? map['amount'] as int : int.parse(map['amount'].toString()),
      period: map['period'] as String? ?? '',
      rollover: (map['rollover'] is int ? (map['rollover'] as int) : int.tryParse(map['rollover'].toString())) == 1,
      createdAt: map['created_at'] as String? ?? '',
    );
  }
}
