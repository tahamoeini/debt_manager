import 'package:shamsi_date/shamsi_date.dart';

enum PaymentStatus { pending, partial, paid, overdue }

class InstallmentPayment {
  final int id;
  final int installmentId;
  final int loanId;
  final int accountId; // Source account for payment
  final double amount;
  final Jalali dueDate;
  final Jalali? paidDate;
  final double amountPaid;
  final PaymentStatus status;
  final String? notes;
  final String createdAt;

  const InstallmentPayment({
    required this.id,
    required this.installmentId,
    required this.loanId,
    required this.accountId,
    required this.amount,
    required this.dueDate,
    this.paidDate,
    required this.amountPaid,
    required this.status,
    this.notes,
    required this.createdAt,
  });

  /// Is this payment overdue?
  bool get isOverdue => 
    status == PaymentStatus.pending && Jalali.now().isAfter(dueDate);

  /// Remaining amount to pay
  double get remainingAmount => (amount - amountPaid).abs();

  /// Display status in Persian
  String get statusLabel => switch (status) {
    PaymentStatus.pending => 'در انتظار',
    PaymentStatus.partial => 'جزئی',
    PaymentStatus.paid => 'پرداخت شده',
    PaymentStatus.overdue => 'تأخیر',
  };

  InstallmentPayment copyWith({
    int? id,
    int? installmentId,
    int? loanId,
    int? accountId,
    double? amount,
    Jalali? dueDate,
    Jalali? paidDate,
    double? amountPaid,
    PaymentStatus? status,
    String? notes,
    String? createdAt,
  }) {
    return InstallmentPayment(
      id: id ?? this.id,
      installmentId: installmentId ?? this.installmentId,
      loanId: loanId ?? this.loanId,
      accountId: accountId ?? this.accountId,
      amount: amount ?? this.amount,
      dueDate: dueDate ?? this.dueDate,
      paidDate: paidDate ?? this.paidDate,
      amountPaid: amountPaid ?? this.amountPaid,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
