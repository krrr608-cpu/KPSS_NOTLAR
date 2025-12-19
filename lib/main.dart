import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const KpssNotlarApp());
}

class KpssNotlarApp extends StatelessWidget {
  const KpssNotlarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'KPSS NOTLAR',
      theme: ThemeData(
        // KPSS için biraz daha ciddi ve okunaklı renkler (Mavi tonları)
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1565C0)),
        useMaterial3: true,
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
  List<Map<String, String>> notlar = [];

  @override
  void initState() {
    super.initState();
    _notlariYukle();
  }

  Future<void> _notlariYukle() async {
    final prefs = await SharedPreferences.getInstance();
    final String? kayitliNotlar = prefs.getString('kpss_notlari_v1');
    if (kayitliNotlar != null) {
      setState(() {
        notlar = List<Map<String, String>>.from(json.decode(kayitliNotlar));
      });
    }
  }

  Future<void> _notlariKaydet() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('kpss_notlari_v1', json.encode(notlar));
  }

  void _notEkle(String ders, String icerik) {
    setState(() {
      notlar.insert(0, {'ders': ders, 'icerik': icerik});
    });
    _notlariKaydet();
  }

  void _notSil(int index) {
    setState(() {
      notlar.removeAt(index);
    });
    _notlariKaydet();
  }

  void _notEklePenceresiAc() {
    String dersAdi = "";
    String notIcerigi = "";
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("KPSS Notu Ekle"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: "Ders (Örn: Tarih, Vatandaşlık)", 
                border: OutlineInputBorder()
              ),
              onChanged: (val) => dersAdi = val,
            ),
            const SizedBox(height: 10),
            TextField(
              decoration: const InputDecoration(
                labelText: "Notun (Örn: Islahat Fermanı...)", 
                border: OutlineInputBorder()
              ),
              maxLines: 4,
              onChanged: (val) => notIcerigi = val,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
          FilledButton(
            onPressed: () {
              if (dersAdi.isNotEmpty && notIcerigi.isNotEmpty) {
                _notEkle(dersAdi, notIcerigi);
                Navigator.pop(context);
              }
            },
            child: const Text("Kaydet"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("KPSS NOTLAR", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: notlar.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  "Henüz notun yok.\nKPSS çalışmalarını kaydetmek için\n+ butonuna bas!",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: notlar.length,
              itemBuilder: (context, index) {
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      child: Text(
                        notlar[index]['ders']!.isNotEmpty ? notlar[index]['ders']![0].toUpperCase() : "?",
                        style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer),
                      ),
                    ),
                    title: Text(notlar[index]['ders']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 5.0),
                      child: Text(notlar[index]['icerik']!),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red), 
                      onPressed: () => _notSil(index)
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _notEklePenceresiAc, 
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}
