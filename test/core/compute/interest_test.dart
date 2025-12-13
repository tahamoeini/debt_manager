import 'package:flutter_test/flutter_test.dart';
import 'dart:math';

void main() {
  group('Interest Calculation Tests', () {
    // Helper function: calculate compound interest
    double calculateCompoundInterest({
      required double principal,
      required double annualRate,
      required int compoundingFrequency,
      required int years,
    }) {
      // n = number of times interest is compounded per year
      // t = time in years
      // A = P(1 + r/n)^(nt)
      final n = compoundingFrequency;
      final r = annualRate / 100.0;
      final t = years;
      return principal * pow(1 + r / n, n * t).toDouble();
    }

    // Helper function: calculate daily accrual
    double calculateDailyAccrual({
      required double principal,
      required double annualRate,
      required int days,
    }) {
      // Simple daily accrual: P * (r / 365) * days
      final dailyRate = (annualRate / 100.0) / 365.0;
      return principal * dailyRate * days;
    }

    // Helper function: calculate effective annual rate
    double calculateEffectiveAnnualRate({
      required double nominalRate,
      required int compoundingFrequency,
    }) {
      // EAR = (1 + r/n)^n - 1
      final r = nominalRate / 100.0;
      final n = compoundingFrequency;
      return (pow(1 + r / n, n).toDouble() - 1) * 100.0;
    }

    test('Simple compound interest - annual compounding', () {
      // Principal: 1,000,000 Toman, Rate: 15% per year, Years: 1
      final result = calculateCompoundInterest(
        principal: 1000000,
        annualRate: 15.0,
        compoundingFrequency: 1,
        years: 1,
      );

      expect(result, closeTo(1150000, 100)); // 1,000,000 * 1.15
    });

    test('Compound interest - monthly compounding', () {
      // Principal: 1,000,000 Toman, Rate: 12% per year, Years: 1
      final result = calculateCompoundInterest(
        principal: 1000000,
        annualRate: 12.0,
        compoundingFrequency: 12,
        years: 1,
      );

      // A = 1,000,000 * (1 + 0.12/12)^12 = 1,000,000 * (1.01)^12 ≈ 1,126,825
      expect(result, closeTo(1126825, 200));
    });

    test('Compound interest - quarterly compounding', () {
      // Principal: 2,000,000 Toman, Rate: 8% per year, Years: 2
      final result = calculateCompoundInterest(
        principal: 2000000,
        annualRate: 8.0,
        compoundingFrequency: 4,
        years: 2,
      );

      // A = 2,000,000 * (1 + 0.08/4)^(4*2) = 2,000,000 * (1.02)^8 ≈ 2,343,311
      expect(result, closeTo(2343311, 300));
    });

    test('Compound interest - daily compounding', () {
      // Principal: 500,000 Toman, Rate: 10% per year, Years: 1
      final result = calculateCompoundInterest(
        principal: 500000,
        annualRate: 10.0,
        compoundingFrequency: 365,
        years: 1,
      );

      // Daily compounding gives slightly higher effective rate
      expect(result, greaterThan(550000));
      expect(result, lessThan(555000));
    });

    test('Daily accrual - exact calculation', () {
      // Principal: 10,000,000 Toman, Rate: 15% per year, Days: 30
      final accrual = calculateDailyAccrual(
        principal: 10000000,
        annualRate: 15.0,
        days: 30,
      );

      // Daily rate = 15% / 365 = 0.0411%
      // Accrual = 10,000,000 * 0.000411 * 30 ≈ 123,288
      expect(accrual, closeTo(123288, 500));
    });

    test('Daily accrual - one year (365 days)', () {
      // Principal: 10,000,000 Toman, Rate: 15% per year, Days: 365
      final accrual = calculateDailyAccrual(
        principal: 10000000,
        annualRate: 15.0,
        days: 365,
      );

      // Should equal 15% of principal for daily simple accrual
      expect(accrual, closeTo(1500000, 5000));
    });

    test('Daily accrual - varying principals', () {
      final smallPrincipal = calculateDailyAccrual(
        principal: 1000000.0,
        annualRate: 12.0,
        days: 30,
      );

      final largePrincipal = calculateDailyAccrual(
        principal: 10000000.0,
        annualRate: 12.0,
        days: 30,
      );

      // Larger principal should accrue 10x more interest
      expect(largePrincipal / smallPrincipal, closeTo(10.0, 0.01));
    });

    test('Daily accrual - varying rates', () {
      final lowRate = calculateDailyAccrual(
        principal: 1000000.0,
        annualRate: 5.0,
        days: 30,
      );

      final highRate = calculateDailyAccrual(
        principal: 1000000.0,
        annualRate: 20.0,
        days: 30,
      );

      // 20% rate should accrue 4x more than 5% rate
      expect(highRate / lowRate, closeTo(4.0, 0.01));
    });

    test('Effective annual rate - various frequencies', () {
      const nominalRate = 12.0;

      final annualEAR = calculateEffectiveAnnualRate(
        nominalRate: nominalRate,
        compoundingFrequency: 1,
      );

      final monthlyEAR = calculateEffectiveAnnualRate(
        nominalRate: nominalRate,
        compoundingFrequency: 12,
      );

      final dailyEAR = calculateEffectiveAnnualRate(
        nominalRate: nominalRate,
        compoundingFrequency: 365,
      );

      // Annual should be lowest, daily should be highest
      expect(annualEAR, closeTo(nominalRate, 0.0001));
      expect(monthlyEAR, greaterThan(annualEAR));
      expect(dailyEAR, greaterThan(monthlyEAR));
    });

    test('Interest accrual on declining balance (payment reduction)', () {
      // Simulate a loan with monthly payments
      double balance = 10000000;
      double totalInterest = 0;
      const annualRate = 12.0;
      const monthlyPayment = 500000;

      for (var month = 0; month < 24; month++) {
        // Accrue monthly interest on current balance
        final monthlyInterest = balance * (annualRate / 100.0 / 12);
        totalInterest += monthlyInterest;
        balance += monthlyInterest;

        // Make payment
        balance -= monthlyPayment;
        if (balance <= 0) break;
      }

      // Should have paid significant interest over 24 months
      expect(totalInterest, greaterThan(500000));
      // Balance can be slightly negative due to final payment overshoot
      expect(balance.abs(), lessThan(monthlyPayment));
    });

    test('Compound interest never decreases with longer periods', () {
      const principal = 1000000.0;
      const rate = 10.0;

      final year1 = calculateCompoundInterest(
        principal: principal,
        annualRate: rate,
        compoundingFrequency: 12,
        years: 1,
      );

      final year2 = calculateCompoundInterest(
        principal: principal,
        annualRate: rate,
        compoundingFrequency: 12,
        years: 2,
      );

      final year3 = calculateCompoundInterest(
        principal: principal,
        annualRate: rate,
        compoundingFrequency: 12,
        years: 3,
      );

      expect(year2, greaterThan(year1));
      expect(year3, greaterThan(year2));
    });

    test('Edge case - zero interest rate', () {
      final result = calculateCompoundInterest(
        principal: 1000000.0,
        annualRate: 0.0,
        compoundingFrequency: 12,
        years: 5,
      );

      expect(result, equals(1000000.0)); // No growth with 0% rate
    });

    test('Edge case - very small principal', () {
      final accrual = calculateDailyAccrual(
        principal: 100.0,
        annualRate: 15.0,
        days: 30,
      );

      expect(accrual, greaterThan(0));
      expect(accrual, lessThan(1000));
    });

    test('Edge case - very high interest rate (hyperinflation scenario)', () {
      final result = calculateCompoundInterest(
        principal: 1000000.0,
        annualRate: 150.0, // 150% annual rate
        compoundingFrequency: 12,
        years: 1,
      );

      // Should still calculate without overflow
      expect(result.isFinite, isTrue);
      expect(result, greaterThan(1000000.0));
    });

    test('Interest calculation consistency across methods', () {
      // Compare daily simple accrual with compound interest over one year
      const principal = 1000000.0;
      const rate = 10.0;
      const days = 365;

      final dailyAccrual = calculateDailyAccrual(
        principal: principal,
        annualRate: rate,
        days: days,
      );

      final compound = calculateCompoundInterest(
        principal: principal,
        annualRate: rate,
        compoundingFrequency: 365,
        years: 1,
      );

      // Compound should be slightly higher than simple daily accrual
      expect(compound, greaterThan(principal + dailyAccrual * 0.9));
    });
  });
}
