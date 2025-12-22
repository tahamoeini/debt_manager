import 'package:flutter/foundation.dart';

/// Ledger entry representing a single cashflow event.
@immutable
class LedgerEntry {
  final int? id;
  final int amount; // positive=inflow, negative=outflow
  final int? categoryId;
  final String refType; // e.g., loan_disbursement, installment_payment, manual
  final int? refId;
  final String dateJalali; // yyyy-MM-dd
  final String? note;
  final String createdAt; // ISO 8601

  const LedgerEntry({
    this.id,
    required this.amount,
    this.categoryId,
    required this.refType,
    this.refId,
    required this.dateJalali,
    this.note,
    required this.createdAt,
  });

  LedgerEntry copyWith({
    int? id,
    int? amount,
    int? categoryId,
    String? refType,
    int? refId,
    String? dateJalali,
    String? note,
    String? createdAt,
  }) {
    return LedgerEntry(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      refType: refType ?? this.refType,
      refId: refId ?? this.refId,
      dateJalali: dateJalali ?? this.dateJalali,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'amount': amount,
      'category_id': categoryId,
      'ref_type': refType,
      'ref_id': refId,
      'date_jalali': dateJalali,
      'note': note,
      'created_at': createdAt,
    };
  }

  factory LedgerEntry.fromMap(Map<String, dynamic> map) {
    return LedgerEntry(
      id: map['id'] is int
          ? map['id'] as int
          : (map['id'] != null ? int.tryParse('${map['id']}') : null),
      amount: map['amount'] is int
          ? map['amount'] as int
          : int.parse(map['amount'].toString()),
      categoryId: map['category_id'] is int
          ? map['category_id'] as int
          : (map['category_id'] != null ? int.tryParse('${map['category_id']}') : null),
      refType: map['ref_type'] as String? ?? '',
      refId: map['ref_id'] is int
          ? map['ref_id'] as int
          : (map['ref_id'] != null ? int.tryParse('${map['ref_id']}') : null),
      dateJalali: map['date_jalali'] as String? ?? '',
      note: map['note'] as String?,
      createdAt: map['created_at'] as String? ?? '',
    );
  }
}
