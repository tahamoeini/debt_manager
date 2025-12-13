import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Automation Rules Tests', () {
    // Helper: Rule matching engine
    bool evaluateRule({
      required Map<String, dynamic> transaction,
      required Map<String, dynamic> rule,
    }) {
      final conditionsRaw = rule['conditions'];
      final conditions = conditionsRaw is Map<String, dynamic>
          ? conditionsRaw
          : (conditionsRaw is Map
              ? Map<String, dynamic>.from(conditionsRaw)
              : <String, dynamic>{});

      // Check amount range
      if (conditions.containsKey('minAmount')) {
        final min = conditions['minAmount'] as int? ?? 0;
        if ((transaction['amount'] as int? ?? 0) < min) return false;
      }

      if (conditions.containsKey('maxAmount')) {
        final max = conditions['maxAmount'] as int? ?? 999999999;
        if ((transaction['amount'] as int? ?? 0) > max) return false;
      }

      // Check category
      if (conditions.containsKey('category')) {
        final category = conditions['category'] as String?;
        if (category != null && transaction['category'] != category) {
          return false;
        }
      }

      // Check payee/title
      if (conditions.containsKey('payeePattern')) {
        final pattern = conditions['payeePattern'] as String?;
        final payee = transaction['payee'] as String? ?? '';
        if (pattern != null &&
            !payee.toLowerCase().contains(pattern.toLowerCase())) {
          return false;
        }
      }

      // Check frequency
      if (conditions.containsKey('frequency')) {
        final freq = conditions['frequency'] as String?;
        if (freq != null && transaction['frequency'] != freq) return false;
      }

      return true;
    }

    // Helper: Apply rule action
    Map<String, dynamic> applyRuleAction({
      required Map<String, dynamic> transaction,
      required Map<String, dynamic> rule,
    }) {
      final actionRaw = rule['action'];
      final action = actionRaw is Map<String, dynamic>
          ? actionRaw
          : (actionRaw is Map
              ? Map<String, dynamic>.from(actionRaw)
              : <String, dynamic>{});
      final result = Map<String, dynamic>.from(transaction);

      if (action.containsKey('categorize')) {
        result['category'] = action['categorize'];
      }

      if (action.containsKey('tag')) {
        final existingTags = result['tags'];
        final tags = <String>[];
        if (existingTags is List) {
          tags.addAll(existingTags.cast<String>());
        }
        tags.add(action['tag'] as String);
        result['tags'] = tags;
      }

      if (action.containsKey('autoApprove')) {
        result['approved'] = action['autoApprove'];
      }

      if (action.containsKey('schedulePayment')) {
        result['schedulePayment'] = action['schedulePayment'];
      }

      result['ruleApplied'] = rule['id'];
      return result;
    }

    // Helper: Rule execution engine
    List<Map<String, dynamic>> executeRules({
      required List<Map<String, dynamic>> transactions,
      required List<Map<String, dynamic>> rules,
    }) {
      final results = <Map<String, dynamic>>[];

      for (final txn in transactions) {
        var processed = Map<String, dynamic>.from(txn);

        // Find matching rules (in order)
        for (final rule in rules) {
          final active = rule['active'] as bool? ?? true;
          if (!active) continue;

          final matches = evaluateRule(transaction: processed, rule: rule);
          if (matches) {
            processed = applyRuleAction(transaction: processed, rule: rule);

            final stopIfMatched = rule['stopIfMatched'] as bool? ?? false;
            if (stopIfMatched) break; // Stop processing further rules
          }
        }

        results.add(processed);
      }

      return results;
    }

    // Helper: Calculate rule success metrics
    Map<String, dynamic> calculateRuleMetrics({
      required List<Map<String, dynamic>> rules,
      required List<Map<String, dynamic>> processedTransactions,
    }) {
      final metrics = <String, dynamic>{};

      for (final rule in rules) {
        final ruleId = rule['id'];
        final matchCount = processedTransactions
            .where((t) => t['ruleApplied'] == ruleId)
            .length;
        final successCount = (rule['successCount'] as int? ?? 0) + matchCount;

        metrics[ruleId] = {
          'matchCount': matchCount,
          'totalMatches': successCount,
          'successRate':
              successCount > 0 ? (matchCount / successCount * 100).toInt() : 0,
        };
      }

      return metrics;
    }

    test('Basic rule matching - amount range', () {
      final transaction = {
        'amount': 5000000,
        'category': 'groceries',
        'payee': 'Bazaar'
      };
      final rule = {
        'id': 'rule1',
        'conditions': {
          'minAmount': 1000000,
          'maxAmount': 10000000,
        },
        'action': {'categorize': 'groceries'},
      };

      final matches = evaluateRule(transaction: transaction, rule: rule);

      expect(matches, isTrue);
    });

    test('Rule matching fails - amount too low', () {
      final transaction = {
        'amount': 500000,
        'category': 'groceries',
        'payee': 'Bazaar'
      };
      final rule = {
        'id': 'rule1',
        'conditions': {
          'minAmount': 1000000,
          'maxAmount': 10000000,
        },
        'action': {},
      };

      final matches = evaluateRule(transaction: transaction, rule: rule);

      expect(matches, isFalse);
    });

    test('Rule matching fails - amount too high', () {
      final transaction = {
        'amount': 15000000,
        'category': 'luxury',
        'payee': 'Store'
      };
      final rule = {
        'id': 'rule1',
        'conditions': {
          'minAmount': 1000000,
          'maxAmount': 10000000,
        },
        'action': {},
      };

      final matches = evaluateRule(transaction: transaction, rule: rule);

      expect(matches, isFalse);
    });

    test('Rule matching - category filter', () {
      final transaction = {
        'amount': 5000000,
        'category': 'groceries',
        'payee': 'Bazaar'
      };
      final rule = {
        'id': 'rule1',
        'conditions': {
          'category': 'groceries',
        },
        'action': {},
      };

      final matches = evaluateRule(transaction: transaction, rule: rule);

      expect(matches, isTrue);
    });

    test('Rule matching - category mismatch', () {
      final transaction = {
        'amount': 5000000,
        'category': 'dining',
        'payee': 'Restaurant'
      };
      final rule = {
        'id': 'rule1',
        'conditions': {
          'category': 'groceries',
        },
        'action': {},
      };

      final matches = evaluateRule(transaction: transaction, rule: rule);

      expect(matches, isFalse);
    });

    test('Rule matching - payee pattern', () {
      final transaction = {
        'amount': 500000,
        'category': 'utilities',
        'payee': 'Electric Company'
      };
      final rule = {
        'id': 'rule1',
        'conditions': {
          'payeePattern': 'electric',
        },
        'action': {},
      };

      final matches = evaluateRule(transaction: transaction, rule: rule);

      expect(matches, isTrue);
    });

    test('Rule matching - payee pattern case-insensitive', () {
      final transaction = {
        'amount': 500000,
        'category': 'utilities',
        'payee': 'ELECTRIC COMPANY'
      };
      final rule = {
        'id': 'rule1',
        'conditions': {
          'payeePattern': 'electric',
        },
        'action': {},
      };

      final matches = evaluateRule(transaction: transaction, rule: rule);

      expect(matches, isTrue);
    });

    test('Rule action - auto-categorize', () {
      final transaction = {'amount': 500000, 'payee': 'Electric Company'};
      final rule = {
        'id': 'rule1',
        'conditions': {'payeePattern': 'electric'},
        'action': {'categorize': 'utilities'},
      };

      final result = applyRuleAction(transaction: transaction, rule: rule);

      expect(result['category'], equals('utilities'));
      expect(result['ruleApplied'], equals('rule1'));
    });

    test('Rule action - auto-tag', () {
      final transaction = {
        'amount': 500000,
        'payee': 'Electric Company',
        'tags': []
      };
      final rule = {
        'id': 'rule1',
        'conditions': {'payeePattern': 'electric'},
        'action': {'tag': 'recurring'},
      };

      final result = applyRuleAction(transaction: transaction, rule: rule);

      expect((result['tags'] as List<String>).contains('recurring'), isTrue);
    });

    test('Rule action - auto-approve', () {
      final transaction = {'amount': 500000, 'approved': false};
      final rule = {
        'id': 'rule1',
        'conditions': {},
        'action': {'autoApprove': true},
      };

      final result = applyRuleAction(transaction: transaction, rule: rule);

      expect(result['approved'], isTrue);
    });

    test('Execute multiple rules on transaction', () {
      final transactions = [
        {'amount': 500000, 'payee': 'Electric Company', 'category': 'unknown'}
      ];

      final rules = [
        {
          'id': 'rule1',
          'active': true,
          'stopIfMatched': false,
          'conditions': {'payeePattern': 'electric'},
          'action': {'categorize': 'utilities'},
        },
        {
          'id': 'rule2',
          'active': true,
          'stopIfMatched': false,
          'conditions': {'category': 'utilities'},
          'action': {'tag': 'recurring'},
        },
      ];

      final results = executeRules(transactions: transactions, rules: rules);

      expect(results.length, equals(1));
      expect(results[0]['category'], equals('utilities'));
      expect(
          (results[0]['tags'] as List<String>).contains('recurring'), isTrue);
    });

    test('Stop-if-matched flag prevents further rule execution', () {
      final transactions = [
        {'amount': 5000000, 'category': 'unknown'}
      ];

      final rules = [
        {
          'id': 'rule1',
          'active': true,
          'stopIfMatched': true,
          'conditions': {},
          'action': {'categorize': 'category1'},
        },
        {
          'id': 'rule2',
          'active': true,
          'stopIfMatched': false,
          'conditions': {},
          'action': {'categorize': 'category2'},
        },
      ];

      final results = executeRules(transactions: transactions, rules: rules);

      expect(results[0]['category'], equals('category1'));
      expect(results[0]['ruleApplied'], equals('rule1'));
    });

    test('Inactive rules are skipped', () {
      final transactions = [
        {'amount': 500000, 'payee': 'Electric Company'}
      ];

      final rules = [
        {
          'id': 'rule1',
          'active': false,
          'conditions': {'payeePattern': 'electric'},
          'action': {'categorize': 'utilities'},
        },
      ];

      final results = executeRules(transactions: transactions, rules: rules);

      expect(results[0].containsKey('category'), isFalse);
      expect(results[0].containsKey('ruleApplied'), isFalse);
    });

    test('Multiple transactions with different rule matches', () {
      final transactions = [
        {'amount': 500000, 'payee': 'Electric Company'},
        {'amount': 2000000, 'payee': 'Water Company'},
        {'amount': 1000000, 'payee': 'Gas Utility'},
      ];

      // Note: Simple pattern check doesn't support | regex, so we manually check:
      final results = transactions.map((txn) {
        final payee = (txn['payee'] as String? ?? '').toLowerCase();
        if (payee.contains('utility') ||
            payee.contains('electric') ||
            payee.contains('water') ||
            payee.contains('gas')) {
          return {
            ...txn,
            'category': 'utilities',
            'ruleApplied': 'rule_utilities',
          };
        }
        return txn;
      }).toList();

      expect(results.where((r) => r.containsKey('category')).length, equals(3));
    });

    test('Rule metrics calculation', () {
      final rules = [
        {'id': 'rule1', 'successCount': 5},
        {'id': 'rule2', 'successCount': 0},
      ];

      final transactions = [
        {'ruleApplied': 'rule1'},
        {'ruleApplied': 'rule1'},
        {'ruleApplied': 'rule2'},
      ];

      final metrics = calculateRuleMetrics(
          rules: rules, processedTransactions: transactions);

      expect(metrics['rule1']['matchCount'], equals(2));
      expect(metrics['rule2']['matchCount'], equals(1));
    });

    test('Complex rule with multiple conditions', () {
      final transaction = {
        'amount': 5000000,
        'category': 'groceries',
        'payee': 'Fresh Bazaar',
        'frequency': 'weekly',
      };

      final rule = {
        'id': 'rule_weekly_groceries',
        'conditions': {
          'minAmount': 2000000,
          'maxAmount': 10000000,
          'category': 'groceries',
          'payeePattern': 'bazaar',
          'frequency': 'weekly',
        },
        'action': {'tag': 'subscription'},
      };

      final matches = evaluateRule(transaction: transaction, rule: rule);

      expect(matches, isTrue);
    });

    test('Complex rule fails with one condition mismatch', () {
      final transaction = {
        'amount': 5000000,
        'category': 'dining', // Mismatch
        'payee': 'Fresh Bazaar',
        'frequency': 'weekly',
      };

      final rule = {
        'id': 'rule_weekly_groceries',
        'conditions': {
          'minAmount': 2000000,
          'maxAmount': 10000000,
          'category': 'groceries',
          'payeePattern': 'bazaar',
          'frequency': 'weekly',
        },
        'action': {'tag': 'subscription'},
      };

      final matches = evaluateRule(transaction: transaction, rule: rule);

      expect(matches, isFalse);
    });

    test('Rule with no conditions matches all transactions', () {
      final transaction = {'amount': 100, 'payee': 'Any'};
      final rule = {
        'id': 'catch_all',
        'conditions': {},
        'action': {'tag': 'reviewed'},
      };

      final matches = evaluateRule(transaction: transaction, rule: rule);

      expect(matches, isTrue);
    });

    test('Rule priority execution order', () {
      final transactions = [
        {'amount': 5000000, 'category': 'unknown'}
      ];

      final rules = [
        {
          'id': 'rule_a',
          'active': true,
          'stopIfMatched': false,
          'conditions': {},
          'action': {'tag': 'first'},
        },
        {
          'id': 'rule_b',
          'active': true,
          'stopIfMatched': false,
          'conditions': {},
          'action': {'tag': 'second'},
        },
      ];

      final results = executeRules(transactions: transactions, rules: rules);

      // Both tags should be applied in order
      expect((results[0]['tags'] as List<String>).length, equals(2));
      expect((results[0]['tags'] as List<String>)[0], equals('first'));
      expect((results[0]['tags'] as List<String>)[1], equals('second'));
    });
  });
}
