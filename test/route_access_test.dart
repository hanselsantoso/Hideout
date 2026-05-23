import 'package:beytourney_hideout/core/auth/route_access.dart';
import 'package:beytourney_hideout/data/models/app_user.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('player routes stay limited to player menus', () {
    final user = _user(role: 'player');

    expect(defaultRouteFor(user), '/dashboard');
    expect(hasRouteAccess(user, playerAccess), isTrue);
    expect(hasRouteAccess(user, judgeAccess), isFalse);
    expect(hasRouteAccess(user, communityManagerAccess), isFalse);
    expect(hasRouteAccess(user, superAdminAccess), isFalse);
  });

  test('judge can use player and judge menus only', () {
    final user = _user(role: 'judge', roles: {'judge'});

    expect(defaultRouteFor(user), '/dashboard');
    expect(hasRouteAccess(user, playerAccess), isTrue);
    expect(hasRouteAccess(user, judgeAccess), isTrue);
    expect(hasRouteAccess(user, communityManagerAccess), isFalse);
    expect(hasRouteAccess(user, superAdminAccess), isFalse);
  });

  test('community lead can use player and community menus only', () {
    final user = _user(
      role: 'community_admin',
      roles: {'community_admin', 'player'},
    );

    expect(defaultRouteFor(user), '/dashboard');
    expect(hasRouteAccess(user, playerAccess), isTrue);
    expect(hasRouteAccess(user, judgeAccess), isFalse);
    expect(hasRouteAccess(user, communityManagerAccess), isTrue);
    expect(hasRouteAccess(user, superAdminAccess), isFalse);
  });

  test('super admin opens platform menus only', () {
    final user = _user(role: 'super_admin', roles: {'super_admin'});

    expect(defaultRouteFor(user), '/super-admin/reports');
    expect(hasRouteAccess(user, playerAccess), isFalse);
    expect(hasRouteAccess(user, judgeAccess), isFalse);
    expect(hasRouteAccess(user, communityManagerAccess), isTrue);
    expect(hasRouteAccess(user, superAdminAccess), isTrue);
  });
}

AppUser _user({
  required String role,
  Set<String> roles = const {},
}) {
  return AppUser(
    uid: 'test-$role',
    displayName: 'Test $role',
    email: '$role@example.com',
    role: role,
    roles: roles,
    eloRating: 1000,
    isActive: true,
    isQrActivated: true,
  );
}
