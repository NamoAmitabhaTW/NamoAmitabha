import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa_onnx;
import 'download_model.dart';
import 'online_model.dart';
import 'utils.dart';
import 'kws_keywords.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart' as path_provider;

class StreamingKwsScreen extends StatefulWidget {
  const StreamingKwsScreen({super.key});
  @override
  State<StreamingKwsScreen> createState() => _StreamingKwsScreenState();
}

class _StreamingKwsScreenState extends State<StreamingKwsScreen> {
  final _log = ValueNotifier<String>('');
  late final AudioRecorder _rec;
  sherpa_onnx.KeywordSpotter? _kws;
  sherpa_onnx.OnlineStream? _stream;
  StreamSubscription<RecordState>? _sub;
  RecordState _state = RecordState.stop;
  final Map<String, int> _hitCounts = {};
  final Map<String, DateTime> _lastHitAt = {};
  int _kwsHitCount = 0;
  DateTime? _kwsLastHitAt;
  String _fmtTs(DateTime? t) => t == null
      ? '—'
      : t.toLocal().toIso8601String().replaceFirst('T', ' ').split('.').first;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DownloadModel>().useKws(
        'sherpa-onnx-kws-zipformer-wenetspeech-3.3M-2024-01-01-mobile',
      );
    });
    _rec = AudioRecorder();
    _sub = _rec.onStateChanged().listen((s) => setState(() => _state = s));
  }

  Future<void> _start() async {
    try {
      final dm = context.read<DownloadModel>();
      final modelName = dm.modelName;

      if (await needsDownload(modelName)) {
        await downloadModelAndUnZip(context, modelName);
        return;
      }
      if (await needsUnZip(modelName)) {
        await unzipModelFile(context, modelName);
        return;
      }

      final appDoc = await path_provider.getApplicationDocumentsDirectory();
      final root = path.join(appDoc.path, modelName);
      final customKeywordsPath = await writeCustomKeywords(root);

      sherpa_onnx.initBindings();
      final cfg = await getKwsConfigByModelName(
        modelName: modelName,
        keywordsFilePath: customKeywordsPath,
      );

      _kws ??= sherpa_onnx.KeywordSpotter(cfg);
      _stream ??= _kws!.createStream();

      if (!await _rec.hasPermission()) {
        await showDialog(
          context: context,
          builder: (_) =>
              const AlertDialog(content: Text('Microphone permission denied.')),
        );
        return;
      }

      const rc = RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 16000,
        numChannels: 1,
      );
      final audioStream = await _rec.startStream(rc);

      audioStream.listen((bytes) {
        try {
          final f32 = convertBytesToFloat32(Uint8List.fromList(bytes));
          _stream!.acceptWaveform(samples: f32, sampleRate: 16000);

          while (_kws!.isReady(_stream!)) {
            _kws!.decode(_stream!);
          }

          final r = _kws!.getResult(_stream!);
          if (r.keyword.isNotEmpty) {
            _lastHitAt[r.keyword] = DateTime.now();
            final count = _hitCounts.update(
              r.keyword,
              (v) => v + 1,
              ifAbsent: () => 1,
            );

            _kwsLastHitAt = _lastHitAt[r.keyword];
            _kwsHitCount = count;
            _log.value = '累計 阿彌陀佛 $_kwsHitCount 聲';
            setState(() {}); 
            setState(() {});
          }
        } catch (e, st) {
          debugPrint('KWS stream error: $e\n$st');
        }
      });
    } catch (e, st) {
      debugPrint('KWS start failed: $e\n$st');
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('KWS 啟動失敗'),
          content: Text(e.toString()),
        ),
      );
    }
  }

  Future<void> _stop() async {
    await _rec.stop();
    _stream?.free();
    _stream = _kws?.createStream();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _rec.dispose();
    _stream?.free();
    _kws?.free();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 200,
              width: 300,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: SingleChildScrollView(
                    reverse: false,
                    child: ValueListenableBuilder<String>(
                      valueListenable: _log,
                      builder: (_, s, __) =>
                          Text(s, textAlign: TextAlign.center),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _kwsCounterPanel(),
            const SizedBox(height: 24),
            SizedBox(
              width: 140,
              child: ElevatedButton(
                onPressed: _state == RecordState.stop ? _start : _stop,
                child: Text(_state == RecordState.stop ? 'Start KWS' : 'Stop'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kwsCounterPanel() {
    final ts = _fmtTs(_kwsLastHitAt);
    return Card(
      elevation: 0,
      color: Colors.amber.withOpacity(0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'KWS 阿彌陀佛',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '累計：$_kwsHitCount 聲',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  '最後：$ts',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
