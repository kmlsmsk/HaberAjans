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
  bool _showSettings = true;
  bool _showHud = true;
  double _scrollSpeed = 2.0; // 0.5 to 8.0
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
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E17),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111827),
        elevation: 2,
        foregroundColor: Colors.white,
        title: Row(
          children: [
            const Icon(Icons.live_tv, size: 20, color: Color(0xFF00A3E0)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isPlaying ? Colors.redAccent : Colors.amber,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _isPlaying ? 'YAYINDA (AKIYOR)' : (_countdown > 0 ? 'GERİ SAYIM' : 'HAZIR'),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _isPlaying ? Colors.redAccent : Colors.grey.shade400,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: _isMirrored ? 'Normal Mod' : 'Ayna Modu (Ters Yansıtma)',
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
            tooltip: _showHud ? 'Kontrolleri Gizle' : 'Kontrolleri Göster',
            icon: Icon(
              _showHud ? Icons.visibility_off : Icons.visibility,
              color: Colors.white70,
            ),
            onPressed: () {
              setState(() {
                _showHud = !_showHud;
              });
            },
          ),
          IconButton(
            tooltip: 'Kapat',
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          // Ekrana dokununca kontrolleri aç/kapa
          setState(() {
            _showHud = !_showHud;
          });
        },
        child: Stack(
          children: [
            // Metin Alanı
            Transform(
              alignment: Alignment.center,
              transform: Matrix4.diagonal3Values(_isMirrored ? -1.0 : 1.0, 1.0, 1.0),
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 70),
                children: [
                  Text(
                    widget.text,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: _fontSize,
                      fontWeight: FontWeight.w600,
                      height: 1.65,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 380),
                ],
              ),
            ),

            // Okuma Çizgisi Göstergesi (Eye Line Marker)
            Positioned(
              left: 0,
              right: 0,
              top: MediaQuery.of(context).size.height * 0.28,
              child: IgnorePointer(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: const BoxDecoration(
                        color: Color(0xFF00A3E0),
                        borderRadius: BorderRadius.horizontal(right: Radius.circular(4)),
                      ),
                      child: const Icon(Icons.play_arrow, color: Colors.white, size: 12),
                    ),
                    Expanded(
                      child: Container(
                        height: 2,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF00A3E0).withAlpha(180),
                              const Color(0xFF00A3E0).withAlpha(60),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: const BoxDecoration(
                        color: Color(0xFF00A3E0),
                        borderRadius: BorderRadius.horizontal(left: Radius.circular(4)),
                      ),
                      child: const RotatedBox(
                        quarterTurns: 2,
                        child: Icon(Icons.play_arrow, color: Colors.white, size: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Geri Sayım Göstergesi (Broadcast Countdown)
            if (_countdown > 0)
              Center(
                child: Container(
                  width: 140,
                  height: 140,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFF002244).withAlpha(240),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF00A3E0), width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00A3E0).withAlpha(120),
                        blurRadius: 28,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: Text(
                    '$_countdown',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 72,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),

            // Gizli modda ufak yüzen gösterge butonu
            if (!_showHud)
              Positioned(
                right: 16,
                bottom: bottomInset + 16,
                child: FloatingActionButton.small(
                  backgroundColor: const Color(0xFF00A3E0).withAlpha(200),
                  foregroundColor: Colors.white,
                  tooltip: 'Kontrol Panelini Göster',
                  onPressed: () => setState(() => _showHud = true),
                  child: const Icon(Icons.tune),
                ),
              ),

            // Alt Kontrol Paneli (SafeArea ve ergonomik floating dock)
            if (_showHud)
              Positioned(
                left: 12,
                right: 12,
                bottom: 0,
                child: SafeArea(
                  top: false,
                  bottom: true,
                  child: Container(
                    margin: EdgeInsets.only(bottom: bottomInset > 0 ? 6 : 14),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF111827).withAlpha(245),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: const Color(0xFF00A3E0).withAlpha(70),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(160),
                          blurRadius: 18,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Ayarlar çubuğu (Açılır / Kapanır)
                        if (_showSettings) ...[
                          Row(
                            children: [
                              // Font Boyutu
                              const Icon(Icons.format_size, color: Color(0xFF00A3E0), size: 18),
                              const SizedBox(width: 4),
                              Text(
                                '${_fontSize.toInt()}pt',
                                style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                              Expanded(
                                child: SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    trackHeight: 3,
                                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                                  ),
                                  child: Slider(
                                    value: _fontSize,
                                    min: 18,
                                    max: 48,
                                    activeColor: const Color(0xFF00A3E0),
                                    inactiveColor: Colors.grey.shade800,
                                    onChanged: (val) {
                                      setState(() {
                                        _fontSize = val;
                                      });
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              // Kaydırma Hızı
                              const Icon(Icons.speed, color: Colors.amber, size: 18),
                              const SizedBox(width: 4),
                              Text(
                                '${_scrollSpeed.toStringAsFixed(1)}x',
                                style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                              Expanded(
                                child: SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    trackHeight: 3,
                                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                                  ),
                                  child: Slider(
                                    value: _scrollSpeed,
                                    min: 0.5,
                                    max: 8.0,
                                    activeColor: Colors.amber,
                                    inactiveColor: Colors.grey.shade800,
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
                              ),
                            ],
                          ),
                          const Divider(color: Colors.white12, height: 8),
                        ],

                        // Ana Eylem Butonları
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Başa Sar Butonu
                            IconButton(
                              tooltip: 'Metnin Başına Dön',
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.white10,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: _resetScroll,
                              icon: const Icon(Icons.replay, size: 20),
                            ),

                            // Ayarları Gizle/Göster Butonu
                            IconButton(
                              tooltip: _showSettings ? 'Ayar Kaydırıcılarını Gizle' : 'Ayar Kaydırıcılarını Aç',
                              style: IconButton.styleFrom(
                                backgroundColor: _showSettings ? const Color(0xFF00A3E0).withAlpha(40) : Colors.white10,
                                foregroundColor: _showSettings ? const Color(0xFF00A3E0) : Colors.white70,
                              ),
                              onPressed: () {
                                setState(() {
                                  _showSettings = !_showSettings;
                                });
                              },
                              icon: const Icon(Icons.tune, size: 20),
                            ),

                            // MERKEZİ OYNAT / DURDUR BUTONU (Hero Action)
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _isPlaying ? Colors.red.shade600 : const Color(0xFF00A3E0),
                                    foregroundColor: Colors.white,
                                    elevation: 4,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  onPressed: _togglePlay,
                                  icon: Icon(
                                    _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                                    size: 24,
                                  ),
                                  label: Text(
                                    _isPlaying ? 'DURDUR' : 'KAYDIR',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // SESLENDİRME (TTS) BUTONU
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isSpeaking ? Colors.green.shade700 : const Color(0xFF003366),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed: _toggleTts,
                              icon: Icon(
                                _isSpeaking ? Icons.volume_off : Icons.record_voice_over,
                                size: 18,
                              ),
                              label: Text(
                                _isSpeaking ? 'Sustur' : 'Seslendir',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
