//amitabha/lib/storage/buffered_hits.dart
import 'dart:async';

class BufferedHits {
  final Duration flushEvery;
  final int maxBuffer;
  final Future<void> Function(List<DateTime>) onFlush;
  final _buf = <DateTime>[];
  Timer? _t;

  BufferedHits({
    required this.flushEvery,
    required this.maxBuffer,
    required this.onFlush,
  });

  void add(DateTime t) {
    _buf.add(t);
    if (_buf.length >= maxBuffer) { _flush(); }
    else { _t ??= Timer(flushEvery, _flush); }
  }

  Future<void> _flush() async {
    _t?.cancel(); _t = null;
    if (_buf.isEmpty) return;
    final copy = List<DateTime>.from(_buf);
    _buf.clear();
    await onFlush(copy);
  }

  Future<void> close() => _flush();
}