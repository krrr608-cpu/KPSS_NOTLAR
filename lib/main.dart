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
      title: 'KPSS CANLI NOTLAR',
      theme: ThemeData(
        // Uygulamanın ana rengi
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
  bool yukleniyor = true;
  bool hataVar = false;

  // SENİN GÖNDERDİĞİN LİNK BURADA:
  final String url = "https://raw.githubusercontent.com/krrr608-cpu/KPSS_NOTLAR/refs/heads/main/notlar.json";

  @override
  void initState() {
    super.initState();
    verileriCek();
  }

  // İnternetten veriyi çeken fonksiyon
  Future<void> verileriCek() async {
    setState(() {
      yukleniyor = true;
      hataVar = false;
    });

    try {
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        // Türkçe karakterleri düzgün göstermek için utf8.decode kullanıyoruz
        final decodedData = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          notlar = decodedData;
          yukleniyor = false;
        });
      } else {
        throw Exception('Veri yüklenemedi: ${response.statusCode}');
      }
    } catch (e) {
      print("Hata: $e");
      setState(() {
        hataVar = true;
        yukleniyor = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("KPSS CANLI NOTLAR", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: verileriCek, // Yenile butonu
            tooltip: 'Notları Güncelle',
          )
        ],
      ),
      body: yukleniyor
          ? const Center(child: CircularProgressIndicator()) // Yükleniyor simgesi
          : hataVar
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.wifi_off, size: 60, color: Colors.red),
                      const SizedBox(height: 10),
                      const Text("Notlar yüklenemedi.", style: TextStyle(fontSize: 18)),
                      const Text("İnternet bağlantını kontrol et.", style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 20),
                      ElevatedButton(onPressed: verileriCek, child: const Text("Tekrar Dene"))
                    ],
                  ),
                )
              : notlar.isEmpty 
                ? const Center(child: Text("Henüz hiç not eklenmemiş."))
                : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: notlar.length,
                  itemBuilder: (context, index) {
                    final not = notlar[index];
                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Ders Adı Etiketi
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                not['ders'] ?? 'Genel',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            // Konu Başlığı
                            Text(
                              not['baslik'] ?? 'Başlıksız',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                            ),
                            const Divider(thickness: 1, height: 20),
                            // Not İçeriği
                            Text(
                              not['icerik'] ?? '',
                              style: const TextStyle(fontSize: 16, color: Colors.black87, height: 1.4),
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
