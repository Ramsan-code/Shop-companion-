import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shop_companion/core/rbac/role.dart';
import 'package:shop_companion/features/ledger/data/in_memory_ledger_repository.dart';
import 'package:shop_companion/features/ledger/domain/models.dart';

import '../helpers.dart';

/// NFR (PRD 11): smooth on 500 customers. The list must build lazily, so a
/// screen builds only the rows it shows, however long the list is.
void main() {
  testWidgets(
    '500 customers: only visible rows are built; scrolls to the end',
    (tester) async {
      final app = TestApp(
        ledger: InMemoryLedgerRepository(
          customers: [
            for (var i = 0; i < 500; i++)
              Customer(
                id: 'c$i',
                name: 'Customer ${i.toString().padLeft(3, '0')}',
              ),
          ],
        ),
      );
      await app.pump(tester);
      await app.signInUnlocked(tester, Role.owner);
      await tester.tap(find.text('வாடிக்கையாளர்').last);
      await tester.pumpAndSettle();

      final built = find.textContaining(RegExp(r'^Customer \d{3}$'));
      expect(built.evaluate().length, lessThan(40));

      final list = find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first;
      await tester.scrollUntilVisible(
        find.text('Customer 499'),
        2000,
        scrollable: list,
        maxScrolls: 50,
      );
      expect(find.text('Customer 499'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
