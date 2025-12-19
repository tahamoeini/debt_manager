import 'package:flutter/foundation.dart';

enum InstallmentStatus { pending, paid, overdue }

@immutable
class Installment {
  final int? id;
  final int loanId;
  final String dueDateJalali; // "yyyy-MM-dd"
  final int amount;
  final InstallmentStatus status;
  final String? paidAt; // ISO date string or null
  final String? paidAtJalali; // yyyy-MM-dd for local budgeting
  final int? actualPaidAmount;
  final int? notificationId;

  const Installment({
    this.id,
    required this.loanId,
    required this.dueDateJalali,
    required this.amount,
    required this.status,
    this.paidAt,
    this.paidAtJalali,
    this.actualPaidAmount,
    this.notificationId,
  });

  Installment copyWith({
    int? id,
    int? loanId,
    String? dueDateJalali,
    int? amount,
    InstallmentStatus? status,
    String? paidAt,
    String? paidAtJalali,
    int? actualPaidAmount,
    int? notificationId,
  }) {
    return Installment(
      id: id ?? this.id,
      loanId: loanId ?? this.loanId,
      dueDateJalali: dueDateJalali ?? this.dueDateJalali,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      paidAt: paidAt ?? this.paidAt,
      paidAtJalali: paidAtJalali ?? this.paidAtJalali,
      actualPaidAmount: actualPaidAmount ?? this.actualPaidAmount,
      notificationId: notificationId ?? this.notificationId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'loan_id': loanId,
      'due_date_jalali': dueDateJalali,
      'amount': amount,
      'status': status == InstallmentStatus.pending
          ? 'pending'
          : status == InstallmentStatus.paid
              ? 'paid'
              : 'overdue',
      'paid_at': paidAt,
          'paid_at_jalali': paidAtJalali,
      'actual_paid_amount': actualPaidAmount,
      'notification_id': notificationId,
    };
  }

  factory Installment.fromMap(Map<String, dynamic> map) {
    final statusStr = (map['status'] as String?)?.toLowerCase() ?? 'pending';
    final status = statusStr == 'paid'
        ? InstallmentStatus.paid
        : (statusStr == 'overdue'
            ? InstallmentStatus.overdue
            : InstallmentStatus.pending);

    return Installment(
      id: map['id'] is int
          ? map['id'] as int
          : (map['id'] != null ? int.tryParse(map['id'].toString()) : null),
      loanId: map['loan_id'] is int
          ? map['loan_id'] as int
          : int.parse(map['loan_id'].toString()),
      dueDateJalali: map['due_date_jalali'] as String? ?? '',
      amount: map['amount'] is int
          ? map['amount'] as int
          : int.parse(map['amount'].toString()),
      status: status,
      paidAt: map['paid_at'] as String?,
        paidAtJalali: map['paid_at_jalali'] as String?,
      actualPaidAmount: map['actual_paid_amount'] is int
          ? map['actual_paid_amount'] as int
          : (map['actual_paid_amount'] != null
              ? int.tryParse(map['actual_paid_amount'].toString())
              : null),
      notificationId: map['notification_id'] is int
          ? map['notification_id'] as int
          : (map['notification_id'] != null
              ? int.tryParse(map['notification_id'].toString())
              : null),
    );
  }

  @override
  String toString() {
    return 'Installment(id: $id, loanId: $loanId, dueDateJalali: $dueDateJalali, amount: $amount, status: $status, paidAt: $paidAt, paidAtJalali: $paidAtJalali, actualPaidAmount: $actualPaidAmount, notificationId: $notificationId)';
  }
}
