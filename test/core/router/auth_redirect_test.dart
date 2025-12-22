import 'package:debt_manager/core/router/app_router.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('lock redirect helper', () {
    test('app lock disabled never redirects to lock', () {
      expect(
        lockRedirect(appLockEnabled: false, unlocked: false, location: '/'),
        isNull,
      );
      expect(
        lockRedirect(appLockEnabled: false, unlocked: false, location: '/lock'),
        '/',
      );
    });

    test('app lock enabled but locked redirects to /lock', () {
      expect(
        lockRedirect(appLockEnabled: true, unlocked: false, location: '/'),
        '/lock',
      );
      expect(
        lockRedirect(appLockEnabled: true, unlocked: false, location: '/lock'),
        isNull,
      );
    });

    test('app lock enabled and unlocked stays or leaves lock', () {
      expect(
        lockRedirect(appLockEnabled: true, unlocked: true, location: '/'),
        isNull,
      );
      expect(
        lockRedirect(appLockEnabled: true, unlocked: true, location: '/lock'),
        '/',
      );
    });
  });
}
