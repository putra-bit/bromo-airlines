import 'package:bromo_airlines/pages/admin/adminpanel.dart';
import 'package:bromo_airlines/pages/intropage.dart';
import 'package:bromo_airlines/pages/loginpage.dart';
import 'package:bromo_airlines/pages/signup.dart';
import 'package:bromo_airlines/pages/users/belitiket.dart';
import 'package:bromo_airlines/pages/users/listpenerbangan.dart';
import 'package:bromo_airlines/pages/users/mainuser.dart';
import 'package:bromo_airlines/pages/users/tiketsaya.dart'; // <== import TiketSayaPage
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id');
  await Supabase.initialize(
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVicGdvYWFqZmtudnplanRvbHZwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDY5NjEzMzUsImV4cCI6MjA2MjUzNzMzNX0.hp_4gzvZG-AgAJxX52gfs3w2355BEzLZcOrLXA7oG4c',
    url: 'https://ebpgoaajfknvzejtolvp.supabase.co',
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: '/intropage',
      onGenerateRoute: (settings) {
        if (settings.name == '/listpenerbanganform') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder:
                (context) => ListPenerbanganPage(
                  asal: args['asal'],
                  tujuan: args['tujuan'],
                  tanggal: args['tanggal'],
                  jumlahPenumpang: args['jumlahPenumpang'],
                ),
          );
        }

        if (settings.name == '/belitiketform') {
          final args = settings.arguments as Map<String, dynamic>?;

          if (args == null ||
              !args.containsKey('jadwalID') ||
              !args.containsKey('jumlahPenumpang')) {
            return MaterialPageRoute(
              builder:
                  (_) => Scaffold(
                    body: Center(
                      child: Text(
                        'Parameter tidak lengkap untuk form beli tiket',
                      ),
                    ),
                  ),
            );
          }

          return MaterialPageRoute(
            builder:
                (context) => BeliTiketFormPage(
                  jadwalID: args['jadwalID'],
                  jumlahPenumpang: args['jumlahPenumpang'],
                ),
          );
        }

        switch (settings.name) {
          case '/intropage':
            return MaterialPageRoute(builder: (_) => Intropage());
          case '/loginpage':
            return MaterialPageRoute(builder: (_) => Loginpage());
          case '/signuppage':
            return MaterialPageRoute(builder: (_) => SignupPage());
          case '/mainuser':
            return MaterialPageRoute(builder: (_) => Mainuser());
          case '/adminpanel':
            return MaterialPageRoute(builder: (_) => AdminPanel());

          case '/tiketsaya':
            final args = settings.arguments as Map<String, dynamic>?;
            final userId =
                args != null &&
                        args.containsKey('userId') &&
                        args['userId'] != null
                    ? args['userId'] as int
                    : 0;
            return MaterialPageRoute(
              builder: (_) => TiketSayaPage(userId: userId),
            );
        }

        return null;
      },
    );
  }
}
