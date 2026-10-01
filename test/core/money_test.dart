import 'package:flutter_test/flutter_test.dart';
import 'package:shop_companion/core/money.dart';

void main() {
  test('parses amounts into integer cents', () {
    expect(Money.tryParse('500'), const Money(50000));
    expect(Money.tryParse('1,250.5'), const Money(125050));
    expect(Money.tryParse('Rs. 1,250.05'), const Money(125005));
    expect(Money.tryParse('ரூ 75'), const Money(7500));
  });

  test('rejects anything that is not a plain amount', () {
    for (final bad in ['', 'abc', '-5', '1.234', '1e5']) {
      expect(Money.tryParse(bad), isNull, reason: bad);
    }
  });

  test('formats with thousands grouping, not lakhs', () {
    expect(const Money(12345678).format(), 'Rs. 123,456.78');
    expect(const Money(-50000).format(showCents: false), '-Rs. 500');
  });

  test('adds without floating point drift', () {
    var total = const Money.zero();
    for (var i = 0; i < 10; i++) {
      total += const Money(10);
    }
    expect(total, const Money(100));
  });
}
