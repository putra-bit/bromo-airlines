import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Loginpage extends StatefulWidget {
  const Loginpage({super.key});

  @override
  State<Loginpage> createState() => _LoginpageState();
}

class _LoginpageState extends State<Loginpage> {
  final supabase = Supabase.instance.client;
  final _usernamecontroller = TextEditingController();
  final _passwordcontroller = TextEditingController();
  bool _obsecurepasword = true;
  bool _islooding = false;

  void showsnacbar(String message, {Color color = Colors.green}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              color == Colors.red ? Icons.error_rounded : Icons.check_circle,
            ),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: color,
      ),
    );
  }

  Future<void> login() async {
    setState(() => _islooding = true);

    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      showsnacbar('tidak ada jaringan internet!', color: Colors.red);
      setState(() => _islooding = false);
      return;
    }
    try {
      final username = _usernamecontroller.text.trim();
      final password = _passwordcontroller.text.trim();

      if (username.isEmpty || password.isEmpty) {
        showsnacbar(
          'Username atau Password tidak boleh kosong',
          color: Colors.red,
        );
        setState(() => _islooding = false);
        return;
      }

      final respone =
          await supabase
              .from('Akun')
              .select()
              .eq('Username', username)
              .maybeSingle();

      if (respone == null) {
        showsnacbar('Username Tidak ditemukan', color: Colors.red);
      } else if (respone['Password'] != password) {
        showsnacbar('Password Salah!', color: Colors.red);
      } else {
        showsnacbar('Selamat datang kembali ${respone['Username']}');
        if (respone['MerupakanAdmin'] == true) {
          Navigator.pushReplacementNamed(context, '/adminpanel');
        } else {
          Navigator.pushReplacementNamed(
            context,
            '/mainuser',
            arguments: {'nama': respone['Nama'], 'userId': respone['ID']},
          );
        }
      }
    } catch (e) {
      showsnacbar('Ada kesalahan $e', color: Colors.red);
    } finally {
      setState(() => _islooding = false);
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Welcome Back....',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 250,
                      vertical: 5,
                    ),
                    child: TextField(
                      controller: _usernamecontroller,
                      decoration: InputDecoration(
                        hintText: 'Username',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        hintStyle: const TextStyle(color: Colors.black),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 250,
                      vertical: 5,
                    ),
                    child: TextField(
                      controller: _passwordcontroller,
                      obscureText: _obsecurepasword,
                      decoration: InputDecoration(
                        hintText: 'Password',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        hintStyle: const TextStyle(color: Colors.black),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              _obsecurepasword = !_obsecurepasword;
                            });
                          },
                          icon: Icon(
                            _obsecurepasword 
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),
                  _islooding
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                        onPressed: login,
                        child: const Text('LOGIN'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(400, 50),
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          elevation: 5,
                        ),
                      ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 250,
                      vertical: 10,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Tidak Memiliki akun?',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        OutlinedButton(
                          onPressed: () {
                            Navigator.pushReplacementNamed(
                              context,
                              '/signuppage',
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white,
                            side: BorderSide.none,
                            foregroundColor: Colors.blueAccent,
                          ),
                          child: const Text("Buat Akun Anda!"),
                        ),
                      ],
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
}
