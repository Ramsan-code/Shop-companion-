import 'package:flutter_test/flutter_test.dart';
import 'package:shop_companion/core/failure.dart';
import 'package:shop_companion/core/rbac/role.dart';
import 'package:shop_companion/features/settings/data/members_repositories.dart';
import 'package:shop_companion/features/settings/domain/members_repository.dart';
import 'package:shop_companion/features/settings/presentation/members_cubit.dart';

void main() {
  const owner = Member(uid: 'o', phone: '+94770000000', role: Role.owner);
  const helper = Member(uid: 'h', phone: '+94770000003', role: Role.helper);

  test('loads members, invites and removes', () async {
    final cubit = MembersCubit(
      FakeMembersRepository(members: [owner, helper]),
      'shop',
    );
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.loading, isFalse);
    expect(cubit.state.members, [owner, helper]);

    final link = await cubit.invite('077 100 0002', Role.partner);
    expect(link?.link, contains('/invite/'));

    await cubit.remove('h');
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.members, [owner]);
    await cubit.close();
  });

  test('surfaces failures: bad phone, removing the owner', () async {
    final cubit = MembersCubit(FakeMembersRepository(members: [owner]), 'shop');
    expect(await cubit.invite('12', Role.helper), isNull);
    expect(cubit.state.failure, isA<ValidationFailure>());
    await cubit.remove('o');
    expect(cubit.state.failure, isA<PermissionFailure>());
    await cubit.close();
  });
}
