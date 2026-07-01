import 'package:flutter_test/flutter_test.dart';
import 'package:still_life/core/utils/safe_external_url.dart';

void main() {
  group('safeExternalHttpUri', () {
    test('accepts http and https URLs', () {
      expect(safeExternalHttpUri('https://ebay.com/itm/1'), isNotNull);
      expect(safeExternalHttpUri('http://example.com'), isNotNull);
    });

    test('rejects non-web schemes an LLM could plant in sources[].url', () {
      expect(safeExternalHttpUri('intent://evil#Intent;end'), isNull);
      expect(safeExternalHttpUri('javascript:alert(1)'), isNull);
      expect(safeExternalHttpUri('file:///etc/passwd'), isNull);
      expect(safeExternalHttpUri('tel:+1555'), isNull);
    });

    test('rejects unparseable and empty strings', () {
      expect(safeExternalHttpUri(''), isNull);
      expect(safeExternalHttpUri('::not a url::'), isNull);
    });
  });
}
