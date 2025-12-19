import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const KpssKategoriApp());
}

class KpssKategoriApp extends StatelessWidget {
  const KpssKategoriApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ders Notları',
      // Varsayılan tema (Veri gelene kadar bu renk görünür)
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          titleTextStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
          iconTheme: IconThemeData(color: Colors.white),
        ),
      ),
      home: const AnaSayfa(),
    );
  }
}

// --- 1. SAYFA: KATEGORİLER VE AYARLAR ---
class AnaSayfa extends StatefulWidget {
  const AnaSayfa({super.key});

  @override
  State<AnaSayfa> createState() => _AnaSayfaState();
}

class _AnaSayfaState extends State<AnaSayfa> {
  List<dynamic> tumNotlar = [];
  List<String> dersler = [];
  
  // -- DİNAMİK AYARLAR (Varsayılanlar) --
  String uygulamaBasligi = "Yükleniyor...";
  Color uygulamaRengi = Colors.deepPurple;
  
  bool yukleniyor = true;
  String hataMesaji = "";

  // GİTHUB LİNKİN (Burası sabit kalacak):
  final String url = "https://raw.githubusercontent.com/krrr608-cpu/KPSS_NOTLAR/main/notlar.json";

  @override
  void initState() {
    super.initState();
    verileriCek();
  }

  Future<void> verileriCek() async {
    setState(() { yukleniyor = true; hataMesaji = ""; });

    try {
      // Cache (Önbellek) sorununu aşmak için linke zaman damgası ekliyoruz
      final baglanti = "$url?v=${DateTime.now().millisecondsSinceEpoch}";
      final response = await http.get(Uri.parse(baglanti));
      
      if (response.statusCode == 200) {
        final body = utf8.decode(response.bodyBytes);
        final decodedData = json.decode(body);
        
        List<dynamic> gelenNotlar = [];
        String yeniBaslik = "KPSS NOTLAR";
        Color yeniRenk = Colors.deepPurple;

        // --- YENİ JSON FORMATI KONTROLÜ ---
        if (decodedData is Map) {
          // 1. Ayarları Çek
          if (decodedData.containsKey('ayarlar')) {
            yeniBaslik = decodedData['ayarlar']['baslik'] ?? "KPSS NOTLAR";
            yeniRenk = hexToColor(decodedData['ayarlar']['ana_renk']);
          } else {
             // Eğer ayarlar yoksa eski usül başlık varsa onu al
             yeniBaslik = decodedData['uygulama_basligi'] ?? "KPSS NOTLAR";
          }

          // 2. Notları Çek
          gelenNotlar = decodedData['notlar_listesi'] ?? [];
        } 
        else if (decodedData is List) {
          // Eski format (Sadece liste) gelirse bozulmasın
          gelenNotlar = decodedData;
        }

        // 3. Dersleri Grupla
        Set<String> benzersizDersler = {};
        for (var not in gelenNotlar) {
          benzersizDersler.add(not['ders'] ?? "Genel");
        }

        setState(() {
          tumNotlar = gelenNotlar;
          dersler = benzersizDersler.toList();
          uygulamaBasligi = yeniBaslik;
          uygulamaRengi = yeniRenk;
          yukleniyor = false;
        });
      } else {
        throw Exception('Bağlantı hatası: ${response.statusCode}');
      }
    } catch (e) {
      setState(() { hataMesaji = "Veri alınamadı:\n$e"; yukleniyor = false; });
    }
  }

  Color hexToColor(String? hexString) {
    if (hexString == null || hexString.isEmpty) return Colors.deepPurple;
    try {
      final buffer = StringBuffer();
      if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
      buffer.write(hexString.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (e) { return Colors.deepPurple; }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(uygulamaBasligi), // JSON'dan gelen başlık
        backgroundColor: uygulamaRengi, // JSON'dan gelen renk
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh), 
            onPressed: verileriCek
          )
        ],
      ),
      body: yukleniyor
          ? Center(child: CircularProgressIndicator(color: uygulamaRengi))
          : hataMesaji.isNotEmpty
              ? Center(child: Padding(padding: const EdgeInsets.all(20), child: Text(hataMesaji, textAlign: TextAlign.center)))
              : dersler.isEmpty 
                  ? const Center(child: Text("Gösterilecek ders bulunamadı."))
                  : Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 1.4,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: dersler.length,
                        itemBuilder: (context, index) {
                          String dersAdi = dersler[index];
                          return GestureDetector(
                            onTap: () {
                              // Diğer sayfaya rengi ve veriyi taşıyoruz
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => DersKonulariSayfasi(
                                    secilenDers: dersAdi,
                                    tumNotlar: tumNotlar,
                                    temaRengi: uygulamaRengi, // Rengi aktar
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: uygulamaRengi, // Kutular da o renkte olsun
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 5, offset: const Offset(2, 2))
                                ]
                              ),
                              child: Center(
                                child: Text(
                                  dersAdi.toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}

// --- 2. SAYFA: DERS İÇERİĞİ ---
class DersKonulariSayfasi extends StatelessWidget {
  final String secilenDers;
  final List<dynamic> tumNotlar;
  final Color temaRengi;

  const DersKonulariSayfasi({
    super.key,
    required this.secilenDers,
    required this.tumNotlar,
    required this.temaRengi,
  });

  @override
  Widget build(BuildContext context) {
    final dersinNotlari = tumNotlar.where((not) => not['ders'] == secilenDers).
