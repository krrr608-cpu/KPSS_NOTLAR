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

  // LİNKİN AYNI KALIYOR
  final String url = "https://raw.githubusercontent.com/krrr608-cpu/KPSS_NOTLAR/refs/heads/main/notlar.json";

  @override
  void initState() {
    super.initState();
    verileriCek();
  }

  Future<void> verileriCek() async {
    setState(() {
      yukleniyor = true;
      hataVar = false;
    });

    try {
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final decodedData = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          notlar = decodedData;
          yukleniyor = false;
        });
      } else {
        throw Exception('Veri yüklenemedi');
      }
    } catch (e) {
      setState(() {
        hataVar = true;
        yukleniyor = false;
      });
    }
  }

  // RENK DÖNÜŞTÜRÜCÜ FONKSİYON
  // Gelen "#FF0000" kodunu Flutter rengine çevirir.
  Color hexToColor(String? hexString) {
    if (hexString == null || hexString.isEmpty) {
      return Colors.indigo; // Renk yazılmamışsa varsayılan renk
    }
    try {
      final buffer = StringBuffer();
      if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
      buffer.write(hexString.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (e) {
      return Colors.indigo; // Hatalı kod girilirse varsayılan renk
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
            onPressed: verileriCek,
          )
        ],
      ),
      body: yukleniyor
          ? const Center(child: CircularProgressIndicator())
          : hataVar
              ? Center(
                  child: ElevatedButton(onPressed: verileriCek, child: const Text("Tekrar Dene")),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: notlar.length,
                  itemBuilder: (context, index) {
                    final not = notlar[index];
                    // JSON'dan gelen renk kodunu renge çeviriyoruz
                    final dersRengi = hexToColor(not['renk']);

                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      // Kartın sol tarafına ince renkli çizgi ekledim, şık durur
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
                              Row(
                                children: [
                                  // Kategori Etiketi (Senin belirlediğin renkte olacak)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: dersRengi, // DİNAMİK RENK BURADA
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      not['ders'] ?? 'Genel',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                not['baslik'] ?? '',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                              ),
                              const Divider(thickness: 1, height: 20),
                              Text(
                                not['icerik'] ?? '',
                                style: const TextStyle(fontSize: 16, color: Colors.black87),
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
