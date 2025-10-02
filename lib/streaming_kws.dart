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
        keywordsScore: 1.4,
        keywordsThreshold: 0.20,
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
            _log.value = '[HIT] ${r.keyword}\n${_log.value}';
            _kws!.reset(_stream!);
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
              height: 200, // 顯示區高度可調
              width: 300, // 可加個寬度限制，視需求
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
}
