import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shop_companion/core/rbac/role.dart';
import 'package:shop_companion/features/stock/domain/stock.dart';

import '../../helpers.dart';

void main() {
  test('low stock sorts first', () {
    const items = [
      StockItem(id: 'a', name: 'Apple', qty: 9, lowStockAt: 2),
      StockItem(id: 'b', name: 'Banana', qty: 1, lowStockAt: 2),
      StockItem(id: 'c', name: 'Cumin', qty: 0),
    ];
    expect((items.toList()..sort(lowFirstThenName)).map((i) => i.id), [
      'b',
      'a',
      'c',
    ]);
    expect(items[2].isLow, isFalse, reason: 'no alert level set');
  });

  testWidgets('owner adds an item; it lands under "running low"', (
    tester,
  ) async {
    final app = TestApp();
    await app.pump(tester);
    await app.signInUnlocked(tester, Role.owner);
    await tester.tap(find.text('சரக்கு').last);
    await tester.pumpAndSettle();

    expect(find.text('குறைவாக உள்ளது · 1 பொருட்கள் குறைவு'), findsOneWidget);
    await tester.tap(find.text('பொருள் சேர்'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('stock-name')),
      'தேங்காய்',
    );
    await tester.enterText(find.byKey(const ValueKey('stock-qty')), '2');
    await tester.enterText(find.byKey(const ValueKey('stock-low-at')), '5');
    await app.tapInSheet(tester, find.byKey(const ValueKey('stock-save')));

    expect(find.text('குறைவாக உள்ளது · 2 பொருட்கள் குறைவு'), findsOneWidget);
    final items = await app.stock.watchItems('fake-shop').first;
    expect(items.take(2).map((i) => i.name), ['சீனி', 'தேங்காய்']);

    await tester.tap(find.byKey(const ValueKey('stock-minus-rice')));
    await tester.pumpAndSettle();
    expect(find.text('41 kg'), findsOneWidget);
    expect(app.stock.moves.single.reason, StockMoveReason.sold);
  });

  testWidgets('helper changes quantities only', (tester) async {
    final app = TestApp();
    await app.pump(tester);
    await app.signInUnlocked(tester, Role.helper);
    await tester.tap(find.byKey(const ValueKey('helper-stock')));
    await tester.pumpAndSettle();

    expect(find.text('பொருள் சேர்'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('stock-plus-sugar')));
    await tester.pumpAndSettle();
    expect(find.text('4 kg'), findsOneWidget);
    expect(app.stock.moves.single.reason, StockMoveReason.received);

    // Tapping the row doesn't open the edit sheet for a helper.
    await tester.tap(find.text('சீனி'));
    await tester.pumpAndSettle();
    expect(find.text('பொருளைத் திருத்து'), findsNothing);
  });
}
