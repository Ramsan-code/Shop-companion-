import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shop_companion/core/rbac/permission.dart';
import 'package:shop_companion/core/rbac/role.dart';

void main() {
  test('Dart roles match seed/roles.json used by Security Rules', () {
    final seed = jsonDecode(
      File('seed/roles.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    for (final role in Role.values) {
      final entry = seed[role.name] as Map<String, dynamic>;
      final wire = (entry['permissions'] as List<dynamic>).cast<String>();
      expect(
        role.permissions.map((p) => p.wireName).toSet(),
        wire.toSet(),
        reason: role.name,
      );
      for (final name in wire) {
        expect(Permission.fromWire(name), isNotNull, reason: name);
      }
    }
  });

  test('PRD 6 spot checks', () {
    expect(Role.helper.can(Permission.profitRead), isFalse);
    expect(Role.helper.can(Permission.scoreRead), isFalse);
    expect(Role.helper.can(Permission.ledgerCreate), isTrue);
    expect(Role.partner.can(Permission.auditRead), isFalse);
    expect(Role.partner.can(Permission.memberInvite), isFalse);
    expect(Role.owner.can(Permission.memberInvite), isTrue);
    expect(Role.admin.permissions, isEmpty);
  });
}
