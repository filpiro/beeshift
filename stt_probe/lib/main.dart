// Throwaway device probe for wayfinder ticket "Task: device test of Italian
// speech_to_text output". Logs every raw plugin event; not the feature.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

void main() => runApp(const MaterialApp(home: Probe()));

class Probe extends StatefulWidget {
  const Probe({super.key});
  @override
  State<Probe> createState() => _ProbeState();
}

class _ProbeState extends State<Probe> {
  final _stt = SpeechToText();
  final _log = <String>[];
  final _clock = Stopwatch();
  bool _onDevice = false;

  void _add(String line) {
    final entry = '${_clock.elapsedMilliseconds.toString().padLeft(6)} $line';
    debugPrint('STT|$entry');
    setState(() => _log.add(entry));
  }

  Future<void> _init() async {
    _clock
      ..reset()
      ..start();
    try {
      final ok = await _stt.initialize(
        onStatus: (s) => _add('status $s'),
        onError: (e) => _add('error ${e.errorMsg} permanent=${e.permanent}'),
        options: [SpeechToText.androidNoBluetooth],
      );
      _add('initialize -> $ok, hasPermission=${await _stt.hasPermission}');
    } on PlatformException catch (e) {
      _add('initialize threw ${e.code}: ${e.message}');
    }
  }

  Future<void> _locales() async {
    try {
      final all = await _stt.locales().timeout(const Duration(seconds: 5));
      final it = all.where((l) => l.localeId.toLowerCase().startsWith('it'));
      _add('locales -> ${all.length}, italian: ${it.map((l) => l.localeId).toList()}');
    } catch (e) {
      _add('locales failed: $e');
    }
  }

  Future<void> _listen() async {
    _clock
      ..reset()
      ..start();
    _add('listen tap (onDevice=$_onDevice)');
    await _stt.listen(
      onResult: _onResult,
      listenOptions: SpeechListenOptions(localeId: 'it_IT', onDevice: _onDevice),
    );
  }

  void _onResult(SpeechRecognitionResult r) {
    final alts = r.alternates.map((a) => '"${a.recognizedWords}"').join(' | ');
    _add('${r.finalResult ? 'FINAL' : 'partial'} $alts');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('STT probe it_IT')),
      body: Column(
        children: [
          Wrap(
            spacing: 8,
            children: [
              FilledButton(onPressed: _init, child: const Text('Init')),
              FilledButton(onPressed: _locales, child: const Text('Locales')),
              FilledButton(onPressed: _listen, child: const Text('Listen')),
              OutlinedButton(onPressed: _stt.stop, child: const Text('Stop')),
              FilterChip(
                label: const Text('onDevice'),
                selected: _onDevice,
                onSelected: (v) => setState(() => _onDevice = v),
              ),
              OutlinedButton(
                onPressed: () => Clipboard.setData(ClipboardData(text: _log.join('\n'))),
                child: const Text('Copy log'),
              ),
              OutlinedButton(
                onPressed: () => setState(_log.clear),
                child: const Text('Clear'),
              ),
            ],
          ),
          Expanded(
            child: ListView(
              reverse: true,
              children: [
                for (final l in _log.reversed)
                  Text(l, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
