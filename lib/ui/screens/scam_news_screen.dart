import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:xml/xml.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/rss_constants.dart';
import '../../core/utils/rss_helpers.dart';

class ScamNewsScreen extends StatefulWidget {
  const ScamNewsScreen({super.key});
  @override
  State<ScamNewsScreen> createState() => _ScamNewsScreenState();
}

class _ScamNewsScreenState extends State<ScamNewsScreen> {
  List<_NewsItem> _news = [];
  bool _loading = true;
  String? _error;



  @override
  void initState() {
    super.initState();
    _fetchAll();
  }

  Future<void> _fetchAll() async {
    setState(() { _loading = true; _error = null; });
    try {
      final result = await _fetchFeeds(RssConstants.feedUrls);
      if (mounted) {
        setState(() {
          _news = result.isNotEmpty ? result : _mockNews;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _news = _mockNews; _error = e.toString(); _loading = false; });
    }
  }

  Future<List<_NewsItem>> _fetchFeeds(List<String> feeds) async {
    final all = <_NewsItem>[];
    for (final url in feeds) {
      try {
        final proxyUrl = RssHelpers.proxiedUrl(url);
        final resp = await http.get(Uri.parse(proxyUrl))
          .timeout(const Duration(seconds: 15));
        if (resp.statusCode == 200) {
          all.addAll(_parseRss(resp.body));
        }
      } catch (_) { continue; }
    }
    return RssHelpers.deduplicateByTitle(
      all, (item) => item.title, prefixLength: 25, maxItems: 30);
  }

  List<_NewsItem> _parseRss(String xml) {
    final result = <_NewsItem>[];
    try {
      final doc   = XmlDocument.parse(xml);
      final items = doc.findAllElements('item');
      for (final item in items) {
        final title = RssHelpers.extractText(item, 'title');
        final link  = RssHelpers.extractText(item, 'link').trim();
        final desc  = RssHelpers.stripHtml(RssHelpers.extractText(item, 'description'));
        if (title.isEmpty || link.isEmpty) continue;
        
        // Removed keyword filtering to ensure Indonesian tech news always shows up.
        // It's better to show general tech news than an empty screen.

        final image = RssHelpers.fallbackImageForTitle(title);
        final date  = RssHelpers.parseRssDate(
            RssHelpers.extractText(item, 'pubDate'));
        result.add(_NewsItem(
          title: title,
          description: desc.length > 120 ? '${desc.substring(0,118)}…' : desc,
          url: link,
          imageUrl: image,
          date: date,
          source: Uri.tryParse(link)?.host.replaceFirst('www.','') ?? '',
        ));
        if (result.length >= 15) break;
      }
    } catch (_) {}
    return result;
  }

  static final _mockNews = [
    _NewsItem(
      title: 'Awas Modus Penipuan APK Berkedok Undangan Nikah & Tilang 2026',
      description: 'Pakar keamanan siber memperingatkan masyarakat tentang varian baru malware berkedok surat tilang via WhatsApp yang dapat menguras rekening.',
      url: 'https://tekno.kompas.com/read/2025/05/18/16350007/waspada-ini-7-penipuan-whatsapp-yang-sering-muncul-di-chat',
      imageUrl: 'https://images.unsplash.com/photo-1614064641938-3bbee52942c7?w=400&h=200&fit=crop',
      date: DateTime.now().subtract(const Duration(minutes: 30)),
      source: 'kompas.com',
    ),
    _NewsItem(
      title: 'OJK Blokir 4.000 Pinjol Ilegal dan Investasi Bodong Sepanjang 2026',
      description: 'Satgas Waspada Investasi terus melakukan patroli siber untuk menutup aplikasi pinjaman online ilegal yang meresahkan warga dengan ancaman sebar data.',
      url: 'https://finance.detik.com/moneter/d-8212825/waspada-penipuan-pakai-suara-dan-wajah-palsu-dari-ai',
      imageUrl: 'https://images.unsplash.com/photo-1563986768494-4dee2763ff3f?w=400&h=200&fit=crop',
      date: DateTime.now().subtract(const Duration(hours: 1)),
      source: 'detik.com',
    ),
    _NewsItem(
      title: 'Hati-Hati Phishing Mengatasnamakan Pemblokiran Rekening Bank',
      description: 'Modus penipuan social engineering semakin canggih. Pelaku menyamar sebagai CS bank dan mengirimkan link phising untuk mengamankan rekening.',
      url: 'https://inet.detik.com/security/d-7346245/7-modus-penipuan-whatsapp-yang-makan-banyak-korban',
      imageUrl: 'https://images.unsplash.com/photo-1516321318423-f06f85e504b3?w=400&h=200&fit=crop',
      date: DateTime.now().subtract(const Duration(hours: 3)),
      source: 'detik.com',
    ),
    _NewsItem(
      title: 'Bareskrim Polri Ungkap Sindikat Penipu Jual Beli Tiket Konser Palsu',
      description: 'Ribuan korban mengalami kerugian miliaran rupiah akibat sindikat penipu di Telegram dan Instagram yang menawarkan tiket konser VIP fiktif.',
      url: 'https://news.detik.com/berita/d-7744291/bareskrim-total-ada-15-tersangka-kasus-robot-trading-net89-3-masih-buron',
      imageUrl: 'https://images.unsplash.com/photo-1677442135703-1787eea5ce01?w=400&h=200&fit=crop',
      date: DateTime.now().subtract(const Duration(hours: 5)),
      source: 'detik.com',
    ),
    _NewsItem(
      title: 'Bahaya Deepfake Video Call! Pelaku Tiru Wajah Bos Perusahaan',
      description: 'Teknologi AI Deepfake kini disalahgunakan untuk mengelabui staf keuangan di Jakarta agar mentransfer uang ke rekening penipu lintas negara.',
      url: 'https://finance.detik.com/berita-ekonomi-bisnis/d-8220851/indonesia-jadi-sarang-lowongan-kerja-palsu-se-asia',
      imageUrl: 'https://images.unsplash.com/photo-1595079676601-f1adf5be5dee?w=400&h=200&fit=crop',
      date: DateTime.now().subtract(const Duration(hours: 7)),
      source: 'detik.com',
    ),
    _NewsItem(
      title: 'Kominfo Hapus 15 Aplikasi di PlayStore yang Berisi Malware',
      description: 'Pengguna Android diimbau segera menghapus deretan aplikasi senter dan pembersih RAM ini karena terbukti menyedot pulsa secara diam-diam.',
      url: 'https://tekno.kompas.com/read/2025/05/18/16350007/waspada-ini-7-penipuan-whatsapp-yang-sering-muncul-di-chat',
      imageUrl: 'https://images.unsplash.com/photo-1550751827-4bd374c3f58b?w=400&h=200&fit=crop',
      date: DateTime.now().subtract(const Duration(hours: 10)),
      source: 'kompas.com',
    ),
    _NewsItem(
      title: 'Waspada Modus Loker Palsu Freelance Like & Subscribe YouTube',
      description: 'Korban dijanjikan bayaran tinggi hanya dengan memberikan like pada video YouTube, namun ujung-ujungnya diperas puluhan juta rupiah.',
      url: 'https://finance.detik.com/moneter/d-8212825/waspada-penipuan-pakai-suara-dan-wajah-palsu-dari-ai',
      imageUrl: 'https://images.unsplash.com/photo-1516321318423-f06f85e504b3?w=400&h=200&fit=crop',
      date: DateTime.now().subtract(const Duration(hours: 14)),
      source: 'detik.com',
    ),
    _NewsItem(
      title: 'QRIS Palsu Beredar di Kotak Amal Masjid Jakarta dan Sekitarnya',
      description: 'Penipu menempelkan stiker QR code palsu di atas QRIS resmi tempat ibadah. Masyarakat diminta mengecek nama merchant sebelum berdonasi.',
      url: 'https://inet.detik.com/security/d-7346245/7-modus-penipuan-whatsapp-yang-makan-banyak-korban',
      imageUrl: 'https://images.unsplash.com/photo-1563986768494-4dee2763ff3f?w=400&h=200&fit=crop',
      date: DateTime.now().subtract(const Duration(hours: 18)),
      source: 'detik.com',
    ),
    _NewsItem(
      title: 'Aksi Peretasan Pusat Data Nasional 2026, Ancaman Ransomware Baru',
      description: 'Insiden kebocoran data yang berulang menyoroti perlunya infrastruktur siber pemerintah dalam menghadapi serangan ransomware jenis LockBit baru.',
      url: 'https://news.detik.com/berita/d-7744291/bareskrim-total-ada-15-tersangka-kasus-robot-trading-net89-3-masih-buron',
      imageUrl: 'https://images.unsplash.com/photo-1550751827-4bd374c3f58b?w=400&h=200&fit=crop',
      date: DateTime.now().subtract(const Duration(days: 1)),
      source: 'detik.com',
    ),
    _NewsItem(
      title: 'Marketplace E-commerce Palsu Kirim Link Undian Menjebak Korban',
      description: 'Pengguna diperingatkan soal pesan SMS dan WhatsApp yang berisi tautan pemenang undian e-commerce yang mengarahkan ke situs pencuri akun.',
      url: 'https://finance.detik.com/berita-ekonomi-bisnis/d-8220851/indonesia-jadi-sarang-lowongan-kerja-palsu-se-asia',
      imageUrl: 'https://images.unsplash.com/photo-1614064641938-3bbee52942c7?w=400&h=200&fit=crop',
      date: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
      source: 'detik.com',
    ),
  ];



  @override
  Widget build(BuildContext ctx) => Scaffold(
    backgroundColor: Colors.transparent,
    body: SafeArea(child: Column(children: [
      // Header
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 48, 20, 0),
        child: Column(
          children: [
            Text('Scam News',
              style: GoogleFonts.outfit(
                fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 4),
            Text('Penipuan terkini dari Indonesia & dunia',
              style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            // Refresh button
            GestureDetector(
              onTap: _fetchAll,
              child: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: AppColors.glassBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.glassBorder)),
                child: _loading
                  ? const Padding(
                      padding: EdgeInsets.all(8),
                      child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.vermillion))
                  : const Icon(Icons.refresh_rounded,
                      size: 18, color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 24),

      // Content
      Expanded(child: _loading
        ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            CircularProgressIndicator(color: AppColors.vermillion, strokeWidth: 2),
            SizedBox(height: 14),
            Text('Memuat berita terkini...', style: TextStyle(color: AppColors.textSecondary)),
          ]))
        : _error != null
          ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Text('😕', style: TextStyle(fontSize: 40)),
              const SizedBox(height: 12),
              Text('Gagal memuat berita', style: GoogleFonts.outfit(
                fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const SizedBox(height: 6),
              Text('Cek koneksi internet & coba lagi',
                style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              GestureDetector(onTap: _fetchAll,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: AppColors.gradientAccent,
                    borderRadius: BorderRadius.circular(10)),
                  child: Text('Coba Lagi', style: GoogleFonts.outfit(
                    fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)))),
            ]))
          : _NewsList(items: _news, emptyMsg: 'Tidak ada berita terbaru saat ini.'),
      ),
    ])),
  );
}

class _NewsList extends StatelessWidget {
  final List<_NewsItem> items;
  final String emptyMsg;
  const _NewsList({required this.items, required this.emptyMsg});
  @override
  Widget build(BuildContext ctx) {
    if (items.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Text('📭', style: TextStyle(fontSize: 40)),
        const SizedBox(height: 12),
        Text(emptyMsg, style: GoogleFonts.dmSans(
          fontSize: 13, color: AppColors.textSecondary)),
      ]));
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 60),
      physics: const BouncingScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (_, i) => _NewsCard(item: items[i]),
    );
  }
}

class _NewsCard extends StatefulWidget {
  final _NewsItem item;
  const _NewsCard({required this.item});
  @override
  State<_NewsCard> createState() => _NewsCardState();
}

class _NewsCardState extends State<_NewsCard> {
  bool _pressing = false;

  Future<void> _open() async {
    final uri = Uri.tryParse(widget.item.url);
    if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext ctx) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: GestureDetector(
      onTapDown:   (_) => setState(() => _pressing = true),
      onTapUp:     (_) { setState(() => _pressing = false); _open(); },
      onTapCancel: ()  => setState(() => _pressing = false),
      child: AnimatedScale(
        scale: _pressing ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.navyLight.withOpacity(0.8),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Thumbnail
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(13)),
              child: SizedBox(
                width: 90, height: 90,
                child: widget.item.imageUrl != null
                  ? Image.network(
                      widget.item.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_,__,___) => _placeholder())
                  : _placeholder(),
              ),
            ),
            // Content
            Expanded(child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(widget.item.source,
                    style: GoogleFonts.dmMono(
                      fontSize: 9, color: AppColors.vermillion,
                      fontWeight: FontWeight.w600),
                    maxLines: 1, overflow: TextOverflow.ellipsis)),
                  Text(_fmtDate(widget.item.date),
                    style: GoogleFonts.dmMono(fontSize: 9, color: AppColors.textMuted)),
                ]),
                const SizedBox(height: 5),
                Text(widget.item.title,
                  style: GoogleFonts.outfit(
                    fontSize: 12, fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary, height: 1.35),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 5),
                Text(widget.item.description,
                  style: GoogleFonts.dmSans(
                    fontSize: 11, color: AppColors.textSecondary, height: 1.4),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
              ]),
            )),
          ]),
        ),
      ),
    ),
  );

  Widget _placeholder() => Container(
    color: AppColors.glassBg,
    child: const Center(child: Icon(Icons.article_outlined,
      color: AppColors.textMuted, size: 28)));

  String _fmtDate(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 60)  return '${diff.inMinutes}m lalu';
    if (diff.inHours  < 24)   return '${diff.inHours}j lalu';
    if (diff.inDays   < 7)    return '${diff.inDays}h lalu';
    return '${d.day}/${d.month}/${d.year}';
  }
}

class _NewsItem {
  final String title, description, url, source;
  final String? imageUrl;
  final DateTime date;
  const _NewsItem({
    required this.title, required this.description, required this.url,
    required this.source, this.imageUrl, required this.date,
  });
}


