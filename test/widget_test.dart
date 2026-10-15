import 'package:flutter_test/flutter_test.dart';

import 'package:motostop/main.dart';

void main() {
  test('apunta al sitio de Acoraza CR', () {
    expect(Uri.parse(kHomeUrl).host, kHomeHost);
  });
}
