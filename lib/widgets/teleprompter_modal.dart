import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TeleprompterModal extends StatefulWidget {
  final String text;
  final String title;

  const TeleprompterModal({
    super.key,
    required this.text,
    this.title = 'Spiker Teleprompter',
  });

  static void show(BuildContext context, {required String text, String title = 'Spiker Teleprompter'}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      builder: (ctx) => TeleprompterModal(text: text, title: title),
    );
  }

  @override
  State<TeleprompterModal> createState() => _TeleprompterModalState();
}

class _TeleprompterModalState extends State<TeleprompterModal> {
  final ScrollController _scrollController = ScrollController();
  final FlutterTts _flutterTts = FlutterTts();

  bool _isPlaying = false;
  bool _isSpeaking = false;
  bool _isMirrored = false;
  double _scrollSpeed = 2.0; // 1.0 to 10.0
  double _fontSize = 28.0;   // 18.0 to 48.0
  Timer? _scrollTimer;
  int _countdown = 0;

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  Future<void> _initTts() async {
    try {
      await _flutterTts.setLanguage('tr-TR');
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);

      _flutterTts.setCompletionHandler(() {
        if (mounted) {
          setState(() {
            _isSpeaking = false;
          });
        }
      });

      _flutterTts.setErrorHandler((msg) {
        if (mounted) {
          setState(() {
            _isSpeaking = false;
          });
        }
      });
    } catch (_) {}
  }

  void _togglePlay() {
    if (_isPlaying) {
      _stopScroll();
    } else {
      _startCountdownAndScroll();
    }
  }

  void _startCountdownAndScroll() {
    setState(() {
      _countdown = 3;
    });

    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_countdown > 1) {
        setState(() {
          _countdown--;
        });
      } else {
        timer.cancel();
        setState(() {
          _countdown = 0;
          _isPlaying = true;
        });
        _startScroll();
      }
    });
  }

  void _startScroll() {
    _scrollTimer?.cancel();
    _scrollTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (!_scrollController.hasClients) return;
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.offset;
      final nextScroll = currentScroll + (_scrollSpeed * 0.8);

      if (nextScroll >= maxScroll) {
        _stopScroll();
      } else {
        _scrollController.jumpTo(nextScroll);
      }
    });
  }

  void _stopScroll() {
    _scrollTimer?.cancel();
    _scrollTimer = null;
    if (mounted) {
      setState(() {
        _isPlaying = false;
      });
    }
  }

  void _resetScroll() {
    _stopScroll();
    _stopSpeaking();
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
  }

  Future<void> _toggleTts() async {
    if (_isSpeaking) {
      await _stopSpeaking();
    } else {
      await _startSpeaking();
    }
  }

  Future<void> _startSpeaking() async {
    if (widget.text.trim().isEmpty) return;
    setState(() {
      _isSpeaking = true;
    });
    // Clean headers before reading
    final speechText = widget.text
        .replaceAll('KJ:', '')
        .replaceAll('CAM:', '')
        .replaceAll('SES:', '')
        .replaceAll('**', '')
        .replaceAll('#', '');
    await _flutterTts.speak(speechText);
  }

  Future<void> _stopSpeaking() async {
    await _flutterTts.stop();
    if (mounted) {
      setState(() {
        _isSpeaking = false;
      });
    }
  }

  @override
  void dispose() {
    _scrollTimer?.cancel();
    _scrollController.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF111827),
        foregroundColor: Colors.white,
        title: Text(widget.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            tooltip: _isMirrored ? 'Ayna Modu Açık' : 'Ayna Modu (Ters Yansıtma)',
            icon: Icon(
              Icons.flip,
              color: _isMirrored ? const Color(0xFF00A3E0) : Colors.white70,
            ),
            onPressed: () {
              setState(() {
                _isMirrored = !_isMirrored;
              });
            },
          ),
          IconButton(
            tooltip: _isSpeaking ? 'Seslendirmeyi Durdur' : 'Metni Seslendir (TTS)',
            icon: Icon(
              _isSpeaking ? Icons.volume_up : Icons.volume_mute,
              color: _isSpeaking ? Colors.greenAccent : Colors.white70,
            ),
            onPressed: _toggleTts,
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Metin Alanı
          Transform(
            alignment: Alignment.center,
            transform: Matrix4.diagonal3Values(_isMirrored ? -1.0 : 1.0, 1.0, 1.0),
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 80),
              children: [
                Text(
                  widget.text,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: _fontSize,
                    fontWeight: FontWeight.w600,
                    height: 1.6,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 350),
              ],
            ),
          ),

          // Okuma Çizgisi Göstergesi (Eye Line Marker)
          Positioned(
            left: 0,
            right: 0,
            top: MediaQuery.of(context).size.height * 0.28,
            child: IgnorePointer(
              child: Container(
                height: 3,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      const Color(0xFF00A3E0).withAlpha(180),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Geri Sayım Göstergesi (Countdown)
          if (_countdown > 0)
            Center(
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: const Color(0xFF003366).withAlpha(220),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF00A3E0), width: 3),
                ),
                child: Text(
                  '$_countdown',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 72,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

          // Alt Kontrol Paneli
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF111827).withAlpha(240),
                border: Border(top: BorderSide(color: Colors.grey.shade800)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Ayar Kaydırıcıları
                  Row(
                    children: [
                      const Icon(Icons.format_size, color: Colors.white70, size: 20),
                      Expanded(
                        child: Slider(
                          value: _fontSize,
                          min: 18,
                          max: 48,
                          activeColor: const Color(0xFF00A3E0),
                          inactiveColor: Colors.grey.shade700,
                          onChanged: (val) {
                            setState(() {
                              _fontSize = val;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.speed, color: Colors.white70, size: 20),
                      Expanded(
                        child: Slider(
                          value: _scrollSpeed,
                          min: 0.5,
                          max: 8.0,
                          activeColor: Colors.orangeAccent,
                          inactiveColor: Colors.grey.shade700,
                          onChanged: (val) {
                            setState(() {
                              _scrollSpeed = val;
                            });
                            if (_isPlaying) {
                              _startScroll();
                            }
                          },
                        ),
                      ),
                    ],
                  ),

                  // Eylem Düğmeleri
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade800,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _resetScroll,
                        icon: const Icon(Icons.replay),
                        label: const Text('Başa Dön'),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isPlaying ? Colors.redAccent : const Color(0xFF00A3E0),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        onPressed: _togglePlay,
                        icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                        label: Text(_isPlaying ? 'Durdur' : 'Kaydır'),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isSpeaking ? Colors.green.shade700 : const Color(0xFF003366),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _toggleTts,
                        icon: Icon(_isSpeaking ? Icons.stop : Icons.record_voice_over),
                        label: Text(_isSpeaking ? 'Sustur' : 'Seslendir'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
