#!/usr/bin/env python3
"""設定頁葉片標題座標抽取。

從 design/anchors_*.png（帶紅色 X 標記的校準圖）抓出各標題的中心點，
換算成 settings_screen.dart 使用的畫布座標。

校準圖必須與 assets/images/bg_bodhi_leaf_tablet_*.png 同尺寸；
校準圖不列入 pubspec.yaml，不會打包進 App。

除了印在終端機，也會把結果寫進 design/anchors.json，供
test/settings_leaf_anchor_test.dart 比對 leaf_layout.dart 的座標。
改完校準圖跑這支腳本，測試若失敗就代表座標還沒同步更新。

用法：python3 tool/extract_anchors.py
"""
import json
import sys

import numpy as np
from PIL import Image

OUT_JSON = 'design/anchors.json'

# (校準圖, 畫布寬, 畫布高, 標籤, SettingsCanvas 的 enum 名稱)
# 最後一欄必須與 lib/features/settings/leaf_layout.dart 的 SettingsCanvas
# 完全一致，測試靠它把每張校準圖對應到正確的畫布。
TARGETS = [
    ('design/anchors_tablet_portrait.png', 1080, 1440, '平板直向 3:4',
     'tabletPortrait'),
    ('design/anchors_tablet_landscape.png', 1440, 1080, '平板橫向 4:3',
     'tabletLandscape'),
]

# 預期的標記數量 = 設定頁的葉片數。
EXPECTED_ANCHORS = 6


def red_mask(a):
    """紅色標記：R 明顯高於 G/B。底圖為米黃色，不會誤判。"""
    r, g, b = a[..., 0], a[..., 1], a[..., 2]
    return (r > 150) & (r.astype(int) - g > 60) & (r.astype(int) - b > 60)


def blobs(mask, min_px):
    h, w = mask.shape
    seen = np.zeros_like(mask)
    out = []
    for y in range(h):
        for x in range(w):
            if mask[y, x] and not seen[y, x]:
                st, pts = [(y, x)], []
                seen[y, x] = True
                while st:
                    cy, cx = st.pop()
                    pts.append((cy, cx))
                    for dy in (-1, 0, 1):
                        for dx in (-1, 0, 1):
                            ny, nx = cy + dy, cx + dx
                            if 0 <= ny < h and 0 <= nx < w and mask[ny, nx] and not seen[ny, nx]:
                                seen[ny, nx] = True
                                st.append((ny, nx))
                if len(pts) >= min_px:
                    ys = [p[0] for p in pts]
                    xs = [p[1] for p in pts]
                    out.append((sum(xs) / len(xs), sum(ys) / len(ys), len(pts)))
    return out


def run(path, cw, ch, label):
    im = Image.open(path).convert('RGB')
    W, H = im.size
    a = np.asarray(im)
    m = red_mask(a)
    found = blobs(m, min_px=200)
    sx, sy = cw / W, ch / H
    pts = [(cx * sx, cy * sy, n) for cx, cy, n in found]
    # 由上而下、左而右排序，方便對照圖片
    pts.sort(key=lambda p: (round(p[1] / 100), p[0]))
    print(f'\n=== {label} — 原圖 {W}x{H} → 畫布 {cw}x{ch} — 找到 {len(pts)} 個標記 ===')
    for i, (cx, cy, n) in enumerate(pts, 1):
        print(f'  {i}. 中心 ({cx:7.1f}, {cy:7.1f})   標記面積 {n} px')
    if len(pts) != EXPECTED_ANCHORS:
        print(f'  ⚠ 預期 {EXPECTED_ANCHORS} 個，實際 {len(pts)} 個'
              ' —— 請檢查標記顏色或大小')
    return {
        'source': path,
        'sourceSize': [W, H],
        'canvas': [cw, ch],
        # 只寫中心點；標記面積僅供人工核對，不進 JSON。
        'anchors': [[round(cx, 2), round(cy, 2)] for cx, cy, _ in pts],
    }


if __name__ == '__main__':
    result = {}
    for path, cw, ch, label, canvas_key in TARGETS:
        try:
            result[canvas_key] = run(path, cw, ch, label)
        except FileNotFoundError:
            print(f'找不到 {path}', file=sys.stderr)

    if len(result) != len(TARGETS):
        print('\n有校準圖讀取失敗，未寫出 JSON（避免產生不完整的檔案）。',
              file=sys.stderr)
        sys.exit(1)

    with open(OUT_JSON, 'w', encoding='utf-8') as fh:
        json.dump(result, fh, ensure_ascii=False, indent=2)
        fh.write('\n')
    print(f'\n已寫出 {OUT_JSON}')
