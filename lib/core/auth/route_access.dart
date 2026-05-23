import '../../data/models/app_user.dart';

const playerAccess = {'player', 'judge', 'community_admin'};
const judgeAccess = {'judge'};
const communityManagerAccess = {'community_admin', 'super_admin'};
const superAdminAccess = {'super_admin'};
const anySignedInAccess = {
  'player',
  'judge',
  'community_admin',
  'super_admin',
};

bool hasRouteAccess(AppUser user, Set<String> allowedRoles) {
  final capabilities = capabilitiesFor(user);
  return allowedRoles.any(capabilities.contains);
}

Set<String> capabilitiesFor(AppUser? user) {
  if (user == null) return {'player'};
  final capabilities = user.capabilities;
  if (capabilities.contains('super_admin')) {
    return {'super_admin'};
  }
  return {'player', ...capabilities};
}

String defaultRouteFor(AppUser user) {
  final capabilities = capabilitiesFor(user);
  if (capabilities.contains('super_admin')) return '/super-admin/reports';
  return '/dashboard';
}

String roleLabel(String role) {
  return switch (role) {
    'super_admin' => 'super admin',
    'community_admin' => 'community admin',
    'judge' => 'judge',
    _ => 'player',
  };
}
