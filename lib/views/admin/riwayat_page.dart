import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:project_akhir_sedesa/config.dart';
import 'package:project_akhir_sedesa/service/jwt_service.dart';
import 'home_page.dart';
import 'nik_data_page.dart';
import 'surat_detail_page.dart';

class AdminSuratRiwayat {
  final int id;
  final String status;
  final String jenisSurat;
  final DateTime createdAt;
  final String? namaPemohon;
  final String? nikPemohon;

  AdminSuratRiwayat({
    required this.id,
    required this.status,
    required this.jenisSurat,
    required this.createdAt,
    this.namaPemohon,
    this.nikPemohon,
  });

  factory AdminSuratRiwayat.fromJson(Map<String, dynamic> json) {
    return AdminSuratRiwayat(
      id: json['id'],
      status: json['status'],
      jenisSurat: json['jenis_surat'],
      createdAt: DateTime.parse(json['created_at']),
      namaPemohon: json['nama'],
      nikPemohon: json['nik'],
    );
  }
}

class RiwayatPage extends StatefulWidget {
  const RiwayatPage({super.key});

  @override
  State<RiwayatPage> createState() => _RiwayatPageState();
}

class _RiwayatPageState extends State<RiwayatPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<AdminSuratRiwayat> _pending = [];
  List<AdminSuratRiwayat> _approved = [];
  List<AdminSuratRiwayat> _rejected = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchRiwayat();
  }

  Future<void> _fetchRiwayat() async {
    setState(() => _isLoading = true);
    try {
      final token = await getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/api/surat/admin/all'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final all = data.map((e) => AdminSuratRiwayat.fromJson(e)).toList();
        setState(() {
          _pending = all.where((e) => e.status == 'pending').toList();
          _approved = all.where((e) => e.status == 'disetujui' || e.status == 'selesai').toList();
          _rejected = all.where((e) => e.status == 'ditolak').toList();
        });
      }
    } catch (e) {
      // Optionally show error
    }
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0),
        title: const Text('Riwayat Verifikasi', style: TextStyle(color: Colors.white)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Disetujui'),
            Tab(text: 'Ditolak'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildRequestList(_pending, null),
                _buildRequestList(_approved, true),
                _buildRequestList(_rejected, false),
              ],
            ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: 1,
          onTap: (index) {
            if (index == 1) return;
            if (index == 0) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const AdminHomePage()),
              );
            } else if (index == 2) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const NIKDataPage()),
              );
            } else if (index == 3) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Halaman Maps belum tersedia'),
                  backgroundColor: Color(0xFF1565C0),
                ),
              );
            }
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF1565C0),
          unselectedItemColor: Colors.grey,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.pending_actions),
              label: 'Riwayat',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people),
              label: 'NIK Data',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.location_on_rounded),
              label: 'Maps',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestList(List<AdminSuratRiwayat> requests, bool? isApproved) {
    if (requests.isEmpty) {
      String emptyText = 'Belum ada permintaan.';
      if (isApproved == true) {
        emptyText = 'Belum ada permintaan yang disetujui.';
      } else if (isApproved == false) {emptyText = 'Belum ada permintaan yang ditolak.';}
      else if (isApproved == null) {emptyText = 'Belum ada permintaan pending.';}
      return Center(
        child: Text(
          emptyText,
          style: const TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final request = requests[index];
        return _buildHistoryCard(request, isApproved);
      },
    );
  }

  Widget _buildHistoryCard(AdminSuratRiwayat request, bool? isApproved) {
    Color statusColor;
    String statusText;
    if (isApproved == true) {
      statusColor = Colors.green;
      statusText = 'Disetujui';
    } else if (isApproved == false) {
      statusColor = Colors.red;
      statusText = 'Ditolak';
    } else {
      statusColor = Colors.orange;
      statusText = 'Pending';
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SuratDetailPage(surat: request),
            ),
          );
        },
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: statusColor.withValues(alpha: 0.1),
            child: Text(
              (request.namaPemohon != null && request.namaPemohon!.isNotEmpty)
                  ? request.namaPemohon![0]
                  : '?',
              style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
            ),
          ),
          title: Text(
            request.namaPemohon ?? '-',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(getSuratDisplayName(request.jenisSurat)),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 12, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    request.createdAt.toString().split(' ')[0],
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.badge, size: 12, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    request.nikPemohon ?? '-',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              statusText,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
