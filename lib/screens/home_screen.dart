import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_key_storage.dart';
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

    if (mounted) {
      setState(() {
        _hasApiKey = key != null && key.isNotEmpty;
        _universityName = uni;
        _agencyName = agency;
        _rectorName = rector;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF003366),
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(30),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Image.asset(
                'assets/images/logo.png',
                width: 28,
                height: 28,
                errorBuilder: (_, __, ___) => const Icon(Icons.cell_tower, color: Colors.white, size: 28),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'HaberVAR',
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
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
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF003366), Color(0xFF00A3E0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/logo.png',
                    width: 44,
                    height: 44,
                    errorBuilder: (_, __, ___) => const Icon(Icons.cell_tower, size: 44, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'HaberVAR',
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '$_universityName $_agencyName',
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.mic, color: Color(0xFF003366)),
              title: const Text('1. Ses Çözümleme'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AudioTranscriptionScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.newspaper, color: Color(0xFF003366)),
              title: Text('2. $_agencyName Basın Haber Yazarı'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const NewsCreatorScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.tv, color: Color(0xFF003366)),
              title: const Text('3. TV Haber & Prompter'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const TvNewsScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.fact_check, color: Color(0xFF003366)),
              title: const Text('4. Editoryal Denetim & İmla'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const EditorialCheckScreen()));
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.settings, color: Color(0xFF003366)),
              title: const Text('Ayarlar & Gemini Modelleri'),
              onTap: () async {
                Navigator.pop(context);
                await Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                _checkStatus();
              },
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF003366).withAlpha(12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF003366).withAlpha(30)),
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
                            'Geliştiren:',
                            style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w600),
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
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            // Üst Karşılama Kartı
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF003366), Color(0xFF0B2545)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF003366).withAlpha(30),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00A3E0).withAlpha(40),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF00A3E0).withAlpha(80)),
                          ),
                          child: Text(
                            '$_universityName • $_agencyName'.toUpperCase(),
                            style: const TextStyle(color: Color(0xFF00A3E0), fontSize: 10, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'HaberVAR AI Asistanı',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Rektörlük: $_rectorName',
                          style: const TextStyle(color: Colors.white70, fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Image.asset(
                    'assets/images/logo.png',
                    width: 56,
                    height: 56,
                    errorBuilder: (_, __, ___) => const Icon(Icons.cell_tower, size: 56, color: Color(0xFF00A3E0)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // API Key Uyarısı (Eğer key yoksa)
            if (!_hasApiKey)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 24),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('API Anahtarı Eksik', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          Text('Modülleri çalıştırmak için Ayarlar sekmesinden Gemini API anahtarınızı girin.', style: TextStyle(fontSize: 11, color: Colors.black87)),
                        ],
                      ),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
                      onPressed: () async {
                        await Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                        _checkStatus();
                      },
                      child: const Text('Ayarla', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ],
                ),
              ),

            // Başlık
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Modüller & Araçlar',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const Text(
                    '4 Akıllı Modül',
                    style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // IZGARA (GRID) DÜZENİ - Responsive Tasarım
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
                      subtitle: 'Canlı ses kaydı & Word çıktısı',
                      badgeText: '🎙️ Canlı Kayıt',
                      badgeColor: Colors.orange.shade700,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AudioTranscriptionScreen())),
                    ),
                    _buildGridCard(
                      context,
                      width: cardWidth,
                      icon: Icons.newspaper,
                      gradientColors: [const Color(0xFF003366), const Color(0xFF00A3E0)],
                      title: 'Haber Yazarı',
                      subtitle: 'Kurumsal format & 5N1K',
                      badgeText: '📰 Multimodal',
                      badgeColor: const Color(0xFF003366),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NewsCreatorScreen())),
                    ),
                    _buildGridCard(
                      context,
                      width: cardWidth,
                      icon: Icons.tv,
                      gradientColors: [const Color(0xFF0284C7), const Color(0xFF38BDF8)],
                      title: 'TV Formatı',
                      subtitle: 'Video seçeneği & Teleprompter',
                      badgeText: '📺 Seslendirmeli',
                      badgeColor: const Color(0xFF0284C7),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TvNewsScreen())),
                    ),
                    _buildGridCard(
                      context,
                      width: cardWidth,
                      icon: Icons.fact_check,
                      gradientColors: [const Color(0xFF0D9488), const Color(0xFF2DD4BF)],
                      title: 'Editoryal Denetim',
                      subtitle: 'TDK imla karnesi & Ayrı kutular',
                      badgeText: '🔍 100 Puan',
                      badgeColor: const Color(0xFF0D9488),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditorialCheckScreen())),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 20),

            // Geliştirici İmza Kartı (Footer)
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade300),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(6),
                      blurRadius: 6,
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
        shadowColor: Colors.black.withAlpha(12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
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
                      child: Icon(icon, color: Colors.white, size: 24),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                    color: Colors.grey.shade600,
                    fontSize: 11,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
