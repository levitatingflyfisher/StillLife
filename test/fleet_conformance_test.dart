// The fleet's standards, run as tests that can fail — see
// oh_fleet_conformance's README for what each check enforces. Every
// deliberate divergence from fleet canon is a recorded field here, in one
// place, not scattered through the app.
import 'package:oh_fleet_conformance/oh_fleet_conformance.dart';

void main() => runFleetConformance(const FleetAppConfig(
      appId: 'stilllife',
      // Bundles its own type, so nothing falls back to a web font — a
      // character the bundled families cannot draw is a box on a
      // real phone. C7 sweeps lib/ for any.
      // C8 rides along with the bundled-font set: StillLife builds on
      // OhTheme, whose app-wide iconTheme paints a bare IconButton.filled
      // glyph in the same colour as its own fill. Three of this app's
      // buttons shipped that way — the quantity minus, the chat send, and
      // the inline add — so the guard stays on permanently.
      checks: {
        ...FleetAppConfig.withBundledFonts,
        FleetCheck.c8IconButtons,
      },
      styleTier: StyleTier.full,
      // The exact <uses-permission> surface of the main AndroidManifest —
      // camera/mic for the video walkthrough + barcode/OCR capture,
      // INTERNET for opt-in BYOK AI + LAN sync, notifications/boot/vibrate
      // for loan-due reminders.
      androidPermissions: {
        'android.permission.INTERNET',
        'android.permission.CAMERA',
        'android.permission.RECORD_AUDIO',
        'android.permission.POST_NOTIFICATIONS',
        'android.permission.RECEIVE_BOOT_COMPLETED',
        'android.permission.VIBRATE',
      },
      // C4 v2 — the release MERGED surface: source permissions plus
      // what plugins and the manifest merge inject. Bites when an APK
      // build has left a merged manifest under build/ (dev box).
      mergedAndroidPermissions: {
        'android.permission.ACCESS_NETWORK_STATE',
        'android.permission.CAMERA',
        'android.permission.INTERNET',
        'android.permission.POST_NOTIFICATIONS',
        'android.permission.READ_EXTERNAL_STORAGE',
        'android.permission.RECEIVE_BOOT_COMPLETED',
        'android.permission.RECORD_AUDIO',
        'android.permission.VIBRATE',
        'android.permission.WAKE_LOCK',
        'android.permission.WRITE_EXTERNAL_STORAGE',
        'com.google.android.apps.aicore.service.BIND_SERVICE',
        'com.google.android.c2dm.permission.RECEIVE',
        'com.llcdomain.stilllife.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION',
      },
      // StillLife's restore is an upsert-merge, so the shared package's
      // destructive default confirm copy is overridden (backup_wiring.dart).
      mergeSemanticsRestore: true,
      // StillLife carries a deliberately-tighter analysis_options.yaml.
      analysisOptionsOverrideRecorded: true,
    ));
