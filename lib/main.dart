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
      title: 'KPSS Notları',
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

class AnaSayfa extends StatefulWidget {
  const AnaSayfa({super.key});

  @override
  State<AnaSayfa> createState() => _AnaSayfaState();
}

class _AnaSayfaState extends State<AnaSayfa> {
  List<dynamic> tumNotlar = [];
  List<String> dersler = [];
  String uygulamaBasligi = "Yükleniyor...";
  Color uygulamaRengi = Colors.deepPurple;
  bool yukleniyor = true;
  String hataMesaji = "";

  // LİNKİN:
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
        String yeniBaslik = "KPSS NOTLAR";
        Color yeniRenk = Colors.deepPurple;

        if (decodedData is Map) {
          if (decodedData.containsKey('ayarlar')) {
            yeniBaslik = decodedData['ayarlar']['baslik'] ?? "KPSS NOTLAR";
            yeniRenk = hexToColor(decodedData['ayarlar']['ana_renk']);
          } else {
             yeniBaslik = decodedData['uygulama_basligi'] ?? "KPSS NOTLAR";
          }
          gelenNotlar = decodedData['notlar_listesi'] ?? [];
        } else if (decodedData is List) {
          gelenNotlar = decodedData;
        }

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
      setState(() { hataMesaji = "Veri alınamadı. İnternetini kontrol et."; yukleniyor = false; });
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
        title: Text(uygulamaBasligi),
        backgroundColor: uygulamaRengi,
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: verileriCek)],
      ),
      body: yukleniyor
          ? Center(child: CircularProgressIndicator(color: uygulamaRengi))
          : hataMesaji.isNotEmpty
              ? Center(child: Text(hataMesaji))
              : GridView.builder(
                  padding: const EdgeInsets.all(12),
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
                        Navigator.push(context, MaterialPageRoute(builder: (context) => DersKonulariSayfasi(secilenDers: dersAdi, tumNotlar: tumNotlar, temaRengi: uygulamaRengi)));
                      },
                      child: Container(
                        decoration: BoxDecoration(color: uygulamaRengi, borderRadius: BorderRadius.circular(15)),
                        child: Center(child: Text(dersAdi.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
                      ),
                    );
                  },
                ),
    );
  }
}

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
            child: ListTile(
              title: Text(not['baslik'] ?? "Başlıksız", style: const TextStyle(fontWeight: FontWeight.bold)),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => NotDetaySayfasi(not: not, temaRengi: temaRengi))),
            ),
          );
        },
      ),
    );
  }
}

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
            Text(not['baslik'] ?? "", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const Divider(),
            Text(not['icerik'] ?? "", style: const TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}
