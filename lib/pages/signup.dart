import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:intl/intl.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final supabase = Supabase.instance.client;

  final _usernameController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  DateTime? _selectedDate;

  bool _obscurePassword = true;
  bool _isLoading = false;

  void showsnacbar(String message, {Color color = Colors.green}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(color == Colors.red ? Icons.error : Icons.check_circle),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: color,
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> signup() async {
    setState(() => _isLoading = true);

    final username = _usernameController.text.trim();
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (username.isEmpty ||
        name.isEmpty ||
        phone.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty ||
        _selectedDate == null) {
      showsnacbar('Semua field wajib diisi!', color: Colors.red);
      setState(() => _isLoading = false);
      return;
    }

    if (password.length < 8) {
      showsnacbar('Password minimal 8 karakter', color: Colors.red);
      setState(() => _isLoading = false);
      return;
    }

    if (password != confirmPassword) {
      showsnacbar('Password tidak cocok', color: Colors.red);
      setState(() => _isLoading = false);
      return;
    }

    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      showsnacbar('Tidak ada koneksi internet!', color: Colors.red);
      setState(() => _isLoading = false);
      return;
    }

    try {
      // Cek nama unik
      final existing =
          await supabase
              .from('Akun')
              .select('Username')
              .eq('Username', username)
              .maybeSingle();

      if (existing != null) {
        showsnacbar('Nama sudah digunakan, pilih yang lain', color: Colors.red);
        setState(() => _isLoading = false);
        return;
      }

      // Simpan ke database
      await supabase.from('Akun').insert({
        'Username': username,
        'Password': password,
        'Nama': name,
        'TanggalLahir': _selectedDate!.toIso8601String(),
        'NomorTelepon': phone,
        'MerupakanAdmin': false,
      });

      showsnacbar('Akun berhasil dibuat!');
      Navigator.pushReplacementNamed(context, '/mainuser');
    } catch (e) {
      showsnacbar('Terjadi kesalahan: $e', color: Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          Expanded(
            flex: 3,
            child: Container(
              color: Colors.blue,
              child: Center(
                child: Image.asset(
                  'lib/images/logorectalt.png',
                  height: 400,
                  width: 400,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 7,
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Buat Akun Baru',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    buildField('Username', _usernameController),
                    buildField('Nama Lengkap', _nameController),
                    buildDateField(context),
                    buildField(
                      'Nomor Telepon',
                      _phoneController,
                      keyboardType: TextInputType.phone,
                    ),
                    buildPasswordField('Password', _passwordController),
                    buildPasswordField(
                      'Konfirmasi Password',
                      _confirmPasswordController,
                    ),
                    const SizedBox(height: 20),
                    _isLoading
                        ? const CircularProgressIndicator()
                        : ElevatedButton(
                          onPressed: signup,
                          style: ElevatedButton.styleFrom(
                            minimumSize: Size(400, 50),
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: Text('DAFTAR'),
                        ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, '/loginpage');
                      },
                      child: Text('Sudah punya akun? Login di sini'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildField(
    String hint,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 250, vertical: 5),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(25)),
        ),
      ),
    );
  }

  Widget buildPasswordField(String hint, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 250, vertical: 5),
      child: TextField(
        controller: controller,
        obscureText: _obscurePassword,
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(25)),
          suffixIcon: IconButton(
            onPressed: () {
              setState(() => _obscurePassword = !_obscurePassword);
            },
            icon: Icon(
              _obscurePassword ? Icons.visibility_off : Icons.visibility,
            ),
          ),
        ),
      ),
    );
  }

  Widget buildDateField(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 250, vertical: 5),
      child: InkWell(
        onTap: () => _selectDate(context),
        child: InputDecorator(
          decoration: InputDecoration(
            hintText: 'Tanggal Lahir',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(25)),
          ),
          child: Text(
            _selectedDate == null
                ? 'Pilih tanggal lahir'
                : DateFormat('dd-MM-yyyy').format(_selectedDate!),
          ),
        ),
      ),
    );
  }
}
