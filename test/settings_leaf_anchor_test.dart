// test/settings_leaf_anchor_test.dart
import 'dart:convert';
import 'dart:io';
import 'package:amitabha/features/settings/presentation/leaf_layout.dart';
import 'package:flutter_test/flutter_test.dart';

const _tolerance = 1.0;

const _calibratedCanvases = {
  'tabletPortrait': SettingsCanvas.tabletPortrait,
  'tabletLandscape': SettingsCanvas.tabletLandscape,
};

void main() {
  late Map<String, dynamic> fixture;

  setUpAll(() {
    final file = File('design/anchors.json');
    if (!file.existsSync()) {
      fail(
        '找不到 design/anchors.json。'
        '請先執行：python3 tool/extract_anchors.py',
      );
    }
    fixture = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  });

  test('校準圖涵蓋所有平板畫布', () {
    expect(
      fixture.keys.toSet(),
      _calibratedCanvases.keys.toSet(),
      reason:
          'anchors.json 的畫布與測試預期的不一致，'
          '請確認 tool/extract_anchors.py 的 TARGETS',
    );
  });

  for (final entry in _calibratedCanvases.entries) {
    final key = entry.key;
    final canvas = entry.value;

    group(key, () {
      test('校準圖的畫布尺寸與 settingsCanvasSize 相符', () {
        final dims = (fixture[key]['canvas'] as List).cast<num>();
        final expected = settingsCanvasSize[canvas]!;
        expect(
          [dims[0].toDouble(), dims[1].toDouble()],
          [expected.width, expected.height],
          reason: '$key 的畫布尺寸已變更，校準圖需要重畫',
        );
      });

      test('每片葉子的中心對上一個紅色標記，且一一對應', () {
        final anchors = (fixture[key]['anchors'] as List)
            .map((p) => ((p as List)[0] as num).toDouble())
            .toList();
        final anchorsY = (fixture[key]['anchors'] as List)
            .map((p) => ((p as List)[1] as num).toDouble())
            .toList();

        expect(
          anchors.length,
          SettingsLeaf.values.length,
          reason: '校準圖上的標記數量與葉片數不符',
        );

        final claimedBy = <int, SettingsLeaf>{};

        for (final leaf in SettingsLeaf.values) {
          final rect = settingsLeafLayout[leaf]!.forCanvas(canvas);

          var bestIndex = -1;
          var bestDistance = double.infinity;
          for (var i = 0; i < anchors.length; i++) {
            final dx = rect.centerX - anchors[i];
            final dy = rect.centerY - anchorsY[i];
            final distance = dx * dx + dy * dy;
            if (distance < bestDistance) {
              bestDistance = distance;
              bestIndex = i;
            }
          }

          final dx = (rect.centerX - anchors[bestIndex]).abs();
          final dy = (rect.centerY - anchorsY[bestIndex]).abs();

          expect(
            dx <= _tolerance && dy <= _tolerance,
            isTrue,
            reason:
                '$key 的 ${leaf.name} 中心是 (${rect.centerX}, ${rect.centerY})，'
                '最近的標記在 (${anchors[bestIndex]}, ${anchorsY[bestIndex]})，'
                '相差 (${dx.toStringAsFixed(2)}, ${dy.toStringAsFixed(2)})。'
                '若校準圖剛改過，請依 tool/extract_anchors.py 的輸出更新 '
                'leaf_layout.dart',
          );

          final previous = claimedBy[bestIndex];
          expect(
            previous,
            isNull,
            reason:
                '$key 的 ${leaf.name} 與 ${previous?.name} '
                '對到了同一個標記，表示有葉子被放到別片的位置上',
          );
          claimedBy[bestIndex] = leaf;
        }

        expect(claimedBy.length, anchors.length, reason: '$key 有標記沒有對應的葉子');
      });
    });
  }
}
