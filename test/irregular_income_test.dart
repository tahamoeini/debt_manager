import 'package:flutter_test/flutter_test.dart';
import 'package:debt_manager/features/budget/irregular_income_service.dart';

void main() {
  test('IrregularIncomeService returns non-negative averages and suggestions',
      () async {
    final svc = IrregularIncomeService();
    final avg = await svc.computeRollingAverage(3);
    expect(avg >= 0, true);

    final suggestion =
        await svc.suggestSafeExtra(months: 3, essentialBudget: 0);
    expect(suggestion >= 0, true);
  });
}
