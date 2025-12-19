import 'package:flutter/foundation.dart';

@immutable
class FinancialTransaction {
  final int? id;
  final String timestamp; // ISO 8601
  final int amount; // stored in minor units (e.g., cents)
  final String direction; // 'credit' or 'debit'
  final int? accountId;
  final String? relatedType; // e.g., 'loan' or 'installment'
  final int? relatedId;
  final String? description;
  final String? source; // 'manual' | 'scheduled' | 'system'

  const FinancialTransaction({
    this.id,
    required this.timestamp,
    required this.amount,
    required this.direction,
    this.accountId,
    this.relatedType,
    this.relatedId,
    this.description,
    this.source,
  });

  FinancialTransaction copyWith({
    int? id,
    String? timestamp,
    int? amount,
    String? direction,
    int? accountId,
    String? relatedType,
    int? relatedId,
    String? description,
    String? source,
  }) {
    return FinancialTransaction(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      amount: amount ?? this.amount,
      direction: direction ?? this.direction,
      accountId: accountId ?? this.accountId,
      relatedType: relatedType ?? this.relatedType,
      relatedId: relatedId ?? this.relatedId,
      description: description ?? this.description,
      source: source ?? this.source,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'timestamp': timestamp,
      'amount': amount,
      'direction': direction,
      'account_id': accountId,
      'related_type': relatedType,
      'related_id': relatedId,
      'description': description,
      'source': source,
    };
  }

  factory FinancialTransaction.fromMap(Map<String, dynamic> m) {
    return FinancialTransaction(
      id: m['id'] is int ? m['id'] as int : (m['id'] != null ? int.tryParse(m['id'].toString()) : null),
      timestamp: m['timestamp'] as String? ?? '',
      amount: m['amount'] is int ? m['amount'] as int : int.parse(m['amount'].toString()),
      direction: m['direction'] as String? ?? 'debit',
      accountId: m['account_id'] is int ? m['account_id'] as int : (m['account_id'] != null ? int.tryParse(m['account_id'].toString()) : null),
      relatedType: m['related_type'] as String?,
      relatedId: m['related_id'] is int ? m['related_id'] as int : (m['related_id'] != null ? int.tryParse(m['related_id'].toString()) : null),
      description: m['description'] as String?,
      source: m['source'] as String?,
    );
  }

  @override
  String toString() => 'FT(id: $id, $direction $amount @ $timestamp, account: $accountId, related: $relatedType#$relatedId)';
}
