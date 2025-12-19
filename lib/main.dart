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
      title: 'KPSS Ders Notları',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1565C0)),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          titleTextStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
          iconTheme: IconThemeData(color: Colors.white),
        ),
      ),
      home: const AnaSayfa(),
    );
  }
}

// --- 1. SAYFA: DERS KATEGORİLERİ ---
class AnaSayfa extends StatefulWidget {
  const AnaSayfa({super.key});

  @override
  State<AnaSayfa> createState() => _AnaSayfaState();
}

class _AnaSayfaState extends State<AnaSayfa> {
  List<dynamic> tumNotlar = [];
  List<String> dersler = []; // Sadece ders isimlerini tutacak liste
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
        
        List<dynamic> gelenVeri = [];
        if (decodedData is Map) {
          gelenVeri = decodedData['notlar_listesi'] ?? [];
        } else if (decodedData is List) {
          gelenVeri = decodedData;
        }

        // DERSLERİ AYIKLA (Her dersten 1 tane olacak şekilde)
        Set<String> benzersizDersler = {};
        for (var not in gelenVeri) {
          benzersizDersler.add(not['ders'] ?? "Diğer");
        }

        setState(() {
          tumNotlar = gelenVeri;
          dersler = benzersizDersler.toList();
          yukleniyor = false;
        });
      } else {
        throw Exception('Bağlantı sorunu: ${response.statusCode}');
      }
    } catch (e) {
      setState(() { hataMesaji = "Hata: $e"; yukleniyor = false; });
    }
  }

  // O dersin rengini bulmak için yardımcı fonksiyon
  Color rengiBul(String dersAdi) {
    var not = tumNotlar.firstWhere((element) => element['ders'] == dersAdi, orElse: () => null);
    if (not != null && not['renk'] != null) {
      return hexToColor(not['renk']);
    }
    return Colors.indigo;
  }

  Color hexToColor(String? hexString) {
    if (hexString == null || hexString.isEmpty) return Colors.indigo;
    try {
      final buffer = StringBuffer();
      if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
      buffer.write(hexString.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (e) { return Colors.indigo; }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("DERS SEÇİMİ"),
        backgroundColor: Colors.indigo,
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: verileriCek)],
      ),
      body: yukleniyor
          ? const Center(child: CircularProgressIndicator())
          : hataMesaji.isNotEmpty
              ? Center(child: Text(hataMesaji))
              : Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, // Yan yana 2 kutu
                      childAspectRatio: 1.5,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: dersler.length,
                    itemBuilder: (context, index) {
                      String dersAdi = dersler[index];
                      Color dersRengi = rengiBul(dersAdi);

                      return GestureDetector(
                        onTap: () {
                          // Tıklanınca o dersin sayfasına git
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DersKonulariSayfasi(
                                secilenDers: dersAdi,
                                tumNotlar: tumNotlar,
                                dersRengi: dersRengi,
                              ),
                            ),
                          );
                        },
                        child: Card(
                          color: dersRengi,
                          elevation: 4,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          child: Center(
                            child: Text(
                              dersAdi.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
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

// --- 2. SAYFA: SEÇİLEN DERSİN KONULARI ---
class DersKonulariSayfasi extends StatelessWidget {
  final String secilenDers;
  final List<dynamic> tumNotlar;
  final Color dersRengi;

  const DersKonulariSayfasi({
    super.key,
    required this.secilenDers,
    required this.tumNotlar,
    required this.dersRengi,
  });

  @override
  Widget build(BuildContext context) {
    // Sadece seçilen derse ait notları filtrele
    final dersinNotlari = tumNotlar.where((not) => not['ders'] == secilenDers).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(secilenDers.toUpperCase()),
        backgroundColor: dersRengi,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(10),
        itemCount: dersinNotlari.length,
        itemBuilder: (context, index) {
          final not = dersinNotlari[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            elevation: 2,
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: dersRengi.withOpacity(0.2),
                child: Icon(Icons.menu_book, color: dersRengi),
              ),
              title: Text(
                not['baslik'] ?? "Başlıksız Konu",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                not['icerik'] != null ? not['icerik'].toString().substring(0, not['icerik'].toString().length > 30 ? 30 : not['icerik'].toString().length) + "..." : "",
                style: const TextStyle(color: Colors.grey),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                // Tıklanınca Detay Sayfasına Git
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NotDetaySayfasi(not: not, temaRengi: dersRengi),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

// --- 3. SAYFA: NOTUN DETAYI ---
class NotDetaySayfasi extends StatelessWidget {
  final dynamic not;
  final Color temaRengi;

  const NotDetaySayfasi({super.key, required this.not, required this.temaRengi});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Not Detayı"),
        backgroundColor: temaRengi,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Konu Başlığı
            Text(
              not['baslik'] ?? "",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: temaRengi,
              ),
            ),
            const Divider(thickness: 2, height: 30),
            // Asıl Not İçeriği
            Text(
              not['icerik'] ?? "",
              style: const TextStyle(
                fontSize: 18,
                height: 1.6, // Satır arası boşluk
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
