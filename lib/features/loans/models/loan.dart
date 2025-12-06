import 'package:flutter/foundation.dart';

// Direction of the loan: whether the user borrowed or lent money.
enum LoanDirection { borrowed, lent }

@immutable
class Loan {
  final int? id;
  final int counterpartyId;
  final String title;
  final LoanDirection direction;
  final int principalAmount;
  final int installmentCount;
  final int installmentAmount;
  final String startDateJalali; // formatted as "yyyy-MM-dd"
  final String? notes;
  final String createdAt; // ISO 8601 datetime string
  final double? interestRate; // annual percentage (e.g., 5.5)
  final int? monthlyPayment;
  final int? termMonths;

  const Loan({
    this.id,
    required this.counterpartyId,
    required this.title,
    required this.direction,
    required this.principalAmount,
    required this.installmentCount,
    required this.installmentAmount,
    required this.startDateJalali,
    this.notes,
    this.interestRate,
    this.monthlyPayment,
    this.termMonths,
    required this.createdAt,
  });

  Loan copyWith({
    int? id,
    int? counterpartyId,
    String? title,
    LoanDirection? direction,
    int? principalAmount,
    int? installmentCount,
    int? installmentAmount,
    String? startDateJalali,
    String? notes,
    double? interestRate,
    int? monthlyPayment,
    int? termMonths,
    String? createdAt,
  }) {
    return Loan(
      id: id ?? this.id,
      counterpartyId: counterpartyId ?? this.counterpartyId,
      title: title ?? this.title,
      direction: direction ?? this.direction,
      principalAmount: principalAmount ?? this.principalAmount,
      installmentCount: installmentCount ?? this.installmentCount,
      installmentAmount: installmentAmount ?? this.installmentAmount,
      startDateJalali: startDateJalali ?? this.startDateJalali,
      notes: notes ?? this.notes,
      interestRate: interestRate ?? this.interestRate,
      monthlyPayment: monthlyPayment ?? this.monthlyPayment,
      termMonths: termMonths ?? this.termMonths,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'counterparty_id': counterpartyId,
      'title': title,
      'direction': direction == LoanDirection.borrowed ? 'borrowed' : 'lent',
      'principal_amount': principalAmount,
      'installment_count': installmentCount,
      'installment_amount': installmentAmount,
      'start_date_jalali': startDateJalali,
      'notes': notes,
      'interest_rate': interestRate,
      'monthly_payment': monthlyPayment,
      'term_months': termMonths,
      'created_at': createdAt,
    };
  }

  factory Loan.fromMap(Map<String, dynamic> map) {
    final dirStr = map['direction'] as String? ?? 'borrowed';
    final direction = dirStr.toLowerCase() == 'lent'
        ? LoanDirection.lent
        : LoanDirection.borrowed;

    return Loan(
      id: map['id'] is int
          ? map['id'] as int
          : (map['id'] != null ? int.tryParse(map['id'].toString()) : null),
      counterpartyId: map['counterparty_id'] is int
          ? map['counterparty_id'] as int
          : int.parse(map['counterparty_id'].toString()),
      title: map['title'] as String? ?? '',
      direction: direction,
      principalAmount: map['principal_amount'] is int
          ? map['principal_amount'] as int
          : int.parse(map['principal_amount'].toString()),
      installmentCount: map['installment_count'] is int
          ? map['installment_count'] as int
          : int.parse(map['installment_count'].toString()),
      installmentAmount: map['installment_amount'] is int
          ? map['installment_amount'] as int
          : int.parse(map['installment_amount'].toString()),
      startDateJalali: map['start_date_jalali'] as String? ?? '',
      notes: map['notes'] as String?,
      interestRate: map['interest_rate'] is num ? (map['interest_rate'] as num).toDouble() : (map['interest_rate'] is String ? double.tryParse(map['interest_rate']) : null),
      monthlyPayment: map['monthly_payment'] is int ? map['monthly_payment'] as int : (map['monthly_payment'] != null ? int.tryParse(map['monthly_payment'].toString()) : null),
      termMonths: map['term_months'] is int ? map['term_months'] as int : (map['term_months'] != null ? int.tryParse(map['term_months'].toString()) : null),
      createdAt: map['created_at'] as String? ?? '',
    );
  }

  @override
  String toString() {
    return 'Loan(id: $id, counterpartyId: $counterpartyId, title: $title, direction: $direction, principalAmount: $principalAmount, installmentCount: $installmentCount, installmentAmount: $installmentAmount, startDateJalali: $startDateJalali, notes: $notes, createdAt: $createdAt)';
  }
}
