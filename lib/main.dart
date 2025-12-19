import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const KpssRenkliApp());
}

class KpssRenkliApp extends StatelessWidget {
  const KpssRenkliApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'KPSS Notları',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
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

class AnaSayfa extends StatefulWidget {
  const AnaSayfa({super.key});

  @override
  State<AnaSayfa> createState() => _AnaSayfaState();
}

class _AnaSayfaState extends State<AnaSayfa> {
  List<dynamic> tumNotlar = [];
  List<String> dersler = [];
  Map<String, Color> kategoriRenkleri = {}; // Renkleri burada tutacağız
  
  String uygulamaBasligi = "Yükleniyor...";
  bool yukleniyor = true;
  String hataMesaji = "";

  // SENİN GİTHUB LİNKİN:
  final String url = "https://raw.githubusercontent.com/krrr608-cpu/KPSS_NOTLAR/main/notlar.json";

  @override
  void initState() {
    super.initState();
    verileriCek();
  }

  Future<void> verileriCek() async {
    setState(() { yukleniyor = true; hataMesaji = ""; });

    try {
      final baglanti = "$url?v=${DateTime.now().millisecondsSinceEpoch}";
      final response = await http.get(Uri.parse(baglanti));
      
      if (response.statusCode == 200) {
        final body = utf8.decode(response.bodyBytes);
        final decodedData = json.decode(body);
        
        List<dynamic> gelenNotlar = [];
        Map<String, Color> gelenRenkler = {};
        String yeniBaslik = "KPSS NOTLAR";

        // JSON Format Kontrolü
        if (decodedData is Map) {
          yeniBaslik = decodedData['uygulama_basligi'] ?? "KPSS NOTLAR";
          gelenNotlar = decodedData['notlar_listesi'] ?? [];

          // Kategori Renklerini Okuma
          if (decodedData['kategori_renkleri'] != null) {
            Map<String, dynamic> renkMap = decodedData['kategori_renkleri'];
            renkMap.forEach((dersAdi, hexKodu) {
              gelenRenkler[dersAdi] = hexToColor(hexKodu);
            });
          }
        } else if (decodedData is List) {
          gelenNotlar = decodedData; // Eski format desteği
        }

        // Dersleri Ayıklama
        Set<String> benzersizDersler = {};
        for (var not in gelenNotlar) {
          benzersizDersler.add(not['ders'] ?? "Genel");
        }

        setState(() {
          tumNotlar = gelenNotlar;
          dersler = benzersizDersler.toList();
          kategoriRenkleri = gelenRenkler;
          uygulamaBasligi = yeniBaslik;
          yukleniyor = false;
        });
      } else {
        throw Exception('Bağlantı hatası: ${response.statusCode}');
      }
    } catch (e) {
      setState(() { hataMesaji = "Veri alınamadı: $e"; yukleniyor = false; });
    }
  }

  Color hexToColor(String? hexString) {
    if (hexString == null || hexString.isEmpty) return Colors.blueGrey;
    try {
      final buffer = StringBuffer();
      if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
      buffer.write(hexString.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (e) { return Colors.blueGrey; }
  }

  // Rengi bulamazsa varsayılan gri döndürür
  Color rengiGetir(String dersAdi) {
    return kategoriRenkleri[dersAdi] ?? Colors.blueGrey;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(uygulamaBasligi),
        backgroundColor: Colors.blueGrey[900], // Ana başlık koyu olsun
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: verileriCek)],
      ),
      body: yukleniyor
          ? const Center(child: CircularProgressIndicator())
          : hataMesaji.isNotEmpty
              ? Center(child: Padding(padding: const EdgeInsets.all(20), child: Text(hataMesaji)))
              : GridView.builder(
                  padding: const EdgeInsets.all(15),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.3,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                  ),
                  itemCount: dersler.length,
                  itemBuilder: (context, index) {
                    String dersAdi = dersler[index];
                    Color dersRengi = rengiGetir(dersAdi);

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DersKonulariSayfasi(
                              secilenDers: dersAdi,
                              tumNotlar: tumNotlar,
                              temaRengi: dersRengi,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: dersRengi,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(color: Colors.black26, blurRadius: 5, offset: const Offset(2, 4))
                          ]
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Dersin Baş harfi simgesi
                            CircleAvatar(
                              backgroundColor: Colors.white24,
                              radius: 25,
                              child: Text(dersAdi.substring(0,1).toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24)),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              dersAdi.toUpperCase(),
                              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

// --- 2. SAYFA: DERS KONULARI ---
class DersKonulariSayfasi extends StatelessWidget {
  final String secilenDers;
  final List<dynamic> tumNotlar;
  final Color temaRengi;

  const DersKonulariSayfasi({super.key, required this.secilenDers, required this.tumNotlar, required this.temaRengi});

  @override
  Widget build(BuildContext context) {
    final dersinNotlari = tumNotlar.where((not) => not['ders'] == secilenDers).toList();

    return Scaffold(
      appBar: AppBar(title: Text(secilenDers.toUpperCase()), backgroundColor: temaRengi),
      body: ListView.builder(
        padding: const EdgeInsets.all(10),
        itemCount: dersinNotlari.length,
        itemBuilder: (context, index) {
          final not = dersinNotlari[index];
          return Card(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              contentPadding: const EdgeInsets.all(10),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: temaRengi.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: Icon(Icons.bookmarks, color: temaRengi),
              ),
              title: Text(not['baslik'] ?? "Başlıksız", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => NotDetaySayfasi(not: not, temaRengi: temaRengi)));
              },
            ),
          );
        },
      ),
    );
  }
}

// --- 3. SAYFA: NOT DETAYI ---
class NotDetaySayfasi extends StatelessWidget {
  final dynamic not;
  final Color temaRengi;

  const NotDetaySayfasi({super.key, required this.not, required this.temaRengi});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Not Detayı"), backgroundColor: temaRengi),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             // Üstteki süslü başlık kutusu
             Container(
               width: double.infinity,
               padding: const EdgeInsets.all(15),
               decoration: BoxDecoration(
                 color: temaRengi.withOpacity(0.1),
                 borderRadius: BorderRadius.circular(15),
                 border: Border.all(color: temaRengi.withOpacity(0.5))
               ),
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   Text(not['ders'] ?? "", style: TextStyle(color: temaRengi, fontWeight: FontWeight.bold)),
                   const SizedBox(height: 5),
                   Text(not['baslik'] ?? "", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
                 ],
               ),
             ),
             const SizedBox(height: 20),
             Text(not['icerik'] ?? "", style: const TextStyle(fontSize: 18, height: 1.6, color: Colors.black87)),
          ],
        ),
      ),
    );
  }
}
