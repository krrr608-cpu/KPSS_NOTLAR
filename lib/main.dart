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
  String dinamikBaslik = "Yükleniyor..."; // Başlangıçta yazacak metin
  bool yukleniyor = true;
  bool hataVar = false;
  String hataMesaji = "";

  // BURASI SENİN GİTHUB LİNKİN (Aynı kalacak)
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
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        // UTF-8 karakter sorunu çözümü
        final decodedData = json.decode(utf8.decode(response.bodyBytes));
        
        setState(() {
          // JSON dosyasından başlığı alıyoruz
          dinamikBaslik = decodedData['uygulama_basligi'] ?? "KPSS NOTLAR";
          
          // JSON dosyasından not listesini alıyoruz
          notlar = decodedData['notlar_listesi'] ?? [];
          
          yukleniyor = false;
        });
      } else {
        throw Exception('Bağlantı Hatası: ${response.statusCode}');
      }
    } catch (e) {
      print("Hata: $e");
      setState(() {
        hataVar = true;
        hataMesaji = "Veri formatı hatalı veya internet yok.\nGitHub JSON dosyasını kontrol et."; 
        yukleniyor = false;
      });
    }
  }

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
        // ARTIK BAŞLIK İNTERNETTEN GELİYOR:
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
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 60, color: Colors.red),
                        const SizedBox(height: 10),
                        const Text("Hata Oluştu", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        const SizedBox(height: 5),
                        Text(hataMesaji, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[700])),
                        const SizedBox(height: 20),
                        ElevatedButton(onPressed: verileriCek, child: const Text("Tekrar Dene"))
                      ],
                    ),
                  ),
                )
              : notlar.isEmpty
                  ? const Center(child: Text("Henüz not eklenmemiş."))
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
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: dersRengi,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      not['ders'] ?? 'Ders',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    not['baslik'] ?? '',
                                    style: const TextStyle(
                                        fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                  const Divider(thickness: 1, height: 20),
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
