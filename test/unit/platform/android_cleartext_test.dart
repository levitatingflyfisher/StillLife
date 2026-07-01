import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AndroidManifest permits cleartext HTTP — the LAN features '
      '(Ollama tier, app-layer-encrypted LAN sync) are plain http and '
      'Android blocks non-localhost cleartext by default', () {
    final manifest =
        File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    expect(manifest, contains('android:usesCleartextTraffic="true"'),
        reason: 'without this, the advertised "phone talks to my '
            'desktop\'s Ollama over LAN" flow throws "Insecure HTTP is '
            'not allowed by platform" on every release APK');
  });
}
