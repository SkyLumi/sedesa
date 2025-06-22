import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:project_akhir_sedesa/service/map_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  // New fields
  final TextEditingController _nikController = TextEditingController();
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _tempatLahirController = TextEditingController();
  DateTime? _tanggalLahir;
  int? _jenisKelamin;
  int? _agama;
  int? _kewarganegaraan;
  int? _statusPerkawinan;
  final TextEditingController _pekerjaanController = TextEditingController();
  final TextEditingController _alamatController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _secretKeyController = TextEditingController();
  double? _lat;
  double? _lng;

  final List<Map<String, dynamic>> _jenisKelaminOptions = [
    {'id': 1, 'nama': 'Laki - Laki'},
    {'id': 2, 'nama': 'Wanita'},
  ];
  final List<Map<String, dynamic>> _agamaOptions = [
    {'id': 1, 'nama': 'Islam'},
    {'id': 2, 'nama': 'Kristen'},
    {'id': 3, 'nama': 'Katolik'},
    {'id': 4, 'nama': 'Hindu'},
    {'id': 5, 'nama': 'Buddha'},
    {'id': 6, 'nama': 'Khonguchu'},
  ];
  final List<Map<String, dynamic>> _kewarganegaraanOptions = [
    {'id': 1, 'nama': 'Indonesia'},
  ];
  final List<Map<String, dynamic>> _statusPerkawinanOptions = [
    {'id': 1, 'nama': 'Menikah'},
    {'id': 2, 'nama': 'Belum Menikah'},
    {'id': 3, 'nama': 'Cerai'},
    {'id': 4, 'nama': 'Cerai Mati'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header dengan gradient
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF2E7D32), // Dark Green
                      Color(0xFF4CAF50), // Light Green
                    ],
                  ),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    // Back button
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.arrow_back_ios,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Logo/Icon
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
                      child: const Icon(
                        Icons.account_balance,
                        size: 50,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'SEDESA',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
                    const Text(
                      'Sistem Persuratan Desa',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),

              // Form Section
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Buat Akun Baru',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                      const Text(
                        'Silakan lengkapi data berikut untuk mendaftar',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // NIK Field
                      _buildInputField(
                        label: 'NIK',
                        icon: Icons.credit_card,
                        controller: _nikController,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'NIK tidak boleh kosong';
                          }
                          if (value.length != 16) {
                            return 'NIK harus 16 digit';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Nama Field
                      _buildInputField(
                        label: 'Nama Lengkap',
                        icon: Icons.person,
                        controller: _namaController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Nama tidak boleh kosong';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Tempat Lahir Field
                      _buildInputField(
                        label: 'Tempat Lahir',
                        icon: Icons.location_city,
                        controller: _tempatLahirController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Tempat lahir tidak boleh kosong';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Tanggal Lahir Field
                      Text(
                        'Tanggal Lahir',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime(2000, 1, 1),
                            firstDate: DateTime(1900),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setState(() {
                              _tanggalLahir = picked;
                            });
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey),
                          ),
                          child: Text(
                            _tanggalLahir == null
                                ? 'Pilih tanggal lahir'
                                : '${_tanggalLahir!.day.toString().padLeft(2, '0')}-${_tanggalLahir!.month.toString().padLeft(2, '0')}-${_tanggalLahir!.year}',
                            style: TextStyle(
                              color: _tanggalLahir == null ? Colors.grey : Colors.black,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Jenis Kelamin Dropdown
                      Text(
                        'Jenis Kelamin',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int>(
                        value: _jenisKelamin,
                        items: _jenisKelaminOptions
                            .map((jk) => DropdownMenuItem<int>(
                                  value: jk['id'],
                                  child: Text(jk['nama']),
                                ))
                            .toList(),
                        onChanged: (val) => setState(() => _jenisKelamin = val),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.grey),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                        validator: (value) => value == null ? 'Pilih jenis kelamin' : null,
                      ),
                      const SizedBox(height: 20),

                      // Pekerjaan Field
                      _buildInputField(
                        label: 'Pekerjaan',
                        icon: Icons.work,
                        controller: _pekerjaanController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Pekerjaan tidak boleh kosong';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Alamat Field
                      _buildInputField(
                        label: 'Alamat',
                        icon: Icons.home,
                        controller: _alamatController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Alamat tidak boleh kosong';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Agama Dropdown
                      Text(
                        'Agama',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int>(
                        value: _agama,
                        items: _agamaOptions
                            .map((ag) => DropdownMenuItem<int>(
                                  value: ag['id'],
                                  child: Text(ag['nama']),
                                ))
                            .toList(),
                        onChanged: (val) => setState(() => _agama = val),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.grey),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                        validator: (value) => value == null ? 'Pilih agama' : null,
                      ),
                      const SizedBox(height: 20),

                      // Kewarganegaraan Dropdown
                      Text(
                        'Kewarganegaraan',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int>(
                        value: _kewarganegaraan,
                        items: _kewarganegaraanOptions
                            .map((kw) => DropdownMenuItem<int>(
                                  value: kw['id'],
                                  child: Text(kw['nama']),
                                ))
                            .toList(),
                        onChanged: (val) => setState(() => _kewarganegaraan = val),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.grey),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                        validator: (value) => value == null ? 'Pilih kewarganegaraan' : null,
                      ),
                      const SizedBox(height: 20),

                      // Status Perkawinan Dropdown
                      Text(
                        'Status Perkawinan',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int>(
                        value: _statusPerkawinan,
                        items: _statusPerkawinanOptions
                            .map((sp) => DropdownMenuItem<int>(
                                  value: sp['id'],
                                  child: Text(sp['nama']),
                                ))
                            .toList(),
                        onChanged: (val) => setState(() => _statusPerkawinan = val),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.grey),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                        validator: (value) => value == null ? 'Pilih status perkawinan' : null,
                      ),
                      const SizedBox(height: 20),

                      // Username Field
                      _buildInputField(
                        label: 'Username',
                        icon: Icons.person_outline,
                        controller: _usernameController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Username tidak boleh kosong';
                          }
                          if (value.length < 3) {
                            return 'Username minimal 3 karakter';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Phone Number Field
                      _buildInputField(
                        label: 'No. Handphone',
                        icon: Icons.phone_outlined,
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'No. Handphone tidak boleh kosong';
                          }
                          if (value.length < 10) {
                            return 'No. Handphone tidak valid';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Password Field
                      _buildPasswordField(
                        label: 'Password',
                        isVisible: _isPasswordVisible,
                        controller: _passwordController,
                        onToggleVisibility: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Password tidak boleh kosong';
                          }
                          if (value.length < 6) {
                            return 'Password minimal 6 karakter';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Confirm Password Field
                      _buildPasswordField(
                        label: 'Konfirmasi Password',
                        isVisible: _isConfirmPasswordVisible,
                        controller: _confirmPasswordController,
                        onToggleVisibility: () {
                          setState(() {
                            _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Konfirmasi password tidak boleh kosong';
                          }
                          if (value != _passwordController.text) {
                            return 'Konfirmasi password tidak cocok';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Secret Key Field
                      _buildInputField(
                        label: 'Secret Key',
                        icon: Icons.vpn_key,
                        controller: _secretKeyController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Secret key tidak boleh kosong';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Location Picker
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Lokasi', style: TextStyle(fontWeight: FontWeight.w500)),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(_lat != null && _lng != null
                                      ? 'Lat: $_lat, Lng: $_lng'
                                      : 'Belum dipilih'),
                                ),
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.map),
                                  label: const Text('Pilih di Peta'),
                                  onPressed: () async {
                                    await showDialog(
                                      context: context,
                                      builder: (context) => Dialog(
                                        insetPadding: const EdgeInsets.all(8),
                                        child: SizedBox(
                                          width: double.infinity,
                                          height: MediaQuery.of(context).size.height * 0.7,
                                          child: LocationPicker(
                                            lat: _lat,
                                            lng: _lng,
                                            onLocationPicked: (lat, lng) {
                                              setState(() {
                                                _lat = lat;
                                                _lng = lng;
                                              });
                                              Navigator.of(context).pop();
                                            },
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Register Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleRegister,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E7D32),
                            foregroundColor: Colors.white,
                            elevation: 3,
                            shadowColor: const Color(0xFF2E7D32).withValues(alpha: 0.3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text(
                                  'Daftar Sekarang',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Login Link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Sudah punya akun? ',
                            style: TextStyle(color: Colors.grey),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: const Text(
                              'Masuk di sini',
                              style: TextStyle(
                                color: Color(0xFF2E7D32),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
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

  Widget _buildInputField({
    required String label,
    required IconData icon,
    TextEditingController? controller,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF2E7D32),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: const Color(0xFF2E7D32)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.grey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required String label,
    required bool isVisible,
    required TextEditingController controller,
    required VoidCallback onToggleVisibility,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF2E7D32),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: !isVisible,
          validator: validator,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF2E7D32)),
            suffixIcon: IconButton(
              onPressed: onToggleVisibility,
              icon: Icon(
                isVisible ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey,
              ),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.grey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }

  void _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final Map<String, dynamic> payload = {
        "nik": _nikController.text,
        "password": _passwordController.text,
        "nomor_telepon": _phoneController.text,
        "secret_key": _secretKeyController.text,
        "nama": _namaController.text,
        "tempat_lahir": _tempatLahirController.text,
        "tanggal_lahir": _tanggalLahir != null
            ? "${_tanggalLahir!.year.toString().padLeft(4, '0')}-${_tanggalLahir!.month.toString().padLeft(2, '0')}-${_tanggalLahir!.day.toString().padLeft(2, '0')}"
            : null,
        "jenis_kelamin_id": _jenisKelamin,
        "pekerjaan": _pekerjaanController.text,
        "alamat": _alamatController.text,
        "lat": _lat,
        "lng": _lng,
        "agama_id": _agama,
        "kewarganegaraan_id": _kewarganegaraan,
        "status_perkawinan_id": _statusPerkawinan,
      };

      final response = await http.post(
        Uri.parse('YOUR_API_URL/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200) {
        // Success
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registrasi berhasil!')),
        );
        // Navigate or reset form
      } else {
        // Error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registrasi gagal: ${response.body}')),
        );
      }
    }
  }
}