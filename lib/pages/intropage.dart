import 'package:flutter/material.dart';

class Intropage extends StatefulWidget {
  const Intropage({super.key});

  @override
  State<Intropage> createState() => _IntropageState();
}

class _IntropageState extends State<Intropage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(0, 135, 200, 1),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(25),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              //logo perusahaan
              Image.asset('lib/images/applogo.png', height: 150, width: 150),
              const SizedBox(height: 15),
              //title
              Text(
                'Selamat Datang di Bromo Airlines',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  shadows: [
                    Shadow(
                      offset: Offset(2.0, 2.0),
                      blurRadius: 1,
                      color: Colors.black38,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              //subtitle
              Text(
                'Mulai Petualangan Udaramu dengan Nyaman dan Aman',
                style: TextStyle(fontSize: 18, color: Colors.black),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/loginpage');
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Lanjutkan', style: TextStyle(color: Colors.black)),
                    const SizedBox(width: 10),
                    Icon(
                      Icons.arrow_circle_right_outlined,
                      color: Colors.black,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
