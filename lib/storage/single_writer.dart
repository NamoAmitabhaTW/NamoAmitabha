class SingleWriter {
  Future<void> _last = Future.value();

  Future<T> run<T>(Future<T> Function() job) {
    final next = _last.then((_) => job());
    _last = next.then((_) {}, onError: (_) {});
    return next;
  }
}

final singleWriter = SingleWriter();