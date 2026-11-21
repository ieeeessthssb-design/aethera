import 'package:flutter_test/flutter_test.dart';
import 'package:aethera/core/i18n.dart';

void main() {
  test('dictionary has crops and governorates', () {
    expect(kCrops, isNotEmpty);
    expect(kGovernorates, isNotEmpty);
  });
}
