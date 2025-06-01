import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MasterKodePromoPage extends StatefulWidget {
  @override
  _MasterKodePromoPageState createState() => _MasterKodePromoPageState();
}

class _MasterKodePromoPageState extends State<MasterKodePromoPage> {
  final supabase = Supabase.instance.client;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController kodeController = TextEditingController();
  final TextEditingController persentaseController = TextEditingController();
  final TextEditingController maksimumController = TextEditingController();
  final TextEditingController deskripsiController = TextEditingController();
  DateTime? berlakuSampai;
  int? editingId;

  void clearForm() {
    kodeController.clear();
    persentaseController.clear();
    maksimumController.clear();
    deskripsiController.clear();
    berlakuSampai = null;
    editingId = null;
  }

  void loadToForm(Map data) {
    kodeController.text = data['Kode'];
    persentaseController.text = data['PersentaseDiskon'].toString();
    maksimumController.text = data['MaksimumDiskon'].toString();
    deskripsiController.text = data['Deskripsi'];
    berlakuSampai = DateTime.parse(data['BerlakuSampai']);
    editingId = data['ID'];
  }

  Future<List<dynamic>> getData() async {
    final response = await supabase.from('KodePromo').select().order('Kode');
    return response;
  }

  Future<bool> isKodeUnique(String kode) async {
    final result =
        await supabase
            .from('KodePromo')
            .select()
            .eq('Kode', kode)
            .maybeSingle();

    return result == null || (editingId != null && result['ID'] == editingId);
  }

  Future<void> saveData() async {
    if (_formKey.currentState!.validate()) {
      final kode = kodeController.text.trim().toUpperCase();

      if (!await isKodeUnique(kode)) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Kode sudah digunakan')));
        return;
      }

      final data = {
        'Kode': kode,
        'PersentaseDiskon': double.parse(persentaseController.text),
        'MaksimumDiskon': double.parse(maksimumController.text),
        'BerlakuSampai': berlakuSampai!.toIso8601String(),
        'Deskripsi': deskripsiController.text.trim(),
      };

      if (editingId == null) {
        await supabase.from('KodePromo').insert(data);
      } else {
        await supabase.from('KodePromo').update(data).eq('ID', editingId!);
      }

      clearForm();
      setState(() {});
    }
  }

  Future<void> deleteData(int id, String Kode) async {
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
                    'Hapus Kode Promo "$Kode"?',
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
      await supabase.from('KodePromo').delete().eq('ID', id).eq('Kode', Kode);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Master Kode Promo')),
      body: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      children: [
                        TextFormField(
                          controller: kodeController,
                          decoration: InputDecoration(labelText: 'Kode Promo'),
                          textCapitalization: TextCapitalization.characters,
                          validator:
                              (val) =>
                                  val == null || val.isEmpty
                                      ? 'Wajib diisi'
                                      : null,
                        ),
                        TextFormField(
                          controller: persentaseController,
                          decoration: InputDecoration(
                            labelText: 'Persentase Diskon (%)',
                          ),
                          keyboardType: TextInputType.number,
                          validator: (val) {
                            final v = double.tryParse(val ?? '');
                            if (v == null || v < 1) return 'Minimal 1%';
                            return null;
                          },
                        ),
                        TextFormField(
                          controller: maksimumController,
                          decoration: InputDecoration(
                            labelText: 'Maksimum Diskon',
                          ),
                          keyboardType: TextInputType.number,
                          validator: (val) {
                            final v = double.tryParse(val ?? '');
                            if (v == null || v < 1) return 'Minimal 1';
                            return null;
                          },
                        ),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text('Masa Berlaku'),
                          subtitle: Text(
                            berlakuSampai == null
                                ? 'Pilih tanggal'
                                : '${berlakuSampai!.toLocal()}'.split(' ')[0],
                          ),
                          trailing: Icon(Icons.calendar_today),
                          onTap: () async {
                            final selected = await showDatePicker(
                              context: context,
                              initialDate: berlakuSampai ?? DateTime.now(),
                              firstDate: DateTime.now().subtract(
                                Duration(days: 1),
                              ),
                              lastDate: DateTime(2100),
                            );
                            if (selected != null) {
                              setState(() => berlakuSampai = selected);
                            }
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
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: FutureBuilder<List>(
                    future: getData(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return Center(child: CircularProgressIndicator());
                      }
                      final list = snapshot.data!;
                      return ListView.builder(
                        itemCount: list.length,
                        itemBuilder: (context, index) {
                          final d = list[index];
                          return ListTile(
                            title: Text(d['Kode']),
                            subtitle: Text(
                              '${d['PersentaseDiskon']}% | Maks: ${d['MaksimumDiskon']} | s.d. ${d['BerlakuSampai']}',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit),
                                  onPressed:
                                      () => setState(() => loadToForm(d)),
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed:
                                      () => deleteData(d['ID'], d['Kode']),
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
          ),
        ],
      ),
    );
  }
}
