import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:project_akhir_sedesa/config.dart';
import 'package:project_akhir_sedesa/service/jwt_service.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:project_akhir_sedesa/service/map_service.dart';

class FormPage extends StatefulWidget {
  final String? jenis;
  const FormPage({super.key, this.jenis});

  @override
  State<FormPage> createState() => _FormPageState();
}

class _FormPageState extends State<FormPage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _file;
  final ImagePicker _picker = ImagePicker();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  // Usaha
  String? _namaUsaha;
  String? _bidangUsaha;
  String? _alamatUsaha;
  double? _lat;
  double? _lng;
  // Tidak Mampu
  String? _statusPerkawinan;
  String? _penghasilanBulanan;
  String? _alasanTidakMampu;
  // Kematian
  String? _hariMeninggal;
  String? _tanggalMeninggal;
  String? _tempatMeninggal;
  String? _sebab;
  String? _namaPelapor;
  String? _hubunganPelapor;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> fetchUserSurat() async {
    final token = await getToken();
    if (token == null) {
      throw Exception('Token tidak ditemukan, silakan login ulang');
    }
    final response = await http.get(
      Uri.parse('$baseUrl/api/surat/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      List<Map<String, dynamic>> suratList = data.map<Map<String, dynamic>>((item) => Map<String, dynamic>.from(item)).toList();
      if (widget.jenis != null) {
        suratList = suratList.where((s) => (s['nama'] ?? '').toString().toLowerCase().contains(widget.jenis!.toLowerCase())).toList();
      }
      return suratList;
    } else if (response.statusCode == 401) {
      throw Exception('Akses ditolak, silakan login ulang');
    } else {
      throw Exception('Gagal memuat data surat');
    }
  }

  Future<void> submitSurat() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    setState(() => _isLoading = true);
    final token = await getToken();
    if (token == null) {
      setState(() => _isLoading = false);
      _showSnackBar('Token tidak ditemukan, silakan login ulang', Colors.red);
      return;
    }
    String jenis = _getJenisKey(widget.jenis);
    try {
      final uri = Uri.parse('$baseUrl/api/surat/$jenis');
      final request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';
      // Add form fields
      if (jenis == 'usaha') {
        request.fields['nama_usaha'] = _namaUsaha ?? '';
        request.fields['bidang_usaha'] = _bidangUsaha ?? '';
        request.fields['alamat_usaha'] = _alamatUsaha ?? '';
        request.fields['lat'] = _lat?.toString() ?? '';
        request.fields['lng'] = _lng?.toString() ?? '';
      } else if (jenis == 'tidak_mampu') {
        request.fields['status_perkawinan'] = _statusPerkawinan ?? '';
        request.fields['penghasilan_bulanan'] = _penghasilanBulanan ?? '';
        request.fields['alasan_tidak_mampu'] = _alasanTidakMampu ?? '';
      } else if (jenis == 'kematian') {
        request.fields['hari_meninggal'] = _hariMeninggal ?? '';
        request.fields['tanggal_meninggal'] = _tanggalMeninggal ?? '';
        request.fields['tempat_meninggal'] = _tempatMeninggal ?? '';
        request.fields['sebab'] = _sebab ?? '';
        request.fields['nama_pelapor'] = _namaPelapor ?? '';
        request.fields['hubungan_pelapor'] = _hubunganPelapor ?? '';
      }
      // Add file if present
      if (_file != null) {
        request.files.add(await http.MultipartFile.fromPath('file_pendukung', _file!));
      }
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 201) {
        _showSnackBar('Surat berhasil diajukan', Colors.green);
        setState(() {
          _formKey.currentState!.reset();
          _file = null;
        });
      } else {
        String msg = 'Gagal mengajukan surat';
        try {
          msg = json.decode(response.body)['message'] ?? msg;
        } catch (_) {}
        _showSnackBar(msg, Colors.red);
      }
    } catch (e) {
      _showSnackBar('Error: $e', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              color == Colors.green ? Icons.check_circle : Icons.error,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  String _getJenisKey(String? title) {
    if (title == null) return '';
    final t = title.toLowerCase();
    if (t.contains('usaha')) return 'usaha';
    if (t.contains('tidak mampu')) return 'tidak_mampu';
    if (t.contains('kematian')) return 'kematian';
    return '';
  }

  String _getJenisIcon(String? title) {
    if (title == null) return '📄';
    final t = title.toLowerCase();
    if (t.contains('usaha')) return '🏢';
    if (t.contains('tidak mampu')) return '🤝';
    if (t.contains('kematian')) return '⚰️';
    return '📄';
  }

  Color _getJenisColor(String? title) {
    if (title == null) return const Color(0xFF2E7D32);
    final t = title.toLowerCase();
    if (t.contains('usaha')) return const Color(0xFF1976D2);
    if (t.contains('tidak mampu')) return const Color(0xFFE65100);
    if (t.contains('kematian')) return const Color(0xFF424242);
    return const Color(0xFF2E7D32);
  }

  Widget _buildCustomTextField({
    required String label,
    required String? Function(String?)? validator,
    required void Function(String?)? onSaved,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? hintText,
    IconData? prefixIcon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: _getJenisColor(widget.jenis)) : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: _getJenisColor(widget.jenis), width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
        onSaved: onSaved,
      ),
    );
  }

  Widget _buildImagePicker() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Lampiran Foto',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () async {
              final XFile? pickedFile = await _picker.pickImage(
                source: ImageSource.camera,
                preferredCameraDevice: CameraDevice.rear,
                imageQuality: 80,
              );
              if (pickedFile != null) {
                setState(() {
                  _file = pickedFile.path;
                });
              }
            },
            child: Container(
              width: double.infinity,
              height: _file != null ? 200 : 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _file != null ? _getJenisColor(widget.jenis) : Colors.grey.shade300,
                  width: _file != null ? 2 : 1,
                ),
                color: Colors.grey.shade50,
              ),
              child: _file != null
                  ? Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(
                            File(_file!),
                            width: double.infinity,
                            height: 200,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.close, color: Colors.white, size: 20),
                              onPressed: () {
                                setState(() {
                                  _file = null;
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.camera_alt,
                          size: 40,
                          color: _getJenisColor(widget.jenis),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap untuk mengambil foto',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildFormFields() {
    final jenis = _getJenisKey(widget.jenis);
    List<Widget> fields = [];
    
    if (jenis == 'usaha') {
      fields.addAll([
        _buildCustomTextField(
          label: 'Nama Usaha',
          hintText: 'Masukkan nama usaha Anda',
          prefixIcon: Icons.business,
          validator: (v) => v == null || v.isEmpty ? 'Nama usaha wajib diisi' : null,
          onSaved: (v) => _namaUsaha = v,
        ),
        _buildCustomTextField(
          label: 'Bidang Usaha',
          hintText: 'Contoh: Kuliner, Retail, Jasa, dll',
          prefixIcon: Icons.category,
          validator: (v) => v == null || v.isEmpty ? 'Bidang usaha wajib diisi' : null,
          onSaved: (v) => _bidangUsaha = v,
        ),
        _buildCustomTextField(
          label: 'Alamat Usaha',
          hintText: 'Masukkan alamat usaha',
          prefixIcon: Icons.location_city,
          validator: (v) => v == null || v.isEmpty ? 'Alamat usaha wajib diisi' : null,
          onSaved: (v) => _alamatUsaha = v,
        ),
        LocationPicker(
          lat: _lat,
          lng: _lng,
          onLocationPicked: (lat, lng) {
            setState(() {
              _lat = lat;
              _lng = lng;
            });
          },
        ),
      ]);
    } else if (jenis == 'tidak_mampu') {
      fields.addAll([
        _buildCustomTextField(
          label: 'Status Perkawinan',
          hintText: 'Belum Menikah/Menikah/Cerai',
          prefixIcon: Icons.family_restroom,
          validator: (v) => v == null || v.isEmpty ? 'Status perkawinan wajib diisi' : null,
          onSaved: (v) => _statusPerkawinan = v,
        ),
        _buildCustomTextField(
          label: 'Penghasilan Bulanan',
          hintText: 'Contoh: Rp 1.000.000',
          prefixIcon: Icons.monetization_on,
          keyboardType: TextInputType.text,
          validator: (v) => v == null || v.isEmpty ? 'Penghasilan bulanan wajib diisi' : null,
          onSaved: (v) => _penghasilanBulanan = v,
        ),
        _buildCustomTextField(
          label: 'Alasan Tidak Mampu',
          hintText: 'Jelaskan alasan mengapa tidak mampu',
          prefixIcon: Icons.description,
          maxLines: 3,
          validator: (v) => v == null || v.isEmpty ? 'Alasan wajib diisi' : null,
          onSaved: (v) => _alasanTidakMampu = v,
        ),
      ]);
    } else if (jenis == 'kematian') {
      fields.addAll([
        _buildCustomTextField(
          label: 'Hari Meninggal',
          hintText: 'Contoh: Senin',
          prefixIcon: Icons.calendar_today,
          validator: (v) => v == null || v.isEmpty ? 'Hari meninggal wajib diisi' : null,
          onSaved: (v) => _hariMeninggal = v,
        ),
        _buildCustomTextField(
          label: 'Tanggal Meninggal',
          hintText: 'Contoh: 01 Januari 2024',
          prefixIcon: Icons.date_range,
          validator: (v) => v == null || v.isEmpty ? 'Tanggal meninggal wajib diisi' : null,
          onSaved: (v) => _tanggalMeninggal = v,
        ),
        _buildCustomTextField(
          label: 'Tempat Meninggal',
          hintText: 'Contoh: Rumah Sakit, Rumah, dll',
          prefixIcon: Icons.location_on,
          validator: (v) => v == null || v.isEmpty ? 'Tempat meninggal wajib diisi' : null,
          onSaved: (v) => _tempatMeninggal = v,
        ),
        _buildCustomTextField(
          label: 'Sebab',
          hintText: 'Penyebab kematian',
          prefixIcon: Icons.healing,
          maxLines: 2,
          validator: (v) => v == null || v.isEmpty ? 'Sebab wajib diisi' : null,
          onSaved: (v) => _sebab = v,
        ),
        _buildCustomTextField(
          label: 'Nama Pelapor',
          hintText: 'Nama lengkap pelapor',
          prefixIcon: Icons.person,
          validator: (v) => v == null || v.isEmpty ? 'Nama pelapor wajib diisi' : null,
          onSaved: (v) => _namaPelapor = v,
        ),
        _buildCustomTextField(
          label: 'Hubungan Pelapor',
          hintText: 'Contoh: Anak, Suami, Istri, dll',
          prefixIcon: Icons.people,
          validator: (v) => v == null || v.isEmpty ? 'Hubungan pelapor wajib diisi' : null,
          onSaved: (v) => _hubunganPelapor = v,
        ),
      ]);
    }

    // Add image picker as the last form field
    fields.add(_buildImagePicker());
    
    return fields;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Row(
          children: [
            Text(
              _getJenisIcon(widget.jenis),
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.jenis != null ? 'Ajukan Surat ${widget.jenis}' : 'Ajukan Surat',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: _getJenisColor(widget.jenis),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header Section
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: _getJenisColor(widget.jenis),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                padding: const EdgeInsets.only(bottom: 30),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                      ),
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _getJenisIcon(widget.jenis),
                              style: const TextStyle(fontSize: 24),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Formulir Pengajuan',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Lengkapi data dengan benar',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Form Section
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Data Pengajuan',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _getJenisColor(widget.jenis),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ..._buildFormFields(),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : submitSurat,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _getJenisColor(widget.jenis),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                            disabledBackgroundColor: Colors.grey.shade300,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.send, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Ajukan Surat',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}