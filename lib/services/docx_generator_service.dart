import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';

class DocxGeneratorService {
  /// Metni formatlayarak standart Microsoft Word (.docx) dosyası üretir.
  static Future<File> createDocxFile({
    required String title,
    required String content,
    String? categoryHeader,
    bool isTvFormat = false,
  }) async {
    return generateDocx(
      title: title,
      content: content,
      categoryHeader: categoryHeader,
      isTvFormat: isTvFormat,
    );
  }

  static Future<File> generateDocx({
    required String title,
    required String content,
    String? categoryHeader,
    bool isTvFormat = false,
  }) async {
    final archive = Archive();

    // 1. [Content_Types].xml
    const contentTypesXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
  <Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/>
  <Override PartName="/docProps/core.xml" ContentType="application/vnd.openxmlformats-package.core-properties+xml"/>
  <Override PartName="/docProps/app.xml" ContentType="application/vnd.openxmlformats-officedocument.extended-properties+xml"/>
</Types>''';
    _addStringToArchive(archive, '[Content_Types].xml', contentTypesXml);

    // 2. _rels/.rels
    const relsXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
  <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties" Target="docProps/core.xml"/>
  <Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/extended-properties" Target="docProps/app.xml"/>
</Relationships>''';
    _addStringToArchive(archive, '_rels/.rels', relsXml);

    // 3. word/_rels/document.xml.rels
    const docRelsXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
</Relationships>''';
    _addStringToArchive(archive, 'word/_rels/document.xml.rels', docRelsXml);

    // 4. word/styles.xml (Times New Roman 12pt, Paragraf stilleri)
    const stylesXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:docDefaults>
    <w:rPrDefault>
      <w:rPr>
        <w:rFonts w:ascii="Times New Roman" w:hAnsi="Times New Roman" w:cs="Times New Roman"/>
        <w:sz w:val="24"/>
        <w:lang w:val="tr-TR"/>
      </w:rPr>
    </w:rPrDefault>
  </w:docDefaults>
</w:styles>''';
    _addStringToArchive(archive, 'word/styles.xml', stylesXml);

    // 5. docProps/core.xml
    final nowIso = DateTime.now().toUtc().toIso8601String();
    final coreXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:dcterms="http://purl.org/dc/terms/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <dc:title>${_escapeXml(title)}</dc:title>
  <dc:creator>Dr. Kemal ŞİMŞEK - Bilgisayar Mühendisi (HaberCiM - Ege Ajans)</dc:creator>
  <cp:lastModifiedBy>Dr. Kemal ŞİMŞEK - Bilgisayar Mühendisi</cp:lastModifiedBy>
  <dcterms:created xsi:type="dcterms:W3CDTF">$nowIso</dcterms:created>
  <dcterms:modified xsi:type="dcterms:W3CDTF">$nowIso</dcterms:modified>
</cp:coreProperties>''';
    _addStringToArchive(archive, 'docProps/core.xml', coreXml);

    // 6. docProps/app.xml
    const appXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Properties xmlns="http://schemas.openxmlformats.org/officeDocument/2006/extended-properties">
  <Application>HaberCiM - Geliştiren: Dr. Kemal ŞİMŞEK (Bilgisayar Mühendisi)</Application>
</Properties>''';
    _addStringToArchive(archive, 'docProps/app.xml', appXml);

    // 7. word/document.xml - İçeriği oluşturma
    final buffer = StringBuffer();
    buffer.write('''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:body>''');

    // Eğer TV formatı değilse ve kategori başlığı varsa ekle
    if (!isTvFormat && categoryHeader != null && categoryHeader.isNotEmpty) {
      buffer.write(_createHeadingXml(categoryHeader, fontSizePt: 16, isBold: true, isHeading1: true));
    }

    // Paragrafları satır satır veya blok blok işle
    final lines = content.split('\n');
    for (var line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      if (trimmed.startsWith('# ')) {
        // H1 Başlık
        final text = trimmed.substring(2).trim();
        buffer.write(_createHeadingXml(text, fontSizePt: 16, isBold: true, isHeading1: true));
      } else if (trimmed.startsWith('## ')) {
        // H2 Ara Başlık
        final text = trimmed.substring(3).trim();
        buffer.write(_createHeadingXml(text, fontSizePt: 14, isBold: true, isHeading1: false));
      } else if (trimmed.startsWith('### ')) {
        // H3
        final text = trimmed.substring(4).trim();
        buffer.write(_createHeadingXml(text, fontSizePt: 13, isBold: true, isHeading1: false));
      } else if (trimmed.startsWith('**') && trimmed.endsWith('**') && trimmed.length > 4) {
        // Spot veya Kalın Paragraf
        final text = trimmed.substring(2, trimmed.length - 2).trim();
        buffer.write(_createParagraphXml(text, isBold: true, isItalic: false, isJustified: true, fontSizePt: 12));
      } else {
        // Normal paragraf (İçindeki **kalın** etiketleri parse edilir)
        buffer.write(_createRichParagraphXml(trimmed, isJustified: !isTvFormat));
      }
    }

    // Belge sonu ve sayfa kenar boşlukları (Standart 1 inç / 1440 twip)
    buffer.write('''
    <w:sectPr>
      <w:pgMar w:top="1440" w:right="1440" w:bottom="1440" w:left="1440" w:header="720" w:footer="720" w:gutter="0"/>
    </w:sectPr>
  </w:body>
</w:document>''');

    _addStringToArchive(archive, 'word/document.xml', buffer.toString());

    // ZIP dosyasını encode et
    final zipData = ZipEncoder().encode(archive);
    if (zipData == null) {
      throw Exception('DOCX ZIP verisi oluşturulamadı.');
    }

    // Dosyayı geçici / dökümanlar klasörüne kaydet
    final tempDir = await getTemporaryDirectory();
    final safeFileName = _createSafeFileName(title);
    final filePath = '${tempDir.path}/$safeFileName.docx';
    final file = File(filePath);
    await file.writeAsBytes(zipData);

    return file;
  }

  static void _addStringToArchive(Archive archive, String name, String content) {
    final bytes = utf8.encode(content);
    archive.addFile(ArchiveFile(name, bytes.length, bytes));
  }

  static String _escapeXml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  static String _createSafeFileName(String title) {
    var raw = title.trim();
    if (raw.startsWith('KJ:')) {
      raw = raw.replaceFirst('KJ:', '').trim();
    }
    if (raw.startsWith('#')) {
      raw = raw.replaceFirst('#', '').trim();
    }
    if (raw.isEmpty) raw = 'ege_ajans_haber';

    const trMap = {
      'ç': 'c', 'Ç': 'C',
      'ğ': 'g', 'Ğ': 'G',
      'ı': 'i', 'İ': 'I',
      'ö': 'o', 'Ö': 'O',
      'ş': 's', 'Ş': 'S',
      'ü': 'u', 'Ü': 'U'
    };

    var result = '';
    for (int i = 0; i < raw.length; i++) {
      final char = raw[i];
      result += trMap[char] ?? char;
    }

    result = result.replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(RegExp(r'\s+'), '_').toLowerCase();
    if (result.length > 40) {
      result = result.substring(0, 40);
    }
    return result.isEmpty ? 'ege_ajans_haber' : result;
  }

  static String _createHeadingXml(String text, {required int fontSizePt, required bool isBold, required bool isHeading1}) {
    final sz = fontSizePt * 2;
    return '''
    <w:p>
      <w:pPr>
        <w:spacing w:before="240" w:after="120" w:line="276" w:lineRule="auto"/>
        <w:jc w:val="left"/>
      </w:pPr>
      <w:r>
        <w:rPr>
          <w:rFonts w:ascii="Times New Roman" w:hAnsi="Times New Roman"/>
          <w:b/>
          <w:sz w:val="$sz"/>
          <w:szCs w:val="$sz"/>
          ${isHeading1 ? '<w:color w:val="003366"/>' : '<w:color w:val="0F172A"/>'}
        </w:rPr>
        <w:t xml:space="preserve">${_escapeXml(text)}</w:t>
      </w:r>
    </w:p>''';
  }

  static String _createParagraphXml(String text, {required bool isBold, required bool isItalic, required bool isJustified, int fontSizePt = 12}) {
    final sz = fontSizePt * 2;
    return '''
    <w:p>
      <w:pPr>
        <w:spacing w:after="160" w:line="276" w:lineRule="auto"/>
        <w:jc w:val="${isJustified ? "both" : "left"}"/>
      </w:pPr>
      <w:r>
        <w:rPr>
          <w:rFonts w:ascii="Times New Roman" w:hAnsi="Times New Roman"/>
          ${isBold ? '<w:b/>' : ''}
          ${isItalic ? '<w:i/>' : ''}
          <w:sz w:val="$sz"/>
          <w:szCs w:val="$sz"/>
        </w:rPr>
        <w:t xml:space="preserve">${_escapeXml(text)}</w:t>
      </w:r>
    </w:p>''';
  }

  static String _createRichParagraphXml(String text, {bool isJustified = true}) {
    final buffer = StringBuffer();
    buffer.write('''
    <w:p>
      <w:pPr>
        <w:spacing w:after="160" w:line="276" w:lineRule="auto"/>
        <w:jc w:val="${isJustified ? "both" : "left"}"/>
      </w:pPr>''');

    // **kalın** kısımlarını regex ile parçala
    final regex = RegExp(r'(\*\*.*?\*\*)');
    final matches = regex.allMatches(text);

    int lastIndex = 0;
    for (final match in matches) {
      if (match.start > lastIndex) {
        final normalChunk = text.substring(lastIndex, match.start);
        buffer.write(_createRunXml(normalChunk, isBold: false));
      }
      final boldChunk = match.group(0)!;
      final cleanBold = boldChunk.substring(2, boldChunk.length - 2);
      buffer.write(_createRunXml(cleanBold, isBold: true));
      lastIndex = match.end;
    }

    if (lastIndex < text.length) {
      final remaining = text.substring(lastIndex);
      buffer.write(_createRunXml(remaining, isBold: false));
    }

    buffer.write('</w:p>');
    return buffer.toString();
  }

  static String _createRunXml(String text, {required bool isBold}) {
    return '''
      <w:r>
        <w:rPr>
          <w:rFonts w:ascii="Times New Roman" w:hAnsi="Times New Roman"/>
          ${isBold ? '<w:b/>' : ''}
          <w:sz w:val="24"/>
          <w:szCs w:val="24"/>
        </w:rPr>
        <w:t xml:space="preserve">${_escapeXml(text)}</w:t>
      </w:r>''';
  }
}
