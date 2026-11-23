import 'package:becoming1/models/achievement.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('dates are formatted like 20 Nov 2026', () {
    expect(formatDate(DateTime(2026, 11, 20)), '20 Nov 2026');
  });

  test('unknown categories fall back to a default style', () {
    expect(categoryStyle('Something else'), isNotNull);
  });
}
