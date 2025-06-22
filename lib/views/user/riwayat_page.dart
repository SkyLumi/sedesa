import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:project_akhir_sedesa/config.dart';
import 'package:project_akhir_sedesa/service/jwt_service.dart';
import 'package:project_akhir_sedesa/views/user/surat_detail_page.dart';

class SuratRiwayat {
  final int id;
  final String status;
  final String jenisSurat;
  final DateTime createdAt;

  SuratRiwayat({
    required this.id,
    required this.status,
    required this.jenisSurat,
    required this.createdAt,
  });

  factory SuratRiwayat.fromJson(Map<String, dynamic> json) {
    return SuratRiwayat(
      id: json['id'],
      status: json['status'],
      jenisSurat: json['jenis_surat'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class RiwayatPage extends StatefulWidget {
  const RiwayatPage({super.key});

  @override
  State<RiwayatPage> createState() => _RiwayatPageState();
}

class _RiwayatPageState extends State<RiwayatPage> {
  List<SuratRiwayat> _riwayat = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRiwayat();
  }

  Future<void> _fetchRiwayat() async {
    setState(() => _isLoading = true);
    try {
      final token = await getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/api/surat/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _riwayat = data.map((e) => SuratRiwayat.fromJson(e)).toList();
        });
      }
    } catch (e) {
      // Optionally show error
    }
    setState(() => _isLoading = false);
  }

  String getSuratDisplayName(String jenisSurat) {
    switch (jenisSurat) {
      case 'usaha':
        return 'Surat Keterangan Usaha';
      case 'kematian':
        return 'Surat Keterangan Kematian';
      case 'tidak_mampu':
        return 'Surat Keterangan Tidak Mampu';
      default:
        return jenisSurat;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Riwayat Surat',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _riwayat.isEmpty
                      ? const Center(child: Text('Belum ada riwayat surat.'))
                      : ListView.builder(
                          itemCount: _riwayat.length,
                          itemBuilder: (context, index) {
                            final surat = _riwayat[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => SuratDetailPage(surat: surat),
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: ListTile(
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2E7D32).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.description,
                                      color: Color(0xFF2E7D32),
                                    ),
                                  ),
                                  title: Text(getSuratDisplayName(surat.jenisSurat)),
                                  subtitle: Text('Tanggal: ${surat.createdAt.toString().split(' ')[0]}'),
                                  trailing: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: surat.status == 'selesai'
                                          ? const Color(0xFF4CAF50)
                                          : surat.status == 'pending'
                                              ? const Color(0xFFFF9800)
                                              : Colors.grey,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      surat.status[0].toUpperCase() + surat.status.substring(1),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}