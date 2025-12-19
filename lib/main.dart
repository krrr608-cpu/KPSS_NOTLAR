import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const KpssOnlineApp());
}

class KpssOnlineApp extends StatelessWidget {
  const KpssOnlineApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'KPSS Notları',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1565C0)),
        useMaterial3: true,
      ),
      home: const NotlarSayfasi(),
    );
  }
}

class NotlarSayfasi extends StatefulWidget {
  const NotlarSayfasi({super.key});

  @override
  State<NotlarSayfasi> createState() => _NotlarSayfasiState();
}

class _NotlarSayfasiState extends State<NotlarSayfasi> {
  List<dynamic> notlar = [];
  String dinamikBaslik = "KPSS CANLI NOTLAR"; 
  bool yukleniyor = true;
  bool hataVar = false;
  String hataMesaji = "";

  // SENİN LİNKİNİN TEMİZLENMİŞ HALİ:
  final String url = "https://raw.githubusercontent.com/krrr608-cpu/KPSS_NOTLAR/main/notlar.json";

  @override
  void initState() {
    super.initState();
    verileriCek();
  }

  Future<void> verileriCek() async {
    setState(() {
      yukleniyor = true;
      hataVar = false;
      hataMesaji = "";
    });

    try {
      // URL'in sonuna rastgele sayı ekliyoruz ki telefon eski dosyayı hatırlamasın
      final baglanti = "$url?v=${DateTime.now().millisecondsSinceEpoch}";
      print("İstek atılan adres: $baglanti");

      final response = await http.get(Uri.parse(baglanti));
      
      if (response.statusCode == 200) {
        // Türkçe karakterleri düzelt
        final body = utf8.decode(response.bodyBytes);
        final decodedData = json.decode(body);
        
        // --- HEM ESKİ HEM YENİ FORMATI DESTEKLEYEN YAPI ---
        if (decodedData is Map) {
          // Eğer JSON dosyan süslü parantez {} ile başlıyorsa (Yeni Format)
          setState(() {
            dinamikBaslik = decodedData['uygulama_basligi'] ?? "KPSS CANLI TAKİP";
            notlar = decodedData['notlar_listesi'] ?? [];
            yukleniyor = false;
          });
        } else if (decodedData is List) {
          // Eğer JSON dosyan köşeli parantez [] ile başlıyorsa (Eski Format)
          setState(() {
            notlar = decodedData;
            dinamikBaslik = "KPSS NOTLARI";
            yukleniyor = false;
          });
        } else {
          throw Exception("Veri formatı tanınamadı. (Ne [] ne de {} ile başlıyor)");
        }

      } else {
        throw Exception('Dosya Bulunamadı (Hata Kodu: ${response.statusCode})');
      }
    } catch (e) {
      print("Hata: $e");
      setState(() {
        hataVar = true;
        hataMesaji = "Bağlantı Hatası:\n$e"; 
        yukleniyor = false;
      });
    }
  }

  // Renk kodunu (Hex) renge çeviren fonksiyon
  Color hexToColor(String? hexString) {
    if (hexString == null || hexString.isEmpty) return Colors.indigo;
    try {
      final buffer = StringBuffer();
      if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
      buffer.write(hexString.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (e) {
      return Colors.indigo;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(dinamikBaslik, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: verileriCek,
          )
        ],
      ),
      body: yukleniyor
          ? const Center(child: CircularProgressIndicator())
          : hataVar
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.wifi_off, size: 60, color: Colors.red),
                          const SizedBox(height: 10),
                          const Text("Veriler Çekilemedi", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          const SizedBox(height: 10),
                          Text(hataMesaji, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
                          const SizedBox(height: 20),
                          ElevatedButton(onPressed: verileriCek, child: const Text("Tekrar Dene"))
                        ],
                      ),
                    ),
                  ),
                )
              : notlar.isEmpty
                  ? const Center(child: Text("Listelenecek not bulunamadı."))
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: notlar.length,
                      itemBuilder: (context, index) {
                        final not = notlar[index];
                        final dersRengi = hexToColor(not['renk']);
                        
                        return Card(
                          elevation: 3,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border(left: BorderSide(color: dersRengi, width: 6)),
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.white,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Ders Etiketi
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: dersRengi,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      not['ders'] ?? 'Genel',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  // Başlık
                                  Text(
                                    not['baslik'] ?? '',
                                    style: const TextStyle(
                                        fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                  const Divider(thickness: 1, height: 20),
                                  // İçerik
                                  Text(
                                    not['icerik'] ?? '',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
