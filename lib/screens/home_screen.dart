import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_key_storage.dart';
import '../services/saved_content_service.dart';
import 'audio_transcription_screen.dart';
import 'news_creator_screen.dart';
import 'tv_news_screen.dart';
import 'editorial_check_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _hasApiKey = false;
  String _universityName = ApiKeyStorage.defaultUniversity;
  String _agencyName = ApiKeyStorage.defaultAgency;
  String _rectorName = ApiKeyStorage.defaultRector;
  int _savedNewsCount = 0;
  int _savedPrompterCount = 0;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    final key = await ApiKeyStorage.getApiKey();
    final uni = await ApiKeyStorage.getUniversityName();
    final agency = await ApiKeyStorage.getAgencyName();
    final rector = await ApiKeyStorage.getRectorName();
    final savedNews = await SavedContentService.getSavedNews();
    final savedPrompters = await SavedContentService.getSavedPrompters();

    if (mounted) {
      setState(() {
        _hasApiKey = key != null && key.isNotEmpty;
        _universityName = uni;
        _agencyName = agency;
        _rectorName = rector;
        _savedNewsCount = savedNews.length;
        _savedPrompterCount = savedPrompters.length;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF002244),
        elevation: 0,
        centerTitle: false,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(25),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withAlpha(40)),
              ),
              child: Image.asset(
                'assets/images/logo.png',
                width: 26,
                height: 26,
                errorBuilder: (_, __, ___) => const Icon(Icons.cell_tower, color: Color(0xFF00A3E0), size: 24),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'HaberVAR',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'AI Kurumsal Medya Merkezi',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withAlpha(200),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Durum Rozeti (API Bağlantısı)
          Container(
            margin: const EdgeInsets.symmetric(vertical: 14),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: _hasApiKey ? Colors.green.withAlpha(40) : Colors.orange.withAlpha(40),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _hasApiKey ? Colors.greenAccent : Colors.orangeAccent),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _hasApiKey ? Colors.greenAccent : Colors.orangeAccent,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  _hasApiKey ? 'Online' : 'Kurulum',
                  style: TextStyle(
                    color: _hasApiKey ? Colors.greenAccent : Colors.orangeAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            tooltip: 'Ayarlar ve Model Yönetimi',
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
              _checkStatus();
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  DrawerHeader(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF002244), Color(0xFF004080)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(30),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Image.asset(
                                'assets/images/logo.png',
                                width: 36,
                                height: 36,
                                errorBuilder: (_, __, ___) => const Icon(Icons.cell_tower, size: 36, color: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'HaberVAR',
                                  style: GoogleFonts.outfit(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF00A3E0).withAlpha(60),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'v1.0.0 Enterprise',
                                    style: TextStyle(color: Color(0xFF00A3E0), fontSize: 9, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '$_universityName • $_agencyName',
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Rektörlük: $_rectorName',
                          style: const TextStyle(color: Colors.white70, fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // Kategori Başlığı: Akıllı Haber Hattı
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Text(
                      'AKILLI HABER ÜRETİM HATTI',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: Colors.blueGrey.shade600,
                      ),
                    ),
                  ),
                  _buildDrawerItem(
                    stepNumber: '1',
                    icon: Icons.mic,
                    iconColor: const Color(0xFFE65100),
                    title: 'Ses Çözümleme',
                    subtitle: 'Canlı röportaj & ses kaydı deşifresi',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const AudioTranscriptionScreen()));
                    },
                  ),
                  _buildDrawerItem(
                    stepNumber: '2',
                    icon: Icons.newspaper,
                    iconColor: const Color(0xFF003366),
                    title: '$_agencyName Basın Bülteni',
                    subtitle: '5N1K ve kurumsal haber yazarı',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const NewsCreatorScreen()));
                    },
                  ),
                  _buildDrawerItem(
                    stepNumber: '3',
                    icon: Icons.fact_check,
                    iconColor: const Color(0xFF0D9488),
                    title: 'Editoryal Denetim',
                    subtitle: 'TDK imla karnesi & onaylı haber',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const EditorialCheckScreen()));
                    },
                  ),
                  _buildDrawerItem(
                    stepNumber: '4',
                    icon: Icons.tv,
                    iconColor: const Color(0xFF0284C7),
                    title: 'TV Formatı & Prompter',
                    subtitle: 'Spiker metni & stüdyo prompterı',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const TvNewsScreen()));
                    },
                  ),

                  const Divider(height: 24),

                  // Kategori Başlığı: Yapılandırma
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                    child: Text(
                      'YAPILANDIRMA & VERİ',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: Colors.blueGrey.shade600,
                      ),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.settings, color: Color(0xFF003366)),
                    title: const Text('Ayarlar & Gemini Modelleri', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    subtitle: const Text('API anahtarı, modeller ve kurum isimleri', style: TextStyle(fontSize: 11)),
                    onTap: () async {
                      Navigator.pop(context);
                      await Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                      _checkStatus();
                    },
                  ),
                ],
              ),
            ),

            // Çekmece Alt Geliştirici Kartı
            Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF003366).withAlpha(10),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF003366).withAlpha(25)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.terminal, color: Color(0xFF003366), size: 24),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'YAZILIM & SİSTEM GELİŞTİRİCİ',
                          style: TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          'Dr. Kemal ŞİMŞEK',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF003366)),
                        ),
                        Text(
                          'Bilgisayar Mühendisi',
                          style: TextStyle(fontSize: 11, color: Color(0xFF00A3E0), fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            // ÜST KARŞILAMA HERO BANNER
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF002244), Color(0xFF003865), Color(0xFF004B87)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF002244).withAlpha(50),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Kurum & Ajans Rozeti
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00A3E0).withAlpha(45),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFF00A3E0).withAlpha(90)),
                          ),
                          child: Text(
                            '$_universityName • $_agencyName'.toUpperCase(),
                            style: const TextStyle(
                              color: Color(0xFF00D2FF),
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // AI Motoru Rozeti
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(20),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.bolt, color: Colors.amber, size: 13),
                            SizedBox(width: 3),
                            Text(
                              'Gemini 2.5 Flash',
                              style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'HaberVAR AI Asistanı',
                              style: GoogleFonts.outfit(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '🏛️ Rektörlük: $_rectorName',
                              style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(25),
                          shape: BoxShape.circle,
                        ),
                        child: Image.asset(
                          'assets/images/logo.png',
                          width: 44,
                          height: 44,
                          errorBuilder: (_, __, ___) => const Icon(Icons.cell_tower, size: 40, color: Color(0xFF00A3E0)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // API KEY UYARISI
            if (!_hasApiKey)
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.amber.shade400),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 26),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Gemini API Anahtarı Gerekli', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          Text('Yapay zeka modellerini çalıştırmak için lütfen Ayarlar sekmesinden anahtarınızı girin.', style: TextStyle(fontSize: 11, color: Colors.black87)),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF003366),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      onPressed: () async {
                        await Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                        _checkStatus();
                      },
                      child: const Text('Ayarla', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),

            // KESİNTİSİZ HABER ÜRETİM HATTI (WORKFLOW PIPELINE STEPPER)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.blueGrey.shade100),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(8),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF003366).withAlpha(15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.alt_route, color: Color(0xFF003366), size: 18),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Kesintisiz Haber Üretim Hattı',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF002244),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00A3E0).withAlpha(20),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'Adım Adım Akış',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF00A3E0)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Röportaj sesinden kurumsal bültene, editoryal denetimden stüdyo prompterına tam entegre gazetecilik hattı:',
                    style: TextStyle(fontSize: 11, color: Colors.blueGrey.shade700),
                  ),
                  const SizedBox(height: 12),

                  // 4 Adımlı Yatay Akış Çizelgesi
                  Row(
                    children: [
                      Expanded(
                        child: _buildWorkflowStep(
                          step: '1',
                          icon: Icons.mic,
                          label: 'Ses Deşifre',
                          color: const Color(0xFFE65100),
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AudioTranscriptionScreen())),
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
                      Expanded(
                        child: _buildWorkflowStep(
                          step: '2',
                          icon: Icons.newspaper,
                          label: 'Haber Yaz',
                          color: const Color(0xFF003366),
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NewsCreatorScreen())),
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
                      Expanded(
                        child: _buildWorkflowStep(
                          step: '3',
                          icon: Icons.fact_check,
                          label: 'Editöryal',
                          color: const Color(0xFF0D9488),
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditorialCheckScreen())),
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
                      Expanded(
                        child: _buildWorkflowStep(
                          step: '4',
                          icon: Icons.tv,
                          label: 'TV Prompter',
                          color: const Color(0xFF0284C7),
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TvNewsScreen())),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // KAYITLI VERİ VE HIZLI ERİŞİM ŞERİDİ
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditorialCheckScreen())),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.blueGrey.shade100),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0D9488).withAlpha(20),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.inventory_2_outlined, color: Color(0xFF0D9488), size: 18),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$_savedNewsCount Kayıt',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                                ),
                                const Text(
                                  'Nihai Haberler',
                                  style: TextStyle(fontSize: 10, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TvNewsScreen())),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.blueGrey.shade100),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0284C7).withAlpha(20),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.live_tv_outlined, color: Color(0xFF0284C7), size: 18),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$_savedPrompterCount Bülten',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                                ),
                                const Text(
                                  'TV Prompterları',
                                  style: TextStyle(fontSize: 10, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // BAŞLIK: AKILLI YAYINCILIK MODÜLLERİ
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Yayıncılık Modülleri',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const Text(
                  '4 Entegre Araç',
                  style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // IZGARA DÜZENİ (GRID CARDS)
            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = isTablet ? 4 : 2;
                final cardWidth = (constraints.maxWidth - ((crossAxisCount - 1) * 12)) / crossAxisCount;

                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildGridCard(
                      context,
                      width: cardWidth,
                      icon: Icons.mic,
                      gradientColors: [const Color(0xFFE65100), const Color(0xFFFF9800)],
                      title: 'Ses Çözümleme',
                      subtitle: 'Canlı röportaj kaydı & Word çıktısı',
                      badgeText: '🎙️ Kayıt & Deşifre',
                      badgeColor: Colors.orange.shade700,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AudioTranscriptionScreen())),
                    ),
                    _buildGridCard(
                      context,
                      width: cardWidth,
                      icon: Icons.newspaper,
                      gradientColors: [const Color(0xFF003366), const Color(0xFF00A3E0)],
                      title: 'Haber Yazarı',
                      subtitle: '5N1K kurumsal basın bülteni üretimi',
                      badgeText: '📰 5N1K Metni',
                      badgeColor: const Color(0xFF003366),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NewsCreatorScreen())),
                    ),
                    _buildGridCard(
                      context,
                      width: cardWidth,
                      icon: Icons.fact_check,
                      gradientColors: [const Color(0xFF0D9488), const Color(0xFF2DD4BF)],
                      title: 'Editoryal Denetim',
                      subtitle: '100 puanlık TDK imla karnesi & onay',
                      badgeText: '🔍 TDK Karnesi',
                      badgeColor: const Color(0xFF0D9488),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditorialCheckScreen())),
                    ),
                    _buildGridCard(
                      context,
                      width: cardWidth,
                      icon: Icons.tv,
                      gradientColors: [const Color(0xFF0284C7), const Color(0xFF38BDF8)],
                      title: 'TV Formatı & Prompter',
                      subtitle: 'KJ, spiker metni, seslendirme & teleprompter',
                      badgeText: '📺 Stüdyo Modu',
                      badgeColor: const Color(0xFF0284C7),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TvNewsScreen())),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 24),

            // GELİŞTİRİCİ İMZA KARTI (FOOTER)
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey.shade300),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(6),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.code, size: 16, color: Color(0xFF003366)),
                    SizedBox(width: 8),
                    Text(
                      'Geliştiren: ',
                      style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500),
                    ),
                    Text(
                      'Dr. Kemal ŞİMŞEK',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF003366)),
                    ),
                    Text(
                      ' • Bilgisayar Mühendisi',
                      style: TextStyle(fontSize: 11, color: Color(0xFF00A3E0), fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkflowStep({
    required String step,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withAlpha(20),
                shape: BoxShape.circle,
                border: Border.all(color: color.withAlpha(80), width: 1.5),
              ),
              child: Center(
                child: Icon(icon, color: color, size: 18),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              '$step. $label',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey.shade800,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required String stepNumber,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withAlpha(20),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        '$stepNumber. $title',
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 11, color: Colors.grey),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
      onTap: onTap,
    );
  }

  Widget _buildGridCard(
    BuildContext context, {
    required double width,
    required IconData icon,
    required List<Color> gradientColors,
    required String title,
    required String subtitle,
    required String badgeText,
    required Color badgeColor,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: width,
      child: Card(
        elevation: 2,
        shadowColor: Colors.black.withAlpha(15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: Colors.blueGrey.shade100, width: 1),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // İkon ve Rozet
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: gradientColors,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: gradientColors[0].withAlpha(60),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(icon, color: Colors.white, size: 22),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: badgeColor.withAlpha(18),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        badgeText,
                        style: TextStyle(
                          color: badgeColor,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Başlık
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: const Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 4),

                // Açıklama
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.blueGrey.shade600,
                    fontSize: 11,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 8),

                // Aksiyon Ok
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'Aç',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: gradientColors[0]),
                    ),
                    const SizedBox(width: 2),
                    Icon(Icons.arrow_forward, size: 12, color: gradientColors[0]),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
