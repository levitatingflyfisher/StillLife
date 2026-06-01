import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:still_life/features/dashboard/presentation/widgets/stat_card.dart';

import 'visual_golden_helper.dart';

const _narrowSizes = <String, Size>{
  'phone': Size(360, 740),
  'narrow': Size(320, 740),
};

void main() {
  testWidgets('StatCard short value golden sweep', (tester) async {
    await goldenAtSizes(
      tester,
      name: 'stat_card_short',
      home: const Scaffold(
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(8),
            child: StatCard(
              title: 'Total Items',
              value: '42',
              icon: Icons.inventory_2_outlined,
              color: Colors.blue,
            ),
          ),
        ),
      ),
      sizes: _narrowSizes,
      textScales: const <double>[1.0, 3.0],
    );
  });

  testWidgets('StatCard long title golden sweep', (tester) async {
    await goldenAtSizes(
      tester,
      name: 'stat_card_long',
      home: const Scaffold(
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(8),
            child: StatCard(
              title: 'Estimated Total Replacement Value',
              value: r'$128,450.00',
              icon: Icons.attach_money_outlined,
              color: Colors.green,
            ),
          ),
        ),
      ),
      sizes: _narrowSizes,
      textScales: const <double>[1.0, 3.0],
    );
  });
}
