// TODO: add Int16→Float32 tests

import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:amitabha/utils.dart';

/// 小工具：把 Int16 陣列轉成對應位元組序列（小端）
Uint8List _i16ToBytesLE(List<int> xs) {
  final b = ByteData(xs.length * 2);
  for (var i = 0; i < xs.length; i++) {
    b.setInt16(i * 2, xs[i], Endian.little);
  }
  return b.buffer.asUint8List();
}

/// 小工具：大端
Uint8List _i16ToBytesBE(List<int> xs) {
  final b = ByteData(xs.length * 2);
  for (var i = 0; i < xs.length; i++) {
    b.setInt16(i * 2, xs[i], Endian.big);
  }
  return b.buffer.asUint8List();
}

void main() {
  group('convertBytesToFloat32', () {
    test('邊界值：-32768、0、32767（小端）', () {
      final bytes = _i16ToBytesLE([-32768, 0, 32767]);
      final f = convertBytesToFloat32(bytes);
      expect(f.length, 3);
      expect(f[0], closeTo(-1.0, 1e-7));                // -32768 / 32768
      expect(f[1], 0.0);
      expect(f[2], closeTo(32767 / 32768.0, 1e-7));     // ≈ 0.9999695
    });

    test('奇數長度：多出 1 byte 應被忽略且不拋錯', () {
      final even = _i16ToBytesLE([1, 2, 3]);            // 6 bytes
      final odd = Uint8List.fromList([...even, 0xFF]);  // 7 bytes
      final f = convertBytesToFloat32(odd);
      expect(f.length, 3);                               // floor(7/2)
    });

    test('大端序解析', () {
      final bytes = _i16ToBytesBE([-32768, 32767]);
      final f = convertBytesToFloat32(bytes, Endian.big);
      expect(f.length, 2);
      expect(f[0], closeTo(-1.0, 1e-7));
      expect(f[1], closeTo(32767 / 32768.0, 1e-7));
    });

    test('子片段（sublist）位移正確', () {
      // 建一個較大的 buffer，取其中一段作為子片段
      final all = _i16ToBytesLE([111, -222, 333, -444, 555]); // 10 bytes
      final slice = Uint8List.sublistView(all, 2, 8); // 對應 [-222, 333, -444]
      final f = convertBytesToFloat32(slice);
      expect(f.length, 3);
      expect(f[0], closeTo(-222 / 32768.0, 1e-7));
      expect(f[1], closeTo( 333 / 32768.0, 1e-7));
      expect(f[2], closeTo(-444 / 32768.0, 1e-7));
    });
  });
}
