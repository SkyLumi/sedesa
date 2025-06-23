import 'package:flutter/material.dart';
import 'package:project_akhir_sedesa/views/user/riwayat_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:project_akhir_sedesa/config.dart';
import 'package:project_akhir_sedesa/service/jwt_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';

class SuratDetailPage extends StatefulWidget {
  final SuratRiwayat surat;

  const SuratDetailPage({
    super.key,
    required this.surat,
  });

  @override
  State<SuratDetailPage> createState() => _SuratDetailPageState();
}

class _SuratDetailPageState extends State<SuratDetailPage> {
  Map<String, dynamic>? _apiResponse;
  bool _isLoadingDetail = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchSuratDetail();
  }

  Future<void> _fetchSuratDetail() async {
    try {
      final token = await getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/api/surat/${widget.surat.id}/details/user'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _apiResponse = data;
          _isLoadingDetail = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Gagal memuat detail surat';
          _isLoadingDetail = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Terjadi kesalahan: $e';
        _isLoadingDetail = false;
      });
    }
  }

  Map<String, dynamic>? get _suratDetail => _apiResponse?['detail'];
  String? get _alasan => _apiResponse?['alasan'];
  String? get _filePdf => _apiResponse?['file_pdf'];

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

  Color getStatusColor(String status) {
    switch (status) {
      case 'selesai':
        return const Color(0xFF4CAF50);
      case 'pending':
        return const Color(0xFFFF9800);
      case 'ditolak':
        return const Color(0xFFF44336);
      default:
        return Colors.grey;
    }
  }

  String getStatusText(String status) {
    switch (status) {
      case 'selesai':
        return 'Selesai';
      case 'pending':
        return 'Menunggu';
      case 'ditolak':
        return 'Ditolak';
      default:
        return status[0].toUpperCase() + status.substring(1);
    }
  }

  Color _getJenisColor(String? jenis) {
    if (jenis == null) return const Color(0xFF2E7D32);
    final t = jenis.toLowerCase();
    if (t.contains('usaha')) return const Color(0xFF1976D2);
    if (t.contains('tidak_mampu')) return const Color(0xFFE65100);
    if (t.contains('kematian')) return const Color(0xFF424242);
    return const Color(0xFF2E7D32);
  }

  Widget _buildSuratSpecificDetails() {
    if (_isLoadingDetail) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null) {
      return Container(
        padding: const EdgeInsets.all(20.0),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error, color: Colors.red),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      );
    }

    if (_suratDetail == null) {
      return Container(
        padding: const EdgeInsets.all(20.0),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          children: [
            Icon(Icons.info, color: Colors.grey),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Tidak ada detail tambahan untuk surat ini',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      );
    }

    switch (widget.surat.jenisSurat) {
      case 'usaha':
        return _buildUsahaDetails();
      case 'tidak_mampu':
        return _buildTidakMampuDetails();
      case 'kematian':
        return _buildKematianDetails();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildUsahaDetails() {
    return Column(
      children: [
        _buildDetailCard(
          icon: Icons.business,
          title: 'Nama Usaha',
          value: _suratDetail!['nama_usaha'] ?? 'Tidak diisi',
        ),
        const SizedBox(height: 16),
        _buildDetailCard(
          icon: Icons.category,
          title: 'Bidang Usaha',
          value: _suratDetail!['bidang_usaha'] ?? 'Tidak diisi',
        ),
        if (_suratDetail!['alamat_usaha'] != null) ...[
          const SizedBox(height: 16),
          _buildDetailCard(
            icon: Icons.location_on,
            title: 'Alamat Usaha',
            value: _suratDetail!['alamat_usaha'],
          ),
        ],
        if (_suratDetail!['lat'] != null && _suratDetail!['lng'] != null) ...[
          const SizedBox(height: 16),
          _buildDetailCard(
            icon: Icons.map,
            title: 'Koordinat Lokasi',
            value: '${_suratDetail!['lat']}, ${_suratDetail!['lng']}',
          ),
        ],
      ],
    );
  }

  Widget _buildTidakMampuDetails() {
    return Column(
      children: [
        _buildDetailCard(
          icon: Icons.family_restroom,
          title: 'Status Perkawinan',
          value: _suratDetail!['status_perkawinan'] ?? 'Tidak diisi',
        ),
        const SizedBox(height: 16),
        _buildDetailCard(
          icon: Icons.attach_money,
          title: 'Penghasilan Bulanan',
          value: 'Rp ${_suratDetail!['penghasilan_bulanan']?.toString() ?? 'Tidak diisi'}',
        ),
        const SizedBox(height: 16),
        _buildDetailCard(
          icon: Icons.note,
          title: 'Alasan Tidak Mampu',
          value: _suratDetail!['alasan_tidak_mampu'] ?? 'Tidak diisi',
        ),
      ],
    );
  }

  Widget _buildKematianDetails() {
    return Column(
      children: [
        _buildDetailCard(
          icon: Icons.calendar_today,
          title: 'Hari Meninggal',
          value: _suratDetail!['hari_meninggal'] ?? 'Tidak diisi',
        ),
        const SizedBox(height: 16),
        _buildDetailCard(
          icon: Icons.event,
          title: 'Tanggal Meninggal',
          value: _suratDetail!['tanggal_meninggal'] ?? 'Tidak diisi',
        ),
        const SizedBox(height: 16),
        _buildDetailCard(
          icon: Icons.location_city,
          title: 'Tempat Meninggal',
          value: _suratDetail!['tempat_meninggal'] ?? 'Tidak diisi',
        ),
        const SizedBox(height: 16),
        _buildDetailCard(
          icon: Icons.medical_services,
          title: 'Sebab Kematian',
          value: _suratDetail!['sebab'] ?? 'Tidak diisi',
        ),
        const SizedBox(height: 16),
        _buildDetailCard(
          icon: Icons.person,
          title: 'Nama Pelapor',
          value: _suratDetail!['nama_pelapor'] ?? 'Tidak diisi',
        ),
        const SizedBox(height: 16),
        _buildDetailCard(
          icon: Icons.people,
          title: 'Hubungan dengan Pelapor',
          value: _suratDetail!['hubungan_pelapor'] ?? 'Tidak diisi',
        ),
      ],
    );
  }

  Widget _buildAlasanSection() {
    if (_alasan == null || _alasan!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        _buildDetailCard(
          icon: Icons.info_outline,
          title: 'Alasan',
          value: _alasan!,
          valueColor: widget.surat.status == 'ditolak' 
              ? const Color(0xFFF44336) 
              : null,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildPdfSection() {
    if (_filePdf == null || _filePdf!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.picture_as_pdf,
                      color: Color(0xFF2E7D32),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'File Surat',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Surat telah selesai diproses',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Implement PDF download/view functionality
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Fitur unduh PDF akan segera hadir'),
                        backgroundColor: Color(0xFF2E7D32),
                      ),
                    );
                  },
                  icon: const Icon(Icons.download),
                  label: const Text('Unduh Surat PDF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Future<void> _downloadAndOpenPdf(int suratId) async {
    try {
      final token = await getToken();
      final url = '$baseUrl/api/surat/$suratId/download-pdf';
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        final tempDir = await getTemporaryDirectory();
        final filePath = '${tempDir.path}/surat_$suratId.pdf';
        final file = await File(filePath).writeAsBytes(bytes);
        await OpenFile.open(file.path);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal mengunduh file PDF.')), 
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Detail Surat',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF2E7D32),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header with gradient
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    _getJenisColor(widget.surat.jenisSurat),
                    _getJenisColor(widget.surat.jenisSurat).withValues(alpha: 0.7),
                  ],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
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
                      child: Icon(
                        Icons.description,
                        size: 50,
                        color: _getJenisColor(widget.surat.jenisSurat),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      getSuratDisplayName(widget.surat.jenisSurat),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: _getJenisColor(widget.surat.jenisSurat).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _getJenisColor(widget.surat.jenisSurat),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        getStatusText(widget.surat.status),
                        style: TextStyle(
                          color: _getJenisColor(widget.surat.jenisSurat),
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Surat ID
                  _buildDetailCard(
                    icon: Icons.numbers,
                    title: 'Nomor Surat',
                    value: '#${widget.surat.id.toString().padLeft(6, '0')}',
                  ),
                  const SizedBox(height: 16),

                  // Jenis Surat
                  _buildDetailCard(
                    icon: Icons.category,
                    title: 'Jenis Surat',
                    value: getSuratDisplayName(widget.surat.jenisSurat),
                  ),
                  const SizedBox(height: 16),

                  // Status
                  _buildDetailCard(
                    icon: Icons.info,
                    title: 'Status',
                    value: getStatusText(widget.surat.status),
                    valueColor: getStatusColor(widget.surat.status),
                  ),
                  const SizedBox(height: 16),

                  // Tanggal Pengajuan
                  _buildDetailCard(
                    icon: Icons.calendar_today,
                    title: 'Tanggal Pengajuan',
                    value: _formatDate(widget.surat.createdAt),
                  ),
                  const SizedBox(height: 16),

                  // Alasan (if available)
                  _buildAlasanSection(),

                  // Surat Specific Details
                  _buildSuratSpecificDetails(),
                  const SizedBox(height: 16),

                  // PDF File (if available and completed)
                  if (widget.surat.status == 'selesai') _buildPdfSection(),

                  // Estimasi Selesai (if pending)
                  if (widget.surat.status == 'pending')
                    _buildDetailCard(
                      icon: Icons.schedule,
                      title: 'Menunggu Persetujuan Admin',
                      value: 'harap bersabar, surat akan segera diverifikasi',
                      valueColor: const Color(0xFFFF9800),
                    ),
                  if (widget.surat.status == 'pending') const SizedBox(height: 16),

                  // Catatan (if rejected)
                  if (widget.surat.status == 'ditolak')
                    _buildDetailCard(
                      icon: Icons.note,
                      title: 'Catatan',
                      value: _alasan ?? 'Tidak ada catatan',
                      valueColor: const Color(0xFFF44336),
                    ),
                  if (widget.surat.status == 'ditolak') const SizedBox(height: 16),

                  // Action Buttons
                  const SizedBox(height: 32),
                  if (widget.surat.status == 'pending')
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // TODO: Implement cancel surat functionality
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Fitur pembatalan surat akan segera hadir'),
                              backgroundColor: Color(0xFFFF9800),
                            ),
                          );
                        },
                        icon: const Icon(Icons.cancel),
                        label: const Text('Batalkan Pengajuan'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF44336),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  if (widget.surat.status == 'ditolak')
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // TODO: Implement resubmit functionality
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Fitur pengajuan ulang akan segera hadir'),
                              backgroundColor: Color(0xFF2E7D32),
                            ),
                          );
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Ajukan Ulang'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  if (_filePdf != null && _filePdf!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.picture_as_pdf),
                        label: const Text('Lihat/Download PDF'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => _downloadAndOpenPdf(widget.surat.id),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard({
    required IconData icon,
    required String title,
    required String value,
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _getJenisColor(widget.surat.jenisSurat).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: _getJenisColor(widget.surat.jenisSurat),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
} 