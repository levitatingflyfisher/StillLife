import 'package:flutter/material.dart';
import 'package:openhearth_design/openhearth_design.dart';
import 'package:url_launcher/url_launcher.dart';

/// Upgrade-to-Pro call-to-action shown when the user has no bearer.
///
/// Tapping the button opens the Stripe Checkout URL in the external
/// browser. We deliberately don't show a WebView — Apple/Google both
/// require external billing for subscription flows that avoid their
/// in-app-purchase tax, and an external browser also gives the user
/// the full Stripe security indicators.
class UpgradeCta extends StatelessWidget {
  final Uri checkoutUrl;

  const UpgradeCta({super.key, required this.checkoutUrl});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: OhSpacing.insetMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Upgrade to Pro',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: OhSpacing.sm),
            const Text('Unlock cloud photo analysis + AI appraiser. \$6/mo.'),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () =>
                  launchUrl(checkoutUrl, mode: LaunchMode.externalApplication),
              child: const Text('Upgrade'),
            ),
          ],
        ),
      ),
    );
  }
}
