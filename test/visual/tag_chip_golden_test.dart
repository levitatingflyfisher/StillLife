import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:still_life/features/inventory/domain/entities/tag.dart';
import 'package:still_life/features/inventory/presentation/widgets/tag_chip.dart';

import 'visual_golden_helper.dart';

Tag _tag({
  String id = 'tag-1',
  String name = 'Electronics',
  int? color = 0xFF2196F3,
}) => Tag(
  id: id,
  name: name,
  color: color,
  createdAt: DateTime(2025),
  modifiedAt: DateTime(2025),
);

const _narrowSizes = <String, Size>{
  'phone': Size(360, 740),
  'narrow': Size(320, 740),
};

void main() {
  testWidgets('TagChip variants golden sweep', (tester) async {
    await goldenAtSizes(
      tester,
      name: 'tag_chip',
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                TagChip(tag: _tag(), onTap: () {}),
                TagChip(
                  tag: _tag(id: 'tag-2', name: 'Kitchen', color: 0xFFFF9800),
                  onTap: () {},
                ),
                TagChip(
                  tag: _tag(id: 'tag-3', name: 'No Color', color: null),
                  onTap: () {},
                ),
                TagChip(
                  tag: _tag(id: 'tag-4', name: 'Deletable', color: 0xFF4CAF50),
                  onTap: () {},
                  onDeleted: () {},
                ),
                TagChip(
                  tag: _tag(
                    id: 'tag-5',
                    name: 'Long Tag Name That Could Wrap',
                    color: 0xFF9C27B0,
                  ),
                  onTap: () {},
                ),
              ],
            ),
          ),
        ),
      ),
      sizes: _narrowSizes,
      textScales: const <double>[1.0, 3.0],
    );
  });
}
