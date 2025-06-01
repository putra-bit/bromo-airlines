import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UbahStatusPenerbanganPage extends StatefulWidget {
  const UbahStatusPenerbanganPage({Key? key}) : super(key: key);

  @override
  State<UbahStatusPenerbanganPage> createState() =>
      _UbahStatusPenerbanganPageState();
}

class _UbahStatusPenerbanganPageState extends State<UbahStatusPenerbanganPage> {
  final supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();
  int? selectedJadwalID;
  int? selectedStatusID;
  bool isLoading = false;

  List<Map<String, dynamic>> jadwalPenerbanganList = [];
  List<Map<String, dynamic>> statusList = [];
  List<Map<String, dynamic>> riwayatStatus = [];

  @override
  void initState() {
    super.initState();
    fetchInitialData();
  }

  Future<void> fetchInitialData() async {
    setState(() => isLoading = true);
    await Future.wait([
      fetchJadwalPenerbangan(),
      fetchStatusPenerbangan(),
      fetchRiwayatStatus(),
    ]);
    setState(() => isLoading = false);
  }

  Future<void> fetchJadwalPenerbangan() async {
    final response = await supabase
        .from('JadwalPenerbangan')
        .select('ID, KodePenerbangan');
    setState(() {
      jadwalPenerbanganList = List<Map<String, dynamic>>.from(response);
    });
  }

  Future<void> fetchStatusPenerbangan() async {
    final response = await supabase
        .from('StatusPenerbangan')
        .select('ID, Nama');
    setState(() {
      statusList = List<Map<String, dynamic>>.from(response);
    });
  }

  Future<void> fetchRiwayatStatus() async {
    final response = await supabase
        .from('PerubahanStatusJadwalPenerbangan')
        .select('''
          ID,
          WaktuPerubahanTerjadi,
          PerkiraanDurasiDelay,
          JadwalPenerbangan(ID, KodePenerbangan),
          StatusPenerbangan(ID, Nama)
        ''')
        .order('WaktuPerubahanTerjadi', ascending: false);
    setState(() {
      riwayatStatus = List<Map<String, dynamic>>.from(response);
    });
  }

  Future<void> simpanPerubahanStatus() async {
    if (_formKey.currentState!.validate()) {
      await supabase.from('PerubahanStatusJadwalPenerbangan').insert({
        'JadwalPenerbanganID': selectedJadwalID,
        'StatusPenerbanganID': selectedStatusID,
        'WaktuPerubahanTerjadi': DateTime.now().toIso8601String(),
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Status berhasil diubah')));

      setState(() {
        selectedJadwalID = null;
        selectedStatusID = null;
      });

      fetchRiwayatStatus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ubah Status Penerbangan')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Form Section
            Expanded(
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Form Ubah Status',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<int>(
                          decoration: const InputDecoration(
                            labelText: 'Kode Penerbangan',
                          ),
                          value: selectedJadwalID,
                          items:
                              jadwalPenerbanganList.map((item) {
                                return DropdownMenuItem<int>(
                                  value: item['ID'],
                                  child: Text(item['KodePenerbangan']),
                                );
                              }).toList(),
                          onChanged: (value) {
                            setState(() => selectedJadwalID = value);
                          },
                          validator:
                              (value) =>
                                  value == null
                                      ? 'Pilih kode penerbangan'
                                      : null,
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<int>(
                          decoration: const InputDecoration(
                            labelText: 'Status',
                          ),
                          value: selectedStatusID,
                          items:
                              statusList.map((item) {
                                return DropdownMenuItem<int>(
                                  value: item['ID'],
                                  child: Text(item['Nama']),
                                );
                              }).toList(),
                          onChanged: (value) {
                            setState(() => selectedStatusID = value);
                          },
                          validator:
                              (value) =>
                                  value == null
                                      ? 'Pilih status penerbangan'
                                      : null,
                        ),
                        const SizedBox(height: 24),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton(
                            onPressed: simpanPerubahanStatus,
                            child: const Text('Simpan'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Riwayat Section
            Expanded(
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child:
                    isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: ListView.separated(
                            itemCount: riwayatStatus.length,
                            separatorBuilder: (_, __) => const Divider(),
                            itemBuilder: (context, index) {
                              final item = riwayatStatus[index];
                              final jadwal = item['JadwalPenerbangan'];
                              final status = item['StatusPenerbangan'];
                              return ListTile(
                                title: Text(
                                  jadwal['KodePenerbangan'] ??
                                      'Tidak diketahui',
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Status: ${status['Nama']}'),
                                    Text(
                                      'Waktu: ${item['WaktuPerubahanTerjadi']}',
                                    ),
                                    if (item['PerkiraanDurasiDelay'] != null)
                                      Text(
                                        'Delay: ${item['PerkiraanDurasiDelay']} menit',
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
