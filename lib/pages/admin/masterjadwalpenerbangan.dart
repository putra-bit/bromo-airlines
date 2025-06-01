import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MasterJadwalPenerbanganPage extends StatefulWidget {
  @override
  _MasterJadwalPenerbanganPageState createState() =>
      _MasterJadwalPenerbanganPageState();
}

class _MasterJadwalPenerbanganPageState
    extends State<MasterJadwalPenerbanganPage> {
  final supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();

  final kodeController = TextEditingController();
  DateTime? tanggalKeberangkatan;
  TimeOfDay? waktuKeberangkatan;
  final durasiController = TextEditingController();
  final hargaController = TextEditingController();

  int? bandaraAsalId;
  int? bandaraTujuanId;
  int? maskapaiId;
  int? editingId;

  void clearForm() {
    kodeController.clear();
    tanggalKeberangkatan = null;
    waktuKeberangkatan = null;
    durasiController.clear();
    hargaController.clear();
    bandaraAsalId = null;
    bandaraTujuanId = null;
    maskapaiId = null;
    editingId = null;
  }

  Future<List<Map<String, dynamic>>> getBandara() async =>
      await supabase.from('Bandara').select().order('Nama');

  Future<List<Map<String, dynamic>>> getMaskapai() async =>
      await supabase.from('Maskapai').select().order('Nama');

  Future<List<dynamic>> getData() async {
    final response = await supabase
        .from('JadwalPenerbangan')
        .select(
          '*, Maskapai(Nama), BandaraKeberangkatan:BandaraKeberangkatanID(Nama), BandaraTujuan:BandaraTujuanID(Nama)',
        )
        .order('TanggalWaktuKeberangkatan', ascending: false);
    return response;
  }

  void loadToForm(Map item) {
    editingId = item['ID'];
    kodeController.text = item['KodePenerbangan'];
    final dt = DateTime.parse(item['TanggalWaktuKeberangkatan']);
    tanggalKeberangkatan = dt;
    waktuKeberangkatan = TimeOfDay(hour: dt.hour, minute: dt.minute);
    durasiController.text =
        '${item['DurasiPenerbangan'] ~/ 60} jam ${item['DurasiPenerbangan'] % 60} menit';
    hargaController.text = item['HargaPerTiket'].toString();
    bandaraAsalId = item['BandaraKeberangkatanID'];
    bandaraTujuanId = item['BandaraTujuanID'];
    maskapaiId = item['MaskapaiID'];
  }

  int? parseDurasi(String val) {
    final regex = RegExp(r'^(\d+)\s*jam\s*(\d+)\s*menit$');
    final match = regex.firstMatch(val);
    if (match != null) {
      final jam = int.parse(match.group(1)!);
      final menit = int.parse(match.group(2)!);
      return jam * 60 + menit;
    }
    return null;
  }

  Future<void> saveData() async {
    if (_formKey.currentState!.validate()) {
      final durasi = parseDurasi(durasiController.text);
      final dt = DateTime(
        tanggalKeberangkatan!.year,
        tanggalKeberangkatan!.month,
        tanggalKeberangkatan!.day,
        waktuKeberangkatan!.hour,
        waktuKeberangkatan!.minute,
      );

      final data = {
        'KodePenerbangan': kodeController.text,
        'BandaraKeberangkatanID': bandaraAsalId,
        'BandaraTujuanID': bandaraTujuanId,
        'MaskapaiID': maskapaiId,
        'TanggalWaktuKeberangkatan': dt.toIso8601String(),
        'DurasiPenerbangan': durasi,
        'HargaPerTiket': double.parse(hargaController.text),
      };

      if (editingId == null) {
        await supabase.from('JadwalPenerbangan').insert(data);
      } else {
        await supabase
            .from('JadwalPenerbangan')
            .update(data)
            .eq('ID', editingId!);
      }

      clearForm();
      setState(() {});
    }
  }

  Future<void> deleteData(int id, String kodePenerbangan) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (_) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 0,
            backgroundColor: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange,
                    size: 48,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Konfirmasi',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Hapus bandara "$kodePenerbangan"?',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey[700],
                        ),
                        onPressed: () => Navigator.pop(context, false),
                        child: Text('Batal'),
                      ),
                      SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () => Navigator.pop(context, true),
                        child: Text('Hapus'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );
    if (confirm == true) {
      await supabase.from('JadwalPenerbangan').delete().eq('ID', id);
      setState(() {});
    }
  }

  // Ganti seluruh isi metode build dengan yang ini
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Master Jadwal Penerbangan')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Form input
            Expanded(
              flex: 2,
              child: FutureBuilder(
                future: Future.wait([getBandara(), getMaskapai()]),
                builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
                  if (!snapshot.hasData) {
                    return Center(child: CircularProgressIndicator());
                  }
                  final bandaraList = snapshot.data![0];
                  final maskapaiList = snapshot.data![1];

                  return Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              editingId == null
                                  ? 'Tambah Jadwal Penerbangan'
                                  : 'Edit Jadwal Penerbangan',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 16),
                            Expanded(
                              child: ListView(
                                children: [
                                  TextFormField(
                                    controller: kodeController,
                                    decoration: InputDecoration(
                                      labelText: 'Kode Penerbangan (XX-YYYY)',
                                    ),
                                    validator: (val) {
                                      if (val == null ||
                                          !RegExp(
                                            r'^[A-Z]{2}-\d{4}$',
                                          ).hasMatch(val)) {
                                        return 'Format salah (contoh: GA-1234)';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 8),
                                  DropdownButtonFormField<int>(
                                    value: bandaraAsalId,
                                    items:
                                        bandaraList.map<DropdownMenuItem<int>>((
                                          b,
                                        ) {
                                          return DropdownMenuItem<int>(
                                            value: b['ID'],
                                            child: Text(b['Nama']),
                                          );
                                        }).toList(),
                                    onChanged:
                                        (val) =>
                                            setState(() => bandaraAsalId = val),
                                    decoration: InputDecoration(
                                      labelText: 'Bandara Keberangkatan',
                                    ),
                                    validator:
                                        (val) =>
                                            val == null
                                                ? 'Pilih bandara'
                                                : null,
                                  ),
                                  const SizedBox(height: 8),
                                  DropdownButtonFormField<int>(
                                    value: bandaraTujuanId,
                                    items:
                                        bandaraList.map<DropdownMenuItem<int>>((
                                          b,
                                        ) {
                                          return DropdownMenuItem<int>(
                                            value: b['ID'],
                                            child: Text(b['Nama']),
                                          );
                                        }).toList(),
                                    onChanged:
                                        (val) => setState(
                                          () => bandaraTujuanId = val,
                                        ),
                                    decoration: InputDecoration(
                                      labelText: 'Bandara Tujuan',
                                    ),
                                    validator: (val) {
                                      if (val == null) return 'Pilih bandara';
                                      if (val == bandaraAsalId) {
                                        return 'Tidak boleh sama dengan keberangkatan';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 8),
                                  DropdownButtonFormField<int>(
                                    value: maskapaiId,
                                    items:
                                        maskapaiList.map<DropdownMenuItem<int>>(
                                          (m) {
                                            return DropdownMenuItem<int>(
                                              value: m['ID'],
                                              child: Text(m['Nama']),
                                            );
                                          },
                                        ).toList(),
                                    onChanged:
                                        (val) =>
                                            setState(() => maskapaiId = val),
                                    decoration: InputDecoration(
                                      labelText: 'Maskapai',
                                    ),
                                    validator:
                                        (val) =>
                                            val == null
                                                ? 'Pilih maskapai'
                                                : null,
                                  ),
                                  const SizedBox(height: 8),
                                  ListTile(
                                    title: Text(
                                      tanggalKeberangkatan == null
                                          ? 'Pilih Tanggal'
                                          : DateFormat(
                                            'dd-MM-yyyy',
                                          ).format(tanggalKeberangkatan!),
                                    ),
                                    trailing: Icon(Icons.calendar_today),
                                    onTap: () async {
                                      final picked = await showDatePicker(
                                        context: context,
                                        initialDate: DateTime.now(),
                                        firstDate: DateTime(2024),
                                        lastDate: DateTime(2030),
                                      );
                                      if (picked != null) {
                                        setState(
                                          () => tanggalKeberangkatan = picked,
                                        );
                                      }
                                    },
                                  ),
                                  ListTile(
                                    title: Text(
                                      waktuKeberangkatan == null
                                          ? 'Pilih Waktu'
                                          : waktuKeberangkatan!.format(context),
                                    ),
                                    trailing: Icon(Icons.access_time),
                                    onTap: () async {
                                      final picked = await showTimePicker(
                                        context: context,
                                        initialTime: TimeOfDay.now(),
                                      );
                                      if (picked != null) {
                                        setState(
                                          () => waktuKeberangkatan = picked,
                                        );
                                      }
                                    },
                                  ),
                                  TextFormField(
                                    controller: durasiController,
                                    decoration: InputDecoration(
                                      labelText: 'Durasi (X jam Y menit)',
                                    ),
                                    validator:
                                        (val) =>
                                            parseDurasi(val ?? '') == null
                                                ? 'Format salah'
                                                : null,
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: hargaController,
                                    decoration: InputDecoration(
                                      labelText: 'Harga Per Tiket',
                                    ),
                                    keyboardType: TextInputType.number,
                                    validator: (val) {
                                      final h = double.tryParse(val ?? '');
                                      if (h == null || h < 1)
                                        return 'Minimal 1';
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      ElevatedButton(
                                        onPressed: saveData,
                                        child: Text(
                                          editingId == null
                                              ? 'Simpan'
                                              : 'Simpan Perubahan',
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      OutlinedButton(
                                        onPressed: () {
                                          clearForm();
                                          setState(() {});
                                        },
                                        child: Text('Batal'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            // Data list
            Expanded(
              flex: 3,
              child: FutureBuilder<List>(
                future: getData(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(child: CircularProgressIndicator());
                  }
                  final list = snapshot.data!;
                  return Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: ListView(
                        children: [
                          Text(
                            'Daftar Jadwal Penerbangan',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Divider(),
                          ...list.map((j) {
                            final dt = DateTime.parse(
                              j['TanggalWaktuKeberangkatan'],
                            );
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(j['KodePenerbangan']),
                              subtitle: Text(
                                '${j['BandaraKeberangkatan']['Nama']} → ${j['BandaraTujuan']['Nama']} (${j['Maskapai']['Nama']})\n${DateFormat('dd-MM-yyyy HH:mm').format(dt)}',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.edit, color: Colors.blue),
                                    onPressed:
                                        () => setState(() => loadToForm(j)),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete, color: Colors.red),
                                    onPressed:
                                        () => deleteData(
                                          j['ID'],
                                          j['KodePenerbangan'],
                                        ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
