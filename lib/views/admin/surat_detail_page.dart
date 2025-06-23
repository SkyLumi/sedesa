import 'package:flutter/material.dart';
import 'riwayat_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:project_akhir_sedesa/config.dart';
import 'package:project_akhir_sedesa/service/jwt_service.dart';
import '../../service/map_service.dart';

class SuratDetailPage extends StatefulWidget {
  final AdminSuratRiwayat surat;
  const SuratDetailPage({super.key, required this.surat});

  @override
  State<SuratDetailPage> createState() => _SuratDetailPageState();
}

class _SuratDetailPageState extends State<SuratDetailPage> {
  Map<String, dynamic>? _apiResponse;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchSuratDetail();
  }

  Future<void> _fetchSuratDetail() async {
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final token = await getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/api/surat/${widget.surat.id}/details/admin'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        setState(() {
          _apiResponse = json.decode(response.body);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Gagal memuat detail surat';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Terjadi kesalahan: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _handleAction(String action) async {
    final isApprove = action == 'approve';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isApprove ? 'Setujui Surat?' : 'Tolak Surat?'),
        content: Text(isApprove
            ? 'Apakah Anda yakin ingin menyetujui surat ini?'
            : 'Apakah Anda yakin ingin menolak surat ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isApprove ? Colors.green : Colors.red,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(isApprove ? 'Setujui' : 'Tolak'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      final token = await getToken();
      final url = '$baseUrl/api/surat/${widget.surat.id}/status';
      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'status': isApprove ? 'disetujui' : 'ditolak',
        }),
      );
      if (response.statusCode == 200) {
        if (isApprove) {
          // Call generate PDF API
          final pdfUrl = '$baseUrl/api/surat/${widget.surat.id}/generate-pdf';
          final pdfResponse = await http.post(
            Uri.parse(pdfUrl),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          );
          String pdfMsg = 'Surat disetujui.';
          if (pdfResponse.statusCode == 200 || pdfResponse.statusCode == 201) {
            final pdfData = json.decode(pdfResponse.body);
            pdfMsg = pdfData['message'] ?? 'PDF berhasil di-generate';
          } else {
            pdfMsg = 'Surat disetujui, tapi gagal generate PDF.';
          }
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(pdfMsg),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Surat ditolak.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        Navigator.of(context).pop(true);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memproses surat.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Color getStatusColor(String? status) {
    switch (status) {
      case 'selesai':
      case 'disetujui':
        return const Color(0xFF4CAF50);
      case 'pending':
        return const Color(0xFFFF9800);
      case 'ditolak':
        return const Color(0xFFF44336);
      default:
        return Colors.grey;
    }
  }

  IconData getJenisIcon(String? jenis) {
    switch (jenis) {
      case 'usaha':
        return Icons.business_center;
      case 'kematian':
        return Icons.sentiment_very_dissatisfied;
      case 'tidak_mampu':
        return Icons.money_off;
      default:
        return Icons.description;
    }
  }

  bool _isImageFile(String? filename) {
    if (filename == null) return false;
    final lower = filename.toLowerCase();
    return lower.endsWith('.jpg') || lower.endsWith('.jpeg') || lower.endsWith('.png') || lower.endsWith('.gif');
  }

  void _showImagePreview(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: InteractiveViewer(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(24),
                  child: const Text('Gagal memuat gambar'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text('Detail Surat'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: const Color(0xFF1565C0),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)))
              : _apiResponse == null
                  ? const Center(child: Text('Tidak ada data'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Info Surat Card
                          Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: getStatusColor(_apiResponse!['status']).withValues(alpha: 0.1),
                                        child: Icon(
                                          getJenisIcon(_apiResponse!['jenis_surat']),
                                          color: getStatusColor(_apiResponse!['status']),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _apiResponse!['jenis_surat']?.toString().toUpperCase() ?? '-',
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Icon(Icons.info, size: 16, color: getStatusColor(_apiResponse!['status'])),
                                                const SizedBox(width: 4),
                                                Text(
                                                  _apiResponse!['status']?.toString().toUpperCase() ?? '-',
                                                  style: TextStyle(
                                                    color: getStatusColor(_apiResponse!['status']),
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  _buildDetailRow('ID', _apiResponse!['id'].toString()),
                                  _buildDetailRow('Alasan', _apiResponse!['alasan'] ?? '-'),
                                  _buildDetailRow('File PDF', _apiResponse!['file_pdf'] ?? '-'),
                                  _buildDetailRow('Tanggal Dibuat', _apiResponse!['created_at'] ?? '-'),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          // Info Pemohon Card
                          Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: const [
                                      Icon(Icons.person, color: Color(0xFF1565C0)),
                                      SizedBox(width: 8),
                                      Text('Info Pemohon', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  if (_apiResponse!['user'] != null)
                                    ...[
                                      _buildDetailRow('Nama', _apiResponse!['user']['nama'] ?? '-'),
                                      _buildDetailRow('NIK', _apiResponse!['user']['NIK'] ?? '-'),
                                      _buildDetailRow('Nomor Telepon', _apiResponse!['user']['nomor_telepon'] ?? '-'),
                                      _buildDetailRow('Alamat', _apiResponse!['user']['alamat'] ?? '-'),
                                    ],
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          // File Pendukung Card
                          Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: const [
                                      Icon(Icons.attach_file, color: Color(0xFF1565C0)),
                                      SizedBox(width: 8),
                                      Text('File Pendukung', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  if (_apiResponse!['file_pendukung'] != null && (_apiResponse!['file_pendukung'] as List).isNotEmpty)
                                    ...(_apiResponse!['file_pendukung'] as List).map<Widget>((f) => ListTile(
                                          contentPadding: EdgeInsets.zero,
                                          leading: const Icon(Icons.insert_drive_file, color: Colors.grey),
                                          title: Text(f['filename'] ?? '-'),
                                          subtitle: Text('Diunggah: ${f['uploaded_at'] ?? '-'}'),
                                          trailing: IconButton(
                                            icon: const Icon(Icons.open_in_new, color: Color(0xFF1565C0)),
                                            onPressed: () {
                                              final url = f['url'];
                                              final filename = f['filename'];
                                              if (url != null && _isImageFile(filename)) {
                                                _showImagePreview(context, url);
                                              } else if (url != null) {
                                                // You can use url_launcher to open
                                                // launchUrl(Uri.parse(url));
                                              }
                                            },
                                          ),
                                        )),
                                  if (_apiResponse!['file_pendukung'] == null || (_apiResponse!['file_pendukung'] as List).isEmpty)
                                    const Padding(
                                      padding: EdgeInsets.symmetric(vertical: 8.0),
                                      child: Text('Tidak ada file pendukung.', style: TextStyle(color: Colors.grey)),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          // Detail Surat Card
                          Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: const [
                                      Icon(Icons.info_outline, color: Color(0xFF1565C0)),
                                      SizedBox(width: 8),
                                      Text('Detail Surat', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  if (_apiResponse!['detail'] != null)
                                    ...(_apiResponse!['detail'] as Map<String, dynamic>).entries.map((e) => _buildDetailRow(e.key, e.value?.toString() ?? '-')),
                                  if (_apiResponse!['detail'] == null)
                                    const Padding(
                                      padding: EdgeInsets.symmetric(vertical: 8.0),
                                      child: Text('Tidak ada detail khusus.', style: TextStyle(color: Colors.grey)),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          // Lokasi Usaha Card (separate)
                          if (_apiResponse!['jenis_surat'] == 'usaha' &&
                              _apiResponse!['detail'] != null &&
                              _apiResponse!['detail']['lat'] != null &&
                              _apiResponse!['detail']['lng'] != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 18.0),
                              child: Card(
                                color: const Color(0xFFF4F6FA),
                                elevation: 1,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        height: 280,
                                        child: LocationPicker(
                                          lat: (_apiResponse!['detail']['lat'] as num).toDouble(),
                                          lng: (_apiResponse!['detail']['lng'] as num).toDouble(),
                                          onLocationPicked: (lat, lng) {}, // read-only
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
      bottomNavigationBar: (_apiResponse != null && (_apiResponse!['status'] == 'pending' || _apiResponse!['status'] == 'disetujui' || _apiResponse!['status'] == 'ditolak'))
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => _handleAction('approve'),
                        child: const Text('Disetujui', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => _handleAction('reject'),
                        child: const Text('Ditolak', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(value ?? '-', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
