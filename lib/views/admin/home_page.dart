import 'package:flutter/material.dart';
import 'nik_data_page.dart';
import 'riwayat_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:project_akhir_sedesa/config.dart';
import 'package:project_akhir_sedesa/service/jwt_service.dart';

class PendingRequest {
  final int id;
  final String name;
  final String nik;
  final String type;
  final String date;
  final String status;

  PendingRequest({
    required this.id,
    required this.name,
    required this.nik,
    required this.type,
    required this.date,
    required this.status,
  });

  factory PendingRequest.fromJson(Map<String, dynamic> json) {
    return PendingRequest(
      id: json['id'],
      name: json['nama'] ?? '-',
      nik: json['nik'] ?? '-',
      type: _getSuratType(json['jenis_surat']),
      date: json['created_at'] != null ? json['created_at'].toString().split('T')[0] : '-',
      status: json['status'],
    );
  }

  static String _getSuratType(String? jenis) {
    switch (jenis) {
      case 'usaha':
        return 'Surat Keterangan Usaha';
      case 'kematian':
        return 'Surat Keterangan Kematian';
      case 'tidak_mampu':
        return 'Surat Keterangan Tidak Mampu';
      default:
        return jenis ?? '-';
    }
  }
}

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  int _currentIndex = 0;
  List<PendingRequest> pendingRequests = [];

  // Mock data untuk registered NIK
  final List<Map<String, dynamic>> registeredNIK = [
    {
      'nik': '3517081234567890',
      'name': 'Ahmad Fauzi',
      'address': 'Jl. Merdeka No. 123',
      'phone': '081234567890',
      'status': 'active',
      'registeredDate': '2025-01-15',
    },
    {
      'nik': '3517081234567891',
      'name': 'Siti Aminah',
      'address': 'Jl. Pancasila No. 456',
      'phone': '081234567891',
      'status': 'active',
      'registeredDate': '2025-02-20',
    },
    {
      'nik': '3517081234567892',
      'name': 'Budi Santoso',
      'address': 'Jl. Gatot Subroto No. 789',
      'phone': '081234567892',
      'status': 'inactive',
      'registeredDate': '2025-03-10',
    },
  ];

  @override
  void initState() {
    super.initState();
    _fetchPendingRequests();
  }

  Future<void> _fetchPendingRequests() async {
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
        final all = data.map((e) => PendingRequest.fromJson(e)).toList();
        setState(() {
          pendingRequests = all.where((e) => e.status == 'pending').toList();
        });
      }
    } catch (e) {
      // Optionally show error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Admin Header
            SliverAppBar(
              expandedHeight: 180,
              floating: false,
              pinned: true,
              backgroundColor: const Color(0xFF1565C0),
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF1565C0),
                        Color(0xFF1976D2),
                      ],
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 10,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.admin_panel_settings,
                          size: 32,
                          color: Color(0xFF1565C0),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'SEDESA ADMIN',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const Text(
                        'Panel Administrasi Desa',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                IconButton(
                  onPressed: () {
                    _showNotificationPanel(context);
                  },
                  icon: Stack(
                    children: [
                      const Icon(Icons.notifications_outlined, color: Colors.white),
                      if (pendingRequests.isNotEmpty)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              '${pendingRequests.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    _showAdminProfile(context);
                  },
                  icon: const Icon(Icons.account_circle_outlined, color: Colors.white),
                ),
              ],
            ),

            // Dashboard Stats
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Dashboard Overview',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1565C0),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildAdminStatCard(
                            icon: Icons.pending_actions,
                            title: 'Pending',
                            value: '${pendingRequests.length}',
                            color: const Color(0xFFFF5722),
                            onTap: () => _showPendingRequests(context),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildAdminStatCard(
                            icon: Icons.people,
                            title: 'Terdaftar',
                            value: '${registeredNIK.length}',
                            color: const Color(0xFF4CAF50),
                            onTap: () => _showNIKManagement(context),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildAdminStatCard(
                            icon: Icons.description,
                            title: 'Total Surat',
                            value: '156',
                            color: const Color(0xFF2196F3),
                            onTap: () => _showSuratDetails(context),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Quick Actions
                    const Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1565C0),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildQuickActionCard(
                            icon: Icons.person_add,
                            title: 'Tambah NIK',
                            subtitle: 'Daftarkan warga baru',
                            color: const Color(0xFF4CAF50),
                            onTap: () {
                            if (!context.mounted) return;
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (_) => NIKDataPage()),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildQuickActionCard(
                            icon: Icons.location_on_rounded,
                            title: 'Maps',
                            subtitle: 'Lihat Lokasi Rumah Warga',
                            color: const Color(0xFF9C27B0),
                            onTap: () => _showReports(context),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Recent Activity
                    const Text(
                      'Recent Activity',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1565C0),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // Recent Pending Requests
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final request = pendingRequests[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: _buildPendingRequestCard(request),
                  );
                },
                childCount: pendingRequests.length > 3 ? 3 : pendingRequests.length,
              ),
            ),

            // View All Button
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: OutlinedButton(
                  onPressed: () => _showPendingRequests(context),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF1565C0)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'Lihat Semua Permintaan',
                    style: TextStyle(
                      color: Color(0xFF1565C0),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
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
          currentIndex: _currentIndex,
          onTap: (index) {
            if (index == _currentIndex) return;
            setState(() => _currentIndex = index);
            if (index == 0) {
              // Dashboard: stay on this page
            } else if (index == 1) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const RiwayatPage()),
              );
            } else if (index == 2) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const NIKDataPage()),
              );
            } else if (index == 3) {
              // Placeholder for Maps
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

  Widget _buildAdminStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha:0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha:0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha:0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha:0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingRequestCard(PendingRequest request) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha:0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: Colors.blue.withValues(alpha: 0.1),
          child: Text(
            request.name.isNotEmpty ? request.name[0] : '-',
            style: const TextStyle(
              color: Colors.blue,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          request.name,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(request.type),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 12, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  request.date,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(width: 12),
                Icon(Icons.badge, size: 12, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  request.nik,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () => _approveRequest(request),
              icon: const Icon(Icons.check_circle, color: Colors.green),
              tooltip: 'Approve',
            ),
            IconButton(
              onPressed: () => _rejectRequest(request),
              icon: const Icon(Icons.cancel, color: Colors.red),
              tooltip: 'Reject',
            ),
          ],
        ),
      ),
    );
  }

  void _showPendingRequests(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Membuka halaman Permintaan Pending'),
        backgroundColor: Color(0xFF1565C0),
      ),
    );
  }

  void _showNIKManagement(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Membuka halaman Manajemen NIK'),
        backgroundColor: Color(0xFF1565C0),
      ),
    );
  }

  void _showSuratDetails(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Membuka halaman Detail Surat'),
        backgroundColor: Color(0xFF1565C0),
      ),
    );
  }

  void _showReports(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Membuka halaman Laporan'),
        backgroundColor: Color(0xFF1565C0),
      ),
    );
  }

  void _showNotificationPanel(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Panel Notifikasi'),
        backgroundColor: Color(0xFF1565C0),
      ),
    );
  }

  void _showAdminProfile(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profil Admin'),
        backgroundColor: Color(0xFF1565C0),
      ),
    );
  }

  void _approveRequest(PendingRequest request) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Permintaan ${request.name} disetujui'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _rejectRequest(PendingRequest request) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Permintaan ${request.name} ditolak'),
        backgroundColor: Colors.red,
      ),
    );
  }
}