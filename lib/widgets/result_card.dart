import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:share_plus/share_plus.dart';
import '../services/docx_generator_service.dart';
import 'teleprompter_modal.dart';

class ResultCard extends StatefulWidget {
  final String title;
  final String content;
  final String? modelUsed;
  final bool isMarkdown;
  final bool showTeleprompter;
  final String? defaultDocxTitle;
  final String? forwardButtonLabel;
  final VoidCallback? onForward;

  const ResultCard({
    super.key,
    required this.title,
    required this.content,
    this.modelUsed,
    this.isMarkdown = true,
    this.showTeleprompter = false,
    this.defaultDocxTitle,
    this.forwardButtonLabel,
    this.onForward,
  });

  @override
  State<ResultCard> createState() => _ResultCardState();
}

class _ResultCardState extends State<ResultCard> {
  late TextEditingController _textController;
  bool _isEditing = false;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.content);
  }

  @override
  void didUpdateWidget(ResultCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.content != widget.content && !_isEditing) {
      _textController.text = widget.content;
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: _textController.text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text('Metin panoya kopyalandı!'),
          ],
        ),
        backgroundColor: Color(0xFF003366),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _exportAndShareDocx() async {
    setState(() {
      _isExporting = true;
    });

    try {
      final title = widget.defaultDocxTitle ?? 'HaberVAR_Metin';
      final file = await DocxGeneratorService.createDocxFile(
        title: title,
        content: _textController.text,
      );

      setState(() {
        _isExporting = false;
      });

      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (ctx) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.description, color: Color(0xFF003366), size: 48),
              const SizedBox(height: 12),
              const Text(
                'Word (.docx) Belgesi Hazırlandı',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Belge yolu: ${file.path}',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close),
                      label: const Text('Kapat'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Share.shareXFiles([XFile(file.path)], text: 'HaberVAR - $title');
                      },
                      icon: const Icon(Icons.share),
                      label: const Text('Paylaş'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _isExporting = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Word belgesi oluşturulamadı: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: const Color(0xFF00A3E0).withAlpha(60), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Başlık ve Üst Eylemler
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF003366).withAlpha(12),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, color: Color(0xFF003366), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      if (widget.modelUsed != null)
                        Text(
                          'Model: ${widget.modelUsed}',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: _isEditing ? 'Önizlemeye Dön' : 'Metni Düzenle',
                  icon: Icon(_isEditing ? Icons.visibility : Icons.edit, size: 20, color: const Color(0xFF003366)),
                  onPressed: () {
                    setState(() {
                      _isEditing = !_isEditing;
                    });
                  },
                ),
                IconButton(
                  tooltip: 'Panoya Kopyala',
                  icon: const Icon(Icons.copy, size: 20, color: Color(0xFF003366)),
                  onPressed: _copyToClipboard,
                ),
              ],
            ),
          ),

          // İçerik Alanı
          Padding(
            padding: const EdgeInsets.all(16),
            child: _isEditing
                ? TextField(
                    controller: _textController,
                    maxLines: null,
                    style: const TextStyle(fontSize: 14, height: 1.5),
                    decoration: const InputDecoration(
                      hintText: 'Metni burada düzenleyebilirsiniz...',
                      border: OutlineInputBorder(),
                    ),
                  )
                : widget.isMarkdown
                    ? MarkdownBody(
                        data: _textController.text,
                        selectable: true,
                        styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
                          p: const TextStyle(fontSize: 14, height: 1.6),
                          h1: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF003366)),
                          h2: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF00A3E0)),
                          h3: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          blockquote: TextStyle(
                            color: Colors.grey.shade800,
                            fontStyle: FontStyle.italic,
                            fontSize: 13,
                          ),
                        ),
                      )
                    : SelectableText(
                        _textController.text,
                        style: const TextStyle(fontSize: 14, height: 1.6, fontFamily: 'monospace'),
                      ),
          ),

          const Divider(height: 1),

          // Alt Eylem Butonları
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 6,
              children: [
                if (widget.showTeleprompter)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black87,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                    onPressed: () {
                      TeleprompterModal.show(
                        context,
                        text: _textController.text,
                        title: widget.title,
                      );
                    },
                    icon: const Icon(Icons.videocam, size: 18),
                    label: const Text('Prompter Modu', style: TextStyle(fontSize: 13)),
                  ),
                OutlinedButton.icon(
                  onPressed: _copyToClipboard,
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('Kopyala', style: TextStyle(fontSize: 13)),
                ),
                ElevatedButton.icon(
                  onPressed: _isExporting ? null : _exportAndShareDocx,
                  icon: _isExporting
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.download, size: 16),
                  label: const Text('Word (.docx)', style: TextStyle(fontSize: 13)),
                ),
                if (widget.forwardButtonLabel != null && widget.onForward != null)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00A3E0),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                    onPressed: widget.onForward,
                    icon: const Icon(Icons.arrow_forward, size: 16),
                    label: Text(widget.forwardButtonLabel!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
