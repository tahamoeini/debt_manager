// Automation rule model: defines rules for auto-categorization
import 'package:flutter/foundation.dart';

@immutable
class AutomationRule {
  final int? id;
  final String name;
  final String
      ruleType; // 'payee_contains', 'amount_equals', 'description_contains'
  final String pattern; // The pattern to match
  final String action; // 'set_category', 'set_tag'
  final String
      actionValue; // The value to apply (e.g., category name, tag name)
  final bool enabled;
  final String createdAt;

  const AutomationRule({
    this.id,
    required this.name,
    required this.ruleType,
    required this.pattern,
    required this.action,
    required this.actionValue,
    this.enabled = true,
    required this.createdAt,
  });

  AutomationRule copyWith({
    int? id,
    String? name,
    String? ruleType,
    String? pattern,
    String? action,
    String? actionValue,
    bool? enabled,
    String? createdAt,
  }) {
    return AutomationRule(
      id: id ?? this.id,
      name: name ?? this.name,
      ruleType: ruleType ?? this.ruleType,
      pattern: pattern ?? this.pattern,
      action: action ?? this.action,
      actionValue: actionValue ?? this.actionValue,
      enabled: enabled ?? this.enabled,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'rule_type': ruleType,
      'pattern': pattern,
      'action': action,
      'action_value': actionValue,
      'enabled': enabled ? 1 : 0,
      'created_at': createdAt,
    };
  }

  factory AutomationRule.fromMap(Map<String, dynamic> map) {
    return AutomationRule(
      id: map['id'] is int
          ? map['id'] as int
          : (map['id'] != null ? int.tryParse(map['id'].toString()) : null),
      name: map['name'] as String? ?? '',
      ruleType: map['rule_type'] as String? ?? '',
      pattern: map['pattern'] as String? ?? '',
      action: map['action'] as String? ?? '',
      actionValue: map['action_value'] as String? ?? '',
      enabled: (map['enabled'] is int
              ? (map['enabled'] as int)
              : int.tryParse(map['enabled'].toString())) ==
          1,
      createdAt: map['created_at'] as String? ?? '',
    );
  }

  /// Check if this rule matches a given payee and/or description
  bool matches(String? payee, String? description, int? amount) {
    if (!enabled) return false;

    switch (ruleType) {
      case 'payee_contains':
        if (payee == null) return false;
        return payee.toLowerCase().contains(pattern.toLowerCase());

      case 'description_contains':
        if (description == null) return false;
        return description.toLowerCase().contains(pattern.toLowerCase());

      case 'amount_equals':
        if (amount == null) return false;
        final patternAmount = int.tryParse(pattern);
        return patternAmount != null && amount == patternAmount;

      default:
        return false;
    }
  }

  /// Apply this rule's action
  Map<String, dynamic> applyAction() {
    return {
      'action': action,
      'value': actionValue,
    };
  }
}

/// Built-in dictionary of common payee patterns and their categories
class BuiltInCategories {
  static const Map<String, String> payeePatterns = {
    // Transportation
    'uber': 'Transportation',
    'lyft': 'Transportation',
    'taxi': 'Transportation',
    'bus': 'Transportation',
    'metro': 'Transportation',
    'fuel': 'Transportation',
    'gas station': 'Transportation',

    // Food & Dining
    'restaurant': 'Dining',
    'cafe': 'Dining',
    'coffee': 'Dining',
    'pizza': 'Dining',
    'food': 'Dining',
    'grocery': 'Groceries',
    'supermarket': 'Groceries',

    // Utilities
    'electric': 'Utilities',
    'water': 'Utilities',
    'gas': 'Utilities',
    'internet': 'Utilities',
    'phone': 'Utilities',

    // Entertainment
    'netflix': 'Entertainment',
    'spotify': 'Entertainment',
    'cinema': 'Entertainment',
    'movie': 'Entertainment',
    'game': 'Entertainment',

    // Shopping
    'amazon': 'Shopping',
    'store': 'Shopping',
    'shop': 'Shopping',

    // Income
    'salary': 'Income',
    'payroll': 'Income',
    'wage': 'Income',

    // Housing
    'rent': 'Housing',
    'mortgage': 'Housing',
    'landlord': 'Housing',
  };

  /// Try to auto-categorize based on built-in patterns
  static String? suggestCategory(String? payee, String? description) {
    if (payee != null) {
      final lowerPayee = payee.toLowerCase();
      for (final entry in payeePatterns.entries) {
        if (lowerPayee.contains(entry.key)) {
          return entry.value;
        }
      }
    }

    if (description != null) {
      final lowerDesc = description.toLowerCase();
      for (final entry in payeePatterns.entries) {
        if (lowerDesc.contains(entry.key)) {
          return entry.value;
        }
      }
    }

    return null;
  }
}
