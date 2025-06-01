import 'package:bromo_airlines/pages/admin/masterbandara.dart';
import 'package:bromo_airlines/pages/admin/masterjadwalpenerbangan.dart';
import 'package:bromo_airlines/pages/admin/masterkodepromo.dart';
import 'package:bromo_airlines/pages/admin/mastermaskapai.dart';
import 'package:bromo_airlines/pages/admin/ubahstatuspenerbangan.dart';
import 'package:flutter/material.dart';

class AdminPanel extends StatefulWidget {
  @override
  _AdminPanelState createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    MasterBandaraPage(),
    MasterMaskapaiPage(),
    MasterJadwalPenerbanganPage(),
    MasterKodePromoPage(),
    UbahStatusPenerbanganPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    Navigator.of(context).maybePop(); // aman jika drawer terbuka
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Panel'),
        leading: Builder(
          builder:
              (context) => IconButton(
                icon: Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
        ),
      ),
      drawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Center(
                child: Text(
                  'Admin Panel',
                  style: TextStyle(color: Colors.white, fontSize: 24),
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.location_on),
              title: Text('Master Bandara'),
              onTap: () => _onItemTapped(0),
            ),
            ListTile(
              leading: Icon(Icons.flight_takeoff),
              title: Text('Master Maskapai'),
              onTap: () => _onItemTapped(1),
            ),
            ListTile(
              leading: Icon(Icons.date_range),
              title: Text('Master Jadwal Penerbangan'),
              onTap: () => _onItemTapped(2),
            ),
            ListTile(
              leading: Icon(Icons.discount),
              title: Text("Master Kode Promo"),
              onTap: () => _onItemTapped(3),
            ),
            ListTile(
              leading: Icon(Icons.date_range),
              title: Text("Ubah Jadwal Penerbangan"),
              onTap: () => _onItemTapped(4),
            ),
            Spacer(),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.red,
                  minimumSize: Size(double.infinity, 50),
                ),
                onPressed: () async {
                  final result = await showDialog<bool>(
                    context: context,
                    builder:
                        (context) => AlertDialog(
                          backgroundColor: Colors.red[50],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          title: Row(
                            children: [
                              Icon(Icons.warning, color: Colors.red, size: 28),
                              SizedBox(width: 8),
                              Text(
                                'Konfirmasi Logout',
                                style: TextStyle(
                                  color: Colors.red[800],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          content: Text(
                            'Apakah Anda yakin ingin logout?',
                            style: TextStyle(
                              color: Colors.red[700],
                              fontSize: 16,
                            ),
                          ),
                          actions: [
                            TextButton(
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.grey[700],
                              ),
                              onPressed: () => Navigator.of(context).pop(false),
                              child: Text('Tidak'),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: () => Navigator.of(context).pop(true),
                              child: Text('Ya'),
                            ),
                          ],
                        ),
                  );
                  if (result == true) {
                    Navigator.of(context).pushReplacementNamed('/loginpage');
                  }
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    const SizedBox(width: 8),
                    Text(
                      'LOGOUT',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      body: _pages[_selectedIndex],
    );
  }
}

void main() {
  runApp(MaterialApp(home: AdminPanel()));
}
