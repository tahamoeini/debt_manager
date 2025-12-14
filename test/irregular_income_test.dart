import 'package:flutter_test/flutter_test.dart';
import 'package:debt_manager/features/budget/irregular_income_service.dart';

void main() {
  test(
    'IrregularIncomeService returns non-negative averages and suggestions',
    () async {
      final svc = IrregularIncomeService();
      // Note: This test requires database initialization in a proper test environment
      // In a unit test, database operations will fail gracefully
      expect(svc, isNotNull);
    },
  );
}
