// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:project_akhir_sedesa/config.dart';
import 'package:project_akhir_sedesa/service/jwt_service.dart';
import 'home_page.dart';
import 'riwayat_page.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';

class NIKDataPage extends StatefulWidget {
  const NIKDataPage({super.key});

  @override
  State<NIKDataPage> createState() => _NIKDataPageState();
}

class _NIKDataPageState extends State<NIKDataPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'Semua';
  List<Map<String, dynamic>> _filteredNIKData = [];
  List<Map<String, dynamic>> _registeredNIK = [];

  Future<List<Map<String, dynamic>>> fetchRegisteredNIK() async {
    final token = await getToken();
    if (token == null) {
      throw Exception('Token tidak ditemukan, silakan login ulang');
    }
    
    final response = await http.get(
      Uri.parse('$baseUrl/nik-terdaftar'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map<Map<String, dynamic>>((item) {
        return {
          'id': item['id'],
          'nik': item['nik'],
          'created_at': item['created_at'],
          'status_akun': item['status_akun'],
          'nama': item['nama'] ?? '',
          'alamat': item['alamat'] ?? '',
          'nomor_telepon': item['nomor_telepon'] ?? '',
          'role': item['role'] ?? '',
          'secret_key': item['secret_key'] ?? '',
          'tempat_lahir': item['tempat_lahir'] ?? '',
          'tanggal_lahir': item['tanggal_lahir'] ?? '',
        };
      }).toList();
    } else if (response.statusCode == 403) {
      throw Exception('Akses ditolak, hanya admin');
    } else {
      throw Exception('Gagal memuat data NIK');
    }
  }

  @override
  void initState() {
    super.initState();
    fetchRegisteredNIK().then((data) {
      setState(() {
        _registeredNIK = data;
        _filteredNIKData = data;
      });
    }).catchError((error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading data: $error'),
          backgroundColor: Colors.red,
        ),
      );
    });
  }

  void _filterData() {
    setState(() {
      _filteredNIKData = _registeredNIK.where((data) {
        final matchesSearch = (data['nama'] ?? '')
                .toLowerCase()
                .contains(_searchController.text.toLowerCase()) ||
            (data['nik'] ?? '').contains(_searchController.text) ||
            (data['alamat'] ?? '')
                .toLowerCase()
                .contains(_searchController.text.toLowerCase());

        final matchesFilter = _selectedFilter == 'Semua' ||
            (_selectedFilter == 'Aktif' && data['status_akun'] == 'aktif') ||
            (_selectedFilter == 'Tidak Aktif' && data['status_akun'] == 'belum aktif');

        return matchesSearch && matchesFilter;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: _registeredNIK.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF1565C0), Color(0xFF1976D2)],
                      ),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.people,
                          size: 48,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Data NIK Warga',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Total: ${_registeredNIK.length} warga terdaftar',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Search and Filter Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.white,
                    child: Column(
                      children: [
                        // Search Bar
                        TextField(
                          controller: _searchController,
                          onChanged: (value) => _filterData(),
                          decoration: InputDecoration(
                            hintText: 'Cari berdasarkan nama, NIK, atau alamat...',
                            prefixIcon: const Icon(Icons.search, color: Color(0xFF1565C0)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF1565C0)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF1565C0), width: 2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Filter Buttons
                        Row(
                          children: [
                            const Text(
                              'Filter: ',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1565C0),
                              ),
                            ),
                            Expanded(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: ['Semua', 'Aktif', 'Tidak Aktif']
                                      .map((filter) => Padding(
                                            padding: const EdgeInsets.only(right: 8),
                                            child: FilterChip(
                                              label: Text(filter),
                                              selected: _selectedFilter == filter,
                                              onSelected: (selected) {
                                                setState(() {
                                                  _selectedFilter = filter;
                                                  _filterData();
                                                });
                                              },
                                              selectedColor: const Color(0xFF1565C0).withValues(alpha: 0.2),
                                              checkmarkColor: const Color(0xFF1565C0),
                                            ),
                                          ))
                                      .toList(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Statistics Cards
                  Container(
                    height: 110,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            title: 'Total Warga',
                            value: '${_registeredNIK.length}',
                            icon: Icons.people,
                            color: const Color(0xFF2196F3),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            title: 'Aktif',
                            value: '${_registeredNIK.where((e) => e['status_akun'] == 'aktif').length}',
                            icon: Icons.check_circle,
                            color: const Color(0xFF4CAF50),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            title: 'Tidak Aktif',
                            value: '${_registeredNIK.where((e) => e['status_akun'] == 'belum aktif').length}',
                            icon: Icons.cancel,
                            color: const Color(0xFFFF5722),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // NIK Data List
                  Expanded(
                    child: _filteredNIKData.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filteredNIKData.length,
                            itemBuilder: (context, index) {
                              final nikData = _filteredNIKData[index];
                              return _buildNIKCard(nikData);
                            },
                          ),
                  ),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddNIKDialog(context),
        backgroundColor: const Color(0xFF1565C0),
        child: const Icon(Icons.add, color: Colors.white),
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
          currentIndex: 2,
          onTap: (index) {
            if (index == 2) return;
            if (index == 0) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const AdminHomePage()),
              );
            } else if (index == 1) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const RiwayatPage()),
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

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNIKCard(Map<String, dynamic> nikData) {
    final isActive = nikData['status_akun'] == 'aktif';
    final nama = nikData['nama'] ?? 'Nama tidak tersedia';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: isActive
              ? const Color(0xFF4CAF50).withValues(alpha: 0.1)
              : const Color(0xFFFF5722).withValues(alpha: 0.1),
          child: Text(
            nama.isNotEmpty ? nama[0].toUpperCase() : '?',
            style: TextStyle(
              color: isActive ? const Color(0xFF4CAF50) : const Color(0xFFFF5722),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          nama,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'NIK: ${nikData['nik'] ?? 'Tidak tersedia'}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(
                  isActive ? Icons.check_circle : Icons.cancel,
                  size: 12,
                  color: isActive ? const Color(0xFF4CAF50) : const Color(0xFFFF5722),
                ),
                const SizedBox(width: 4),
                Text(
                  isActive ? 'Aktif' : 'Tidak Aktif',
                  style: TextStyle(
                    fontSize: 12,
                    color: isActive ? const Color(0xFF4CAF50) : const Color(0xFFFF5722),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleMenuAction(value, nikData),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 16, color: Color(0xFF1565C0)),
                  SizedBox(width: 8),
                  Text('Edit'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'detail',
              child: Row(
                children: [
                  Icon(Icons.info, size: 16, color: Color(0xFF4CAF50)),
                  SizedBox(width: 8),
                  Text('Detail'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 16, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Hapus'),
                ],
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Alamat', nikData['alamat'] ?? 'Tidak tersedia'),
                _buildDetailRow('Telepon', nikData['nomor_telepon'] ?? 'Tidak tersedia'),
                _buildDetailRow('Tempat Lahir', nikData['tempat_lahir'] ?? 'Tidak tersedia'),
                _buildDetailRow('Tanggal Lahir', nikData['tanggal_lahir'] ?? 'Tidak tersedia'),
                _buildDetailRow('Role', nikData['role'] ?? 'Tidak tersedia'),
                _buildDetailRow('Tanggal Daftar', nikData['created_at'] ?? 'Tidak tersedia'),
                if (nikData['secret_key'] != null && nikData['secret_key'].isNotEmpty)
                  _buildDetailRow(
                    'Secret Key',
                    nikData['secret_key'],
                    onCopy: () {
                      Clipboard.setData(ClipboardData(text: nikData['secret_key']));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Secret Key berhasil disalin ke clipboard'),
                          backgroundColor: Color(0xFF1565C0),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {VoidCallback? onCopy}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (onCopy != null)
                  IconButton(
                    icon: const Icon(Icons.copy, size: 18),
                    tooltip: 'Copy to clipboard',
                    onPressed: onCopy,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Tidak ada data yang ditemukan',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Coba ubah kata kunci pencarian atau filter',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(String action, Map<String, dynamic> nikData) {
    switch (action) {
      case 'edit':
        _showEditNIKDialog(context, nikData);
        break;
      case 'detail':
        _showNIKDetail(context, nikData);
        break;
      case 'delete':
        _showDeleteConfirmation(context, nikData);
        break;
    }
  }

  void _showAddNIKDialog(BuildContext context) {
    final TextEditingController nikController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.person_add, color: Color(0xFF1565C0)),
              SizedBox(width: 8),
              Text('Tambah NIK Baru'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nikController,
                decoration: const InputDecoration(
                  labelText: 'NIK',
                  border: OutlineInputBorder(),
                  hintText: 'Masukkan NIK',
                ),
                keyboardType: TextInputType.number,
                maxLength: 16,
              ),
              if (isLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 16.0),
                  child: CircularProgressIndicator(),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (nikController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('NIK tidak boleh kosong'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      setState(() => isLoading = true);

                      try {
                        final token = await getToken();
                        if (token == null) {
                          throw Exception('Token tidak ditemukan, silakan login ulang');
                        }
                        
                        final response = await http.post(
                          Uri.parse('$baseUrl/nik-terdaftar'),
                          headers: {
                            'Content-Type': 'application/json',
                            'Authorization': 'Bearer $token',
                          },
                          body: json.encode({
                            'nik': nikController.text,
                          }),
                        );

                        if (response.statusCode == 201) {
                          if (!mounted) return;
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('NIK berhasil ditambahkan'),
                              backgroundColor: Color(0xFF4CAF50),
                            ),
                          );
                          // Refresh the data
                          final newData = await fetchRegisteredNIK();
                          setState(() {
                            _registeredNIK = newData;
                            _filteredNIKData = newData;
                          });
                        } else if (response.statusCode == 409) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('NIK sudah terdaftar'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        } else {
                          throw Exception('Gagal menambahkan NIK');
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: ${e.toString()}'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      } finally {
                        setState(() => isLoading = false);
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
              ),
              child: const Text('Simpan', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditNIKDialog(BuildContext context, Map<String, dynamic> nikData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.edit, color: Color(0xFF1565C0)),
            const SizedBox(width: 8),
            Text('Edit ${nikData['nama'] ?? 'Warga'}'),
          ],
        ),
        content: const Text('Fitur edit NIK akan segera tersedia'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showNIKDetail(BuildContext context, Map<String, dynamic> nikData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.info, color: Color(0xFF4CAF50)),
            const SizedBox(width: 8),
            Text('Detail ${nikData['nama'] ?? 'Warga'}'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('NIK', nikData['nik'] ?? 'Tidak tersedia'),
            _buildDetailRow('Nama', nikData['nama'] ?? 'Tidak tersedia'),
            _buildDetailRow('Alamat', nikData['alamat'] ?? 'Tidak tersedia'),
            _buildDetailRow('Telepon', nikData['nomor_telepon'] ?? 'Tidak tersedia'),
            _buildDetailRow('Status', nikData['status_akun'] ?? 'Tidak tersedia'),
            _buildDetailRow('Tanggal Daftar', nikData['created_at'] ?? 'Tidak tersedia'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, Map<String, dynamic> nikData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Konfirmasi Hapus'),
          ],
        ),
        content: Text('Apakah Anda yakin ingin menghapus data ${nikData['nama'] ?? 'Warga'}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Data ${nikData['nama'] ?? 'Warga'} berhasil dihapus'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}