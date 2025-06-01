import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MasterMaskapaiPage extends StatefulWidget {
  @override
  _MasterMaskapaiPageState createState() => _MasterMaskapaiPageState();
}

class _MasterMaskapaiPageState extends State<MasterMaskapaiPage> {
  final supabase = Supabase.instance.client;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController namaController = TextEditingController();
  final TextEditingController perusahaanController = TextEditingController();
  final TextEditingController jumlahKruController = TextEditingController();
  final TextEditingController deskripsiController = TextEditingController();

  int? editingId;

  void clearForm() {
    namaController.clear();
    perusahaanController.clear();
    jumlahKruController.clear();
    deskripsiController.clear();
    editingId = null;
  }

  void loadToForm(Map maskapai) {
    namaController.text = maskapai['Nama'];
    perusahaanController.text = maskapai['Perusahaan'];
    jumlahKruController.text = maskapai['JumlahKru'].toString();
    deskripsiController.text = maskapai['Deskripsi'];
    editingId = maskapai['ID'];
  }

  Future<List<dynamic>> getData() async {
    final response = await supabase
        .from('Maskapai')
        .select()
        .order('Nama', ascending: true);
    return response;
  }

  Future<void> saveData() async {
    if (_formKey.currentState!.validate()) {
      final data = {
        'Nama': namaController.text.trim(),
        'Perusahaan': perusahaanController.text.trim(),
        'JumlahKru': int.parse(jumlahKruController.text),
        'Deskripsi': deskripsiController.text.trim(),
      };

      if (editingId == null) {
        await supabase.from('Maskapai').insert(data);
      } else {
        await supabase.from('Maskapai').update(data).eq('ID', editingId!);
      }

      clearForm();
      setState(() {});
    }
  }

  Future<void> deleteData(int id, String Nama) async {
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
                    'Hapus Maskapai "$Nama"?',
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
      await supabase.from('Maskapai').delete().eq('ID', id).eq('Nama', Nama);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Master Maskapai')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Form input dibungkus Card
            Expanded(
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      children: [
                        Text(
                          editingId == null
                              ? 'Tambah Maskapai'
                              : 'Edit Maskapai',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        SizedBox(height: 16),
                        TextFormField(
                          controller: namaController,
                          decoration: InputDecoration(
                            labelText: 'Nama Maskapai',
                          ),
                          validator:
                              (val) =>
                                  val == null || val.isEmpty
                                      ? 'Wajib diisi'
                                      : null,
                        ),
                        TextFormField(
                          controller: perusahaanController,
                          decoration: InputDecoration(labelText: 'Perusahaan'),
                          validator:
                              (val) =>
                                  val == null || val.isEmpty
                                      ? 'Wajib diisi'
                                      : null,
                        ),
                        TextFormField(
                          controller: jumlahKruController,
                          decoration: InputDecoration(labelText: 'Jumlah Kru'),
                          keyboardType: TextInputType.number,
                          validator: (val) {
                            final n = int.tryParse(val ?? '');
                            if (n == null || n < 1) return 'Minimal 1 kru';
                            return null;
                          },
                        ),
                        TextFormField(
                          controller: deskripsiController,
                          decoration: InputDecoration(labelText: 'Deskripsi'),
                          maxLines: 3,
                          validator:
                              (val) =>
                                  val == null || val.isEmpty
                                      ? 'Wajib diisi'
                                      : null,
                        ),
                        SizedBox(height: 16),
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
                            SizedBox(width: 8),
                            ElevatedButton(
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
                ),
              ),
            ),
            SizedBox(width: 16),
            // List maskapai dibungkus Card
            Expanded(
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: FutureBuilder<List>(
                    future: getData(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData)
                        return Center(child: CircularProgressIndicator());

                      final list = snapshot.data!;
                      if (list.isEmpty) {
                        return Center(child: Text('Belum ada data maskapai.'));
                      }

                      return ListView.builder(
                        itemCount: list.length,
                        itemBuilder: (context, index) {
                          final m = list[index];
                          return ListTile(
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            title: Text(
                              m['Nama'],
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              '${m['Perusahaan']} • ${m['JumlahKru']} kru\n${m['Deskripsi']}',
                            ),
                            isThreeLine: true,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit, color: Colors.blue),
                                  onPressed:
                                      () => setState(() => loadToForm(m)),
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed:
                                      () => deleteData(m['ID'], m['Nama']),
                                ),
                              ],
                            ),
                          );
                        },
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
